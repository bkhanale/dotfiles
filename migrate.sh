#!/usr/bin/env bash
# migrate.sh — clean-slate migration to new chezmoi dotfiles
#
# WHAT THIS DOES (in order):
#   1. Install Homebrew packages (chezmoi, mise, starship, etc.)
#   2. Remove all version managers (nvm, pyenv, jenv, rvm) + their runtimes
#   3. Apply dotfiles via chezmoi (from local source)
#   4. Write secrets.zsh to ~/.config/zsh/secrets.zsh (gitignored)
#   5. Remove old shell config files (oh-my-zsh, p10k, ~/.zshrc, etc.)
#   6. Install runtime versions via mise
#
# Run with:  bash ~/workspace/bkhanale/dotfiles/migrate.sh

set -euo pipefail

DOTFILES_DIR="$HOME/workspace/bkhanale/dotfiles"

# ── Colour helpers ────────────────────────────────────────────────────────────
info()    { printf "\033[0;34m▸\033[0m  %s\n" "$*"; }
success() { printf "\033[0;32m✓\033[0m  %s\n" "$*"; }
warn()    { printf "\033[0;33m⚠\033[0m  %s\n" "$*"; }
header()  { printf "\n\033[1;37m━━ %s\033[0m\n" "$*"; }
error()   { printf "\033[0;31m✗\033[0m  %s\n" "$*" >&2; exit 1; }

confirm() {
  printf "\033[0;33m?\033[0m  %s [y/N] " "$1"
  read -r reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

# ── Sanity checks ─────────────────────────────────────────────────────────────
header "Pre-flight checks"

[[ -d "$DOTFILES_DIR" ]] \
  || error "Dotfiles repo not found at $DOTFILES_DIR — clone it first."

[[ "$(uname)" == "Darwin" ]] \
  || error "This script is macOS-only currently. Use install.sh for Arch Linux."

# ── Step 1: Homebrew packages ─────────────────────────────────────────────────
header "Step 1 — Install Homebrew packages"

if ! command -v brew &>/dev/null; then
  info "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
fi
success "Homebrew: $(brew --version | head -1)"

info "Running brew bundle (this may take a while)…"
brew bundle --file="$DOTFILES_DIR/Brewfile"
success "brew bundle complete"

# Reload brew env in this session
eval "$(brew shellenv)"

# ── Step 2: Remove version managers ──────────────────────────────────────────
header "Step 2 — Remove version managers (nvm, pyenv, jenv, rvm)"

warn "This will permanently delete all nvm/pyenv/jenv/rvm installed runtimes."
warn "mise will be used instead. All versions in mise config.toml will be re-installed."
confirm "Continue removing old version managers?" || { warn "Skipped version manager removal."; }

# ── nvm ──────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.nvm" ]]; then
  info "Removing nvm and all installed Node versions…"
  # Unload nvm from current session if loaded
  if declare -f nvm &>/dev/null; then
    nvm deactivate 2>/dev/null || true
    nvm unload 2>/dev/null || true
  fi
  rm -rf "$HOME/.nvm"
  success "nvm removed"
else
  success "nvm: already gone"
fi

# ── pyenv ─────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.pyenv" ]]; then
  info "Removing pyenv and all installed Python versions…"
  rm -rf "$HOME/.pyenv"
  success "pyenv removed"
else
  success "pyenv: already gone"
fi

# ── jenv ──────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.jenv" ]]; then
  info "Removing jenv and all managed JDK references…"
  rm -rf "$HOME/.jenv"
  success "jenv removed"
else
  success "jenv: already gone"
fi

# ── rvm ───────────────────────────────────────────────────────────────────────
if [[ -d "$HOME/.rvm" ]]; then
  info "Removing rvm and all installed Ruby versions…"
  # Passenger and some other gems compile native extensions with sudo,
  # leaving root-owned files inside ~/.rvm that require sudo to delete.
  if find "$HOME/.rvm" -not -user "$(whoami)" -print -quit 2>/dev/null | grep -q .; then
    warn "Found root-owned files in ~/.rvm (built with sudo) — using sudo to remove"
    sudo rm -rf "$HOME/.rvm"
  else
    chmod -R u+w "$HOME/.rvm" 2>/dev/null || true
    rm -rf "$HOME/.rvm"
  fi
  success "rvm removed"
else
  success "rvm: already gone"
fi

success "All old version managers removed"

# ── Step 3: Apply chezmoi dotfiles ────────────────────────────────────────────
header "Step 3 — Apply dotfiles via chezmoi"

info "chezmoi will prompt for your name, email, and GPG key ID."
info "Source: $DOTFILES_DIR"
echo ""

# Always run init with the local source — promptStringOnce is idempotent
# (only prompts if the value isn't already stored in ~/.config/chezmoi/chezmoi.toml)
chezmoi init --source="$DOTFILES_DIR" --apply
success "chezmoi apply complete"

# ── Step 4: Write secrets.zsh ─────────────────────────────────────────────────
header "Step 4 — Write secrets.zsh (gitignored)"

SECRETS_FILE="$HOME/.config/zsh/secrets.zsh"

if [[ -f "$SECRETS_FILE" ]]; then
  warn "secrets.zsh already exists — skipping (edit manually if needed: $SECRETS_FILE)"
else
  info "Writing secrets.zsh with values from old .zshrc…"
  mkdir -p "$(dirname "$SECRETS_FILE")"

  # Extract tokens from old .zshrc (if it still exists)
  _claude_token=""
  _sentry_token=""
  _vault_addr=""
  _vault_token=""
  _requestly_path=""

  if [[ -f "$HOME/.zshrc" ]]; then
    _claude_token="$(grep -oP '(?<=CLAUDE_GH_MCP_TOKEN=")[^"]+' "$HOME/.zshrc" 2>/dev/null || true)"
    _sentry_token="$(grep -oP '(?<=SENTRY_AUTH_TOKEN=")[^"]+' "$HOME/.zshrc" 2>/dev/null || true)"
    _vault_addr="$(grep -oP '(?<=VAULT_ADDR=")[^"]+' "$HOME/.zshrc" 2>/dev/null || true)"
    _vault_token="$(grep -oP '(?<=VAULT_TOKEN=")[^"]+' "$HOME/.zshrc" 2>/dev/null || true)"
    _requestly_path="$(grep -oP '(?<=REQUESTLY_LEGACY_PATH=")[^"]+' "$HOME/.zshrc" 2>/dev/null || true)"
  fi

  cat > "$SECRETS_FILE" <<EOF
# ~/.config/zsh/secrets.zsh — gitignored, never committed
# Migrated from old .zshrc on $(date +%Y-%m-%d)

export CLAUDE_GH_MCP_TOKEN="${_claude_token}"
export SENTRY_AUTH_TOKEN="${_sentry_token}"
export VAULT_ADDR="${_vault_addr}"
export VAULT_TOKEN="${_vault_token}"
export REQUESTLY_LEGACY_PATH="${_requestly_path}"
EOF

  chmod 600 "$SECRETS_FILE"
  success "secrets.zsh written to $SECRETS_FILE"
fi

# ── Step 5: Remove old dotfiles ───────────────────────────────────────────────
header "Step 5 — Removing old shell config files"

# oh-my-zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  info "Removing ~/.oh-my-zsh…"
  rm -rf "$HOME/.oh-my-zsh"
  success "oh-my-zsh removed"
fi

# p10k theme config
if [[ -f "$HOME/.p10k.zsh" ]]; then
  rm -f "$HOME/.p10k.zsh"
  success ".p10k.zsh removed"
fi

# Old ~/.zshrc — now replaced by ZDOTDIR
# Back it up first just in case
if [[ -f "$HOME/.zshrc" ]]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.pre-migration.bak"
  rm -f "$HOME/.zshrc"
  success "~/.zshrc removed (backup at ~/.zshrc.pre-migration.bak)"
fi

# ~/.zlogin — only had RVM line
if [[ -f "$HOME/.zlogin" ]]; then
  rm -f "$HOME/.zlogin"
  success "~/.zlogin removed"
fi

# ~/.bash_profile — only had RVM line
if [[ -f "$HOME/.bash_profile" ]]; then
  cp "$HOME/.bash_profile" "$HOME/.bash_profile.pre-migration.bak"
  rm -f "$HOME/.bash_profile"
  success "~/.bash_profile removed (backup at ~/.bash_profile.pre-migration.bak)"
fi

# zcompdump files in ~/ (they'll regenerate in ~/.cache/zsh/)
rm -f "$HOME"/.zcompdump* 2>/dev/null || true

success "Old config files cleaned up"

# ── Step 6: Install runtimes via mise ────────────────────────────────────────
header "Step 6 — Install runtime versions via mise"

if command -v mise &>/dev/null; then
  info "Running: mise install"
  info "Installing: node (LTS), python (3.12), java (temurin-21), ruby (latest)"
  mise install
  success "mise install complete"

  echo ""
  info "Installed runtimes:"
  mise list
else
  warn "mise not found in PATH — you may need to restart your shell first, then run: mise install"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
header "Migration complete!"

printf "\n"
success "All steps finished."
printf "\n"
printf "  \033[1mNext steps:\033[0m\n"
printf "  1. \033[0;36mRestart your terminal\033[0m — new config takes effect on next shell open\n"
printf "  2. Verify your secrets file:  cat ~/.config/zsh/secrets.zsh\n"
printf "  3. Run:  chezmoi diff         # should show nothing\n"
printf "  4. Run:  mise doctor          # verify runtimes\n"
printf "  5. Run:  time zsh -i -c exit  # should be < 200ms\n"
printf "\n"
printf "  If anything looks wrong, your old .zshrc is backed up at:\n"
printf "  ~/.zshrc.pre-migration.bak\n"
printf "\n"
