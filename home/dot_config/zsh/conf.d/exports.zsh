# conf.d/exports.zsh — environment variable exports

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
if command -v bat &>/dev/null; then
  export PAGER='bat --plain'
  export MANPAGER='sh -c "col -bx | bat -l man -p"'
elif command -v batcat &>/dev/null; then
  export PAGER='batcat --plain'
  export MANPAGER='sh -c "col -bx | batcat -l man -p"'
fi
export BAT_THEME='tokyonight_night'

# ── Language / locale ─────────────────────────────────────────────────────────
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# ── Node.js ───────────────────────────────────────────────────────────────────
# Set NODE_OPTIONS per-project via .env / direnv instead of globally
# export NODE_OPTIONS='--max-old-space-size=8192'

# ── OpenSSL ───────────────────────────────────────────────────────────────────
# Using local OpenSSL 1.1 build (required for some older dependencies)
export OPENSSL_PREFIX="$HOME/.local/openssl-1.1"

# ── MySQL (macOS Homebrew) ────────────────────────────────────────────────────
[[ -d "/opt/homebrew/opt/mysql@8.0/bin" ]] \
  && export PATH="/opt/homebrew/opt/mysql@8.0/bin:$PATH"

# ── PostgreSQL (macOS Homebrew) ───────────────────────────────────────────────
[[ -d "/opt/homebrew/opt/postgresql@18/bin" ]] \
  && export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

# ── libpq (macOS Homebrew) ───────────────────────────────────────────────────
[[ -d "/opt/homebrew/opt/libpq/bin" ]] \
  && export PATH="/opt/homebrew/opt/libpq/bin:$PATH"

# ── Nginx ─────────────────────────────────────────────────────────────────────
[[ -d "/opt/nginx/sbin" ]] && export PATH="/opt/nginx/sbin:$PATH"

# ── Vault ─────────────────────────────────────────────────────────────────────
# VAULT_ADDR, VAULT_TOKEN, and other secrets are set in secrets.zsh

# ── GPG ───────────────────────────────────────────────────────────────────────
export GPG_TTY="$(tty)"

# ── Local bin ─────────────────────────────────────────────────────────────────
export PATH="$HOME/.local/bin:$PATH"

# ── Homebrew (Apple Silicon path first) ───────────────────────────────────────
if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX="/opt/homebrew"
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  export HOMEBREW_PREFIX="/usr/local"
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── FZF defaults ──────────────────────────────────────────────────────────────
if command -v fd &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
elif command -v fdfind &>/dev/null; then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --color=fg:#c0caf5,bg:#1a1b26,hl:#ff9e64,fg+:#c0caf5,bg+:#283457,hl+:#ff9e64,info:#7aa2f7,prompt:#7dcfff,pointer:#bb9af7,marker:#9ece6a,spinner:#bb9af7,header:#7aa2f7'
