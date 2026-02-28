#!/usr/bin/env bash
# install.sh — one-command machine bootstrap
# Usage: bash install.sh
set -euo pipefail

# ── Helpers ───────────────────────────────────────────────────────────────────
info()    { printf "\033[0;34m[INFO]\033[0m  %s\n" "$*"; }
success() { printf "\033[0;32m[OK]\033[0m    %s\n" "$*"; }
warn()    { printf "\033[0;33m[WARN]\033[0m  %s\n" "$*"; }
error()   { printf "\033[0;31m[ERROR]\033[0m %s\n" "$*" >&2; exit 1; }

OS="$(uname -s)"

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
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

  # pacman update
  info "Updating package database…"
  sudo pacman -Syu --noconfirm

  # base-devel for AUR
  sudo pacman -S --needed --noconfirm base-devel git curl

  # yay (AUR helper)
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

  # chezmoi
  if ! command -v chezmoi &>/dev/null; then
    info "Installing chezmoi via yay…"
    yay -S --noconfirm chezmoi
    success "chezmoi installed"
  else
    success "chezmoi already installed"
  fi

  # Core packages from packages.arch.txt (if present)
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [[ -f "$SCRIPT_DIR/packages.arch.txt" ]]; then
    info "Installing Arch packages…"
    grep -v '^\s*#' "$SCRIPT_DIR/packages.arch.txt" | grep -v '^\s*$' \
      | xargs -r yay -S --needed --noconfirm
    success "Arch packages installed"
  else
    warn "packages.arch.txt not found — skipping package install"
  fi
}

# ── Apply dotfiles via chezmoi ────────────────────────────────────────────────
apply_chezmoi() {
  info "Applying dotfiles with chezmoi…"
  if chezmoi data &>/dev/null; then
    # chezmoi is already initialised — just apply
    chezmoi apply
  else
    chezmoi init --apply bkhanale/dotfiles
  fi
  success "chezmoi apply complete"
}

# ── Install runtimes via mise ─────────────────────────────────────────────────
install_mise_tools() {
  if command -v mise &>/dev/null; then
    info "Installing runtime versions with mise…"
    mise install
    success "mise install complete"
  else
    warn "mise not found — skipping runtime install (run 'mise install' after adding mise to PATH)"
  fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  case "$OS" in
    Darwin)  install_macos ;;
    Linux)   install_arch  ;;
    *)       error "Unsupported OS: $OS" ;;
  esac

  apply_chezmoi
  install_mise_tools

  printf "\n"
  success "All done!"
  printf "\n"
  printf "  Next steps:\n"
  printf "    1. Set up your secrets file:\n"
  printf "       cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh\n"
  printf "       \$EDITOR ~/.config/zsh/secrets.zsh\n"
  printf "\n"
  printf "    2. Import your GPG key (if using commit signing):\n"
  printf "       gpg --import private-key.asc\n"
  printf "       gpgconf --kill gpg-agent\n"
  printf "\n"
  printf "    3. Verify with:\n"
  printf "       chezmoi diff         # should be clean\n"
  printf "       mise doctor          # runtimes OK\n"
  printf "       time zsh -i -c exit  # should be < 200ms\n"
  printf "\n"
}

main "$@"
