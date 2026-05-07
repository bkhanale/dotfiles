#!/usr/bin/env bash
# install.sh — one-command machine bootstrap
# Usage: bash install.sh
#
# Supports: macOS (Homebrew), Arch Linux (pacman/yay), Debian/Ubuntu (apt)
#
# What it does (non-destructive — never deletes user data):
#   1. Install platform packages (Brewfile / packages.arch.txt / packages.debian.txt)
#   2. Back up any existing ~/.zshrc, ~/.zshenv, ~/.zlogin, ~/.bash_profile
#      to <file>.pre-chezmoi.bak (chezmoi will overwrite the originals)
#   3. Migrate ~/.zsh_history into $XDG_STATE_HOME/zsh/history. If the new
#      file doesn't exist, copy. If it does, prepend the old entries (older
#      first) and concatenate. A sentinel file in the XDG zsh dir blocks
#      double-merging on re-runs. The original ~/.zsh_history is preserved.
#   4. Pre-populate ~/.config/chezmoi/chezmoi.toml's [data] block via bash
#      `read` prompts (chezmoi's promptStringOnce silently fails when invoked
#      from a script — see AGENTS.md)
#   5. Run `chezmoi init --apply` so chezmoi renders the full chezmoi.toml
#      from .chezmoi.toml.tmpl (sourceDir + diff/edit/merge) and applies the
#      dotfiles. promptStringOnce returns our pre-written values without prompting.
#   6. Fix ~/.gnupg permissions (700 dirs, 600 files) so keyboxd works
#   7. Offer to chsh the login shell to zsh (interactive prompt; defaults to no)
#
# Also done as part of step 1 on Linux: compile terminfo/ghostty.terminfo into
# ~/.terminfo so SSH'd-in sessions with TERM=xterm-ghostty resolve correctly.
set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { printf "\033[0;34m[INFO]\033[0m  %s\n" "$*"; }
success() { printf "\033[0;32m[OK]\033[0m    %s\n" "$*"; }
warn()    { printf "\033[0;33m[WARN]\033[0m  %s\n" "$*"; }
header()  { printf "\n\033[1;37m━━ %s\033[0m\n" "$*"; }
error()   { printf "\033[0;31m[ERROR]\033[0m %s\n" "$*" >&2; exit 1; }

OS="$(uname -s)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect Linux distro family (returns: arch | debian | unknown)
detect_linux_family() {
  if [[ ! -r /etc/os-release ]]; then
    echo "unknown"; return
  fi
  # shellcheck disable=SC1091
  . /etc/os-release
  local id="${ID:-}" id_like="${ID_LIKE:-}"
  case "$id" in
    arch|manjaro|endeavouros|garuda|artix)        echo "arch";   return ;;
    debian|ubuntu|linuxmint|pop|elementary|kali)  echo "debian"; return ;;
  esac
  case " $id_like " in
    *" arch "*)    echo "arch";   return ;;
    *" debian "*)  echo "debian"; return ;;
  esac
  echo "unknown"
}

# ── macOS ─────────────────────────────────────────────────────────────────────
install_macos() {
  info "macOS detected"

  # Homebrew
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for this session (Apple Silicon vs Intel)
    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    success "Homebrew installed"
  else
    success "Homebrew already installed ($(brew --version | head -1))"
  fi

  # chezmoi
  if ! command -v chezmoi &>/dev/null; then
    info "Installing chezmoi via Homebrew…"
    brew install chezmoi
    success "chezmoi installed"
  else
    success "chezmoi already installed ($(chezmoi --version))"
  fi

  # Brewfile
  if [[ -f "$SCRIPT_DIR/Brewfile" ]]; then
    info "Running brew bundle (this may take a while)…"
    brew bundle --file="$SCRIPT_DIR/Brewfile"
    success "brew bundle complete"
  else
    warn "Brewfile not found at $SCRIPT_DIR/Brewfile — skipping"
  fi
}

# ── Arch Linux ────────────────────────────────────────────────────────────────
install_arch() {
  info "Arch Linux detected"

  info "Updating package database…"
  sudo pacman -Syu --noconfirm
  sudo pacman -S --needed --noconfirm base-devel git curl

  if ! command -v yay &>/dev/null; then
    info "Installing yay…"
    tmp="$(mktemp -d)"
    git clone https://aur.archlinux.org/yay.git "$tmp/yay"
    (cd "$tmp/yay" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    success "yay installed"
  else
    success "yay already installed"
  fi

  if ! command -v chezmoi &>/dev/null; then
    info "Installing chezmoi via yay…"
    yay -S --noconfirm chezmoi
    success "chezmoi installed"
  else
    success "chezmoi already installed"
  fi

  if [[ -f "$SCRIPT_DIR/packages.arch.txt" ]]; then
    info "Installing Arch packages…"
    grep -v '^\s*#' "$SCRIPT_DIR/packages.arch.txt" | grep -v '^\s*$' \
      | xargs -r yay -S --needed --noconfirm
    success "Arch packages installed"
  else
    warn "packages.arch.txt not found — skipping package install"
  fi

  install_ghostty_terminfo
  install_neovim_upstream  # no-op on current Arch (already >= 0.11)
}

# ── Debian / Ubuntu ───────────────────────────────────────────────────────────
install_debian() {
  info "Debian / Ubuntu detected"

  export DEBIAN_FRONTEND=noninteractive

  info "Updating apt index…"
  sudo apt-get update -y
  sudo apt-get install -y curl ca-certificates gnupg git

  if [[ -f "$SCRIPT_DIR/packages.debian.txt" ]]; then
    info "Filtering packages.debian.txt against available apt sources…"
    local available=() unavailable=()
    while IFS= read -r pkg; do
      if apt-cache show "$pkg" >/dev/null 2>&1; then
        available+=("$pkg")
      else
        unavailable+=("$pkg")
      fi
    done < <(grep -v '^\s*#' "$SCRIPT_DIR/packages.debian.txt" | grep -v '^\s*$')
    if (( ${#unavailable[@]} > 0 )); then
      warn "Not in apt sources, skipping: ${unavailable[*]}"
      warn "  (likely Debian < 13 or Ubuntu < 24.04 — enable backports or install manually)"
    fi
    if (( ${#available[@]} > 0 )); then
      info "Installing ${#available[@]} apt packages…"
      sudo apt-get install -y --no-install-recommends "${available[@]}"
      success "apt packages installed"
    fi
  else
    warn "packages.debian.txt not found — skipping core install"
  fi

  # Debian renames the binaries: bat → batcat, fd → fdfind. Symlink into ~/.local/bin
  # so our zsh aliases (`alias cat=bat`, `alias find=fd`) and editor configs find them.
  mkdir -p "$HOME/.local/bin"
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
    info "Linked batcat → ~/.local/bin/bat"
  fi
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
    info "Linked fdfind → ~/.local/bin/fd"
  fi

  # chezmoi — not in Debian stable; install upstream binary into ~/.local/bin
  if ! command -v chezmoi &>/dev/null; then
    info "Installing chezmoi (upstream installer → ~/.local/bin)…"
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    export PATH="$HOME/.local/bin:$PATH"
    success "chezmoi installed"
  else
    success "chezmoi already installed ($(chezmoi --version))"
  fi

  # starship — not consistently in apt; install upstream
  if ! command -v starship &>/dev/null; then
    info "Installing starship (upstream installer → ~/.local/bin)…"
    curl -fsSL https://starship.rs/install.sh \
      | sh -s -- --yes --bin-dir "$HOME/.local/bin"
    success "starship installed"
  else
    success "starship already installed"
  fi

  # zoxide — Debian 13's apt package is v0.4.3 from 2020 with an infinite-
  # recursion bug in its `cd` function ("maximum nested function level
  # reached"). Fixed in upstream v0.6+. Install latest into ~/.local/bin
  # so it shadows /usr/bin/zoxide via the PATH order set in dot_zshenv.
  local zoxide_bin="$HOME/.local/bin/zoxide"
  if [[ ! -x "$zoxide_bin" ]] || ! "$zoxide_bin" --version 2>/dev/null | grep -qE 'zoxide 0\.[6-9]|zoxide [1-9]'; then
    info "Installing zoxide (upstream installer → ~/.local/bin)…"
    curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
      | bash -s -- --bin-dir "$HOME/.local/bin"
    success "zoxide installed ($("$zoxide_bin" --version))"
  else
    success "zoxide already up-to-date ($("$zoxide_bin" --version))"
  fi

  install_nerd_fonts_user
  install_ghostty_terminfo
  install_neovim_upstream

  warn "ghostty and zellij are not packaged for Debian — install them manually:"
  warn "  ghostty: https://ghostty.org/docs/install/binary"
  warn "  zellij : https://zellij.dev/documentation/installation"
}

# ── Helper: install neovim from upstream tarball (Linux-only) ────────────────
# Debian 12 ships nvim 0.7.2; our nvim/lua/plugins.lua uses vim.lsp.config and
# vim.lsp.enable which are 0.11+ APIs. Install upstream tarball into
# ~/.local/nvim/ and symlink ~/.local/bin/nvim so it shadows /usr/bin/nvim.
install_neovim_upstream() {
  # Skip if a >= 0.11 nvim is already on PATH (and it's already our symlink, or
  # the user installed something newer themselves).
  if command -v nvim &>/dev/null; then
    local ver; ver="$(nvim --version | head -1 | awk '{print $2}' | tr -d 'v')"
    if [[ "$ver" =~ ^([0-9]+)\.([0-9]+) ]]; then
      local major="${BASH_REMATCH[1]}" minor="${BASH_REMATCH[2]}"
      if (( major > 0 )) || (( minor >= 11 )); then
        success "nvim $ver already installed (>= 0.11) — skipping upstream install"
        return
      fi
      info "nvim $ver is too old for our config (need >= 0.11) — installing upstream"
    fi
  fi

  local arch
  case "$(uname -m)" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="arm64"  ;;
    *) warn "Unsupported arch $(uname -m) — install neovim manually"; return ;;
  esac

  local prefix="$HOME/.local/nvim"
  local tmp; tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN
  info "Downloading nvim-linux-$arch.tar.gz from neovim/neovim releases…"
  curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$arch.tar.gz" \
    -o "$tmp/nvim.tar.gz"
  rm -rf "$prefix"
  mkdir -p "$prefix"
  tar -xzf "$tmp/nvim.tar.gz" -C "$prefix" --strip-components=1

  mkdir -p "$HOME/.local/bin"
  ln -sf "$prefix/bin/nvim" "$HOME/.local/bin/nvim"
  success "nvim $("$HOME/.local/bin/nvim" --version | head -1 | awk '{print $2}') installed at $prefix"
}

# ── Helper: install ghostty terminfo into ~/.terminfo (Linux-only) ────────────
# Without this, SSH'ing into the box from a Ghostty terminal leaves TERM set to
# xterm-ghostty with no matching terminfo entry, breaking clear/tput/vim/etc.
install_ghostty_terminfo() {
  local src="$SCRIPT_DIR/terminfo/ghostty.terminfo"
  if [[ ! -f "$src" ]]; then
    warn "terminfo/ghostty.terminfo not found in repo — skipping"
    return
  fi
  if ! command -v tic &>/dev/null; then
    warn "tic not available (install ncurses-bin) — skipping ghostty terminfo install"
    return
  fi
  if TERMINFO="$HOME/.terminfo" infocmp xterm-ghostty &>/dev/null; then
    success "xterm-ghostty terminfo already installed in ~/.terminfo"
    return
  fi
  info "Compiling xterm-ghostty terminfo into ~/.terminfo…"
  mkdir -p "$HOME/.terminfo"
  tic -x -o "$HOME/.terminfo" "$src"
  success "xterm-ghostty terminfo installed"
}

# ── Helper: install Nerd Fonts into ~/.local/share/fonts (Linux-only) ─────────
install_nerd_fonts_user() {
  local fonts_dir="$HOME/.local/share/fonts"
  if fc-list 2>/dev/null | grep -qi "FiraCode Nerd Font"; then
    success "FiraCode Nerd Font already installed"
    return
  fi
  info "Installing FiraCode + Symbols Nerd Fonts into $fonts_dir…"
  mkdir -p "$fonts_dir"
  local tmp; tmp="$(mktemp -d)"
  local base="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
  curl -fsSL "$base/FiraCode.zip"             -o "$tmp/FiraCode.zip"
  curl -fsSL "$base/NerdFontsSymbolsOnly.zip" -o "$tmp/Symbols.zip"
  unzip -oq "$tmp/FiraCode.zip" -d "$fonts_dir/FiraCode"
  unzip -oq "$tmp/Symbols.zip"  -d "$fonts_dir/Symbols"
  rm -rf "$tmp"
  fc-cache -f "$fonts_dir" >/dev/null
  success "Nerd Fonts installed"
}

# ── Back up files chezmoi is about to overwrite (cp, never rm) ────────────────
# We only touch files chezmoi will write at the same target path. Anything else
# (oh-my-zsh, nvm, pyenv, …) is left untouched so the user can decide later.
backup_existing_configs() {
  header "Backing up existing dotfiles (.pre-chezmoi.bak)"
  local f backed_up=0
  for f in "$HOME/.zshrc" "$HOME/.zshenv" "$HOME/.zlogin" "$HOME/.bash_profile"; do
    # Skip non-existent files and existing symlinks (likely already chezmoi-managed
    # or a previous install run — re-backing them up would clobber the real backup).
    [[ -f "$f" && ! -L "$f" ]] || continue
    local dest="${f}.pre-chezmoi.bak"
    if [[ -e "$dest" ]]; then
      info "Backup already exists: $dest (leaving in place)"
    else
      cp -p "$f" "$dest"
      info "Backed up $f → $dest"
      backed_up=$((backed_up + 1))
    fi
  done
  if [[ $backed_up -eq 0 ]]; then
    success "No collisions to back up"
  else
    success "Backed up $backed_up file(s)"
  fi
}

# ── Migrate ~/.zsh_history into XDG state dir ────────────────────────────────
# - If new doesn't exist: cp old → new.
# - If new exists: prepend old's entries to new's (old entries are
#   chronologically older, so they belong first). zsh tolerates duplicates at
#   read time (HIST_IGNORE_ALL_DUPS in conf.d/keybindings.zsh), so we don't
#   dedupe here — that would risk dropping commands and require parsing the
#   extended-history format.
# A sentinel file in the XDG zsh dir marks the merge as done so re-runs of
# install.sh don't duplicate entries. The original ~/.zsh_history is never
# touched; delete it yourself once you're confident.
migrate_zsh_history() {
  local old="$HOME/.zsh_history"
  local new_dir="${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
  local new="$new_dir/history"
  local sentinel="$new_dir/.zsh_history-migrated"

  [[ -f "$old" ]] || return

  if [[ -f "$sentinel" ]]; then
    info "~/.zsh_history already migrated (sentinel: $sentinel) — skipping"
    return
  fi

  mkdir -p "$new_dir"
  local old_lines; old_lines=$(wc -l < "$old" | tr -d ' ')
  if [[ ! -f "$new" ]]; then
    cp -p "$old" "$new"
    success "Copied $old → $new ($old_lines lines)"
  else
    local before; before=$(wc -l < "$new" | tr -d ' ')
    cat "$old" "$new" > "$new.merging" && mv "$new.merging" "$new"
    local after; after=$(wc -l < "$new" | tr -d ' ')
    success "Merged $old into $new ($old_lines old + $before new = $after lines)"
  fi
  : > "$sentinel"
  info "Original $old left in place; sentinel prevents re-merging on rerun"
}

# ── Write ~/.config/chezmoi/chezmoi.toml ─────────────────────────────────────
# Bash prompts here instead of chezmoi's promptStringOnce, which silently
# fails when invoked from a script (documented in AGENTS.md).
write_chezmoi_config() {
  local cfg_dir="$HOME/.config/chezmoi"
  local cfg="$cfg_dir/chezmoi.toml"
  # POSIX bracket class — \s would only work on GNU grep, not BSD/macOS grep.
  if [[ -f "$cfg" ]] && grep -q '^[[:space:]]*name[[:space:]]*=' "$cfg" 2>/dev/null; then
    info "chezmoi config already exists at $cfg — keeping it"
    return
  fi
  header "chezmoi configuration"
  printf "  Enter your details (used for git config and GPG signing):\n"
  printf "  Full name: ";                            read -r _name
  printf "  Email:     ";                            read -r _email
  printf "  GPG key ID (leave blank to skip): ";     read -r _gpg
  mkdir -p "$cfg_dir"
  cat > "$cfg" <<EOF
[data]
  name    = "$_name"
  email   = "$_email"
  gpgKey  = "$_gpg"
EOF
  success "Wrote $cfg"
}

# ── Apply dotfiles via chezmoi (uses local source if running from a clone) ────
# We use `chezmoi init --apply` (not just `chezmoi apply`) so chezmoi renders
# .chezmoi.toml.tmpl and writes a *complete* ~/.config/chezmoi/chezmoi.toml,
# including sourceDir + diff/edit/merge sections. promptStringOnce reads our
# pre-written [data] block, so it returns the existing values without prompting.
apply_chezmoi() {
  header "Applying dotfiles via chezmoi"
  if [[ -f "$SCRIPT_DIR/.chezmoiroot" ]]; then
    # Running from a local clone — use that as the source, no remote clone.
    chezmoi init --apply --source="$SCRIPT_DIR"
  else
    # No local clone available — pull from GitHub.
    chezmoi init --apply bkhanale/dotfiles
  fi
  success "chezmoi apply complete"
}

# ── Offer to change login shell to zsh (interactive, defaults to NO) ─────────
# We can't do this silently: chsh / sudo prompt for the user's password.
# If the user accepts, chsh will prompt them; if they decline, we just print
# the manual command so they can do it later.
maybe_chsh_to_zsh() {
  local zsh_path; zsh_path="$(command -v zsh || true)"
  [[ -n "$zsh_path" ]] || return
  local current_shell; current_shell="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
  if [[ "$current_shell" == "$zsh_path" ]]; then
    success "Login shell is already zsh ($zsh_path)"
    return
  fi
  if [[ ! -t 0 ]]; then
    warn "Non-interactive run; not prompting for chsh. Run manually:"
    warn "  chsh -s \"$zsh_path\""
    return
  fi
  printf "\n  Your login shell is %s. Switch to %s now? [y/N] " "$current_shell" "$zsh_path"
  local reply; read -r reply
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    # chsh will prompt for the user's password (per /etc/pam.d/chsh on Debian).
    if chsh -s "$zsh_path"; then
      success "Login shell set to $zsh_path — log out and back in to take effect"
    else
      warn "chsh failed. Run manually: chsh -s \"$zsh_path\""
    fi
  else
    info "Skipped. Run manually when ready: chsh -s \"$zsh_path\""
  fi
}

# ── Fix ~/.gnupg permissions (gpg refuses to run with loose perms) ───────────
fix_gnupg_perms() {
  [[ -d "$HOME/.gnupg" ]] || return
  info "Fixing ~/.gnupg permissions…"
  chmod 700 "$HOME/.gnupg"
  find "$HOME/.gnupg" -type d -exec chmod 700 {} \;
  find "$HOME/.gnupg" -type f -exec chmod 600 {} \;
  gpgconf --kill all 2>/dev/null || true
  success "GPG permissions fixed"
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  header "Step 1 — Install packages"
  case "$OS" in
    Darwin)
      install_macos
      ;;
    Linux)
      family="$(detect_linux_family)"
      case "$family" in
        arch)    install_arch   ;;
        debian)  install_debian ;;
        *)
          local detected_id="unknown"
          if [[ -r /etc/os-release ]]; then
            # Run in a subshell so sourced vars don't leak.
            detected_id="$(. /etc/os-release; printf '%s' "${ID:-unknown}")"
          fi
          error "Unsupported Linux distro (need arch- or debian-family). /etc/os-release ID=$detected_id"
          ;;
      esac
      ;;
    *)
      error "Unsupported OS: $OS"
      ;;
  esac

  header "Step 2 — Migrate existing user data"
  backup_existing_configs
  migrate_zsh_history

  write_chezmoi_config
  apply_chezmoi
  fix_gnupg_perms
  maybe_chsh_to_zsh

  printf "\n"
  success "All done!"
  printf "\n"
  printf "  Next steps:\n"
  printf "    1. Set up your per-machine overrides (both gitignored, never\n"
  printf "       overwritten by chezmoi apply):\n"
  printf "         cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh\n"
  printf "         cp ~/.config/zsh/local.zsh.example   ~/.config/zsh/local.zsh\n"
  printf "         \$EDITOR ~/.config/zsh/secrets.zsh ~/.config/zsh/local.zsh\n"
  printf "\n"
  printf "    2. Import your GPG key (if using commit signing):\n"
  printf "         gpg --import private-key.asc\n"
  printf "         gpgconf --kill gpg-agent\n"
  printf "\n"
  printf "    3. Verify:\n"
  printf "         chezmoi diff         # should be clean\n"
  printf "         time zsh -i -c exit  # should be < 200ms\n"
  printf "\n"
  printf "  Backups of pre-existing dotfiles, if any, were left at <file>.pre-chezmoi.bak\n"
  printf "  Your previous ~/.zsh_history, if any, was merged into \$XDG_STATE_HOME/zsh/history\n"
  printf "  (a sentinel file marks the merge so reruns won't duplicate). The original\n"
  printf "  ~/.zsh_history is left in place — delete it whenever you're confident.\n"
  printf "\n"
}

main "$@"
