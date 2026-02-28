# conf.d/exports.zsh — environment variable exports

# ── Editor ────────────────────────────────────────────────────────────────────
export EDITOR='nvim'
export VISUAL='nvim'
export PAGER='bat --plain'
export MANPAGER='sh -c "col -bx | bat -l man -p"'

# ── Language / locale ─────────────────────────────────────────────────────────
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# ── Node.js ───────────────────────────────────────────────────────────────────
export NODE_OPTIONS='--max-old-space-size=8192'

# ── OpenSSL ───────────────────────────────────────────────────────────────────
# Using local OpenSSL 1.1 build (required for some older dependencies)
export OPENSSL_PREFIX="$HOME/.local/openssl-1.1"

# ── MySQL (macOS Homebrew) ────────────────────────────────────────────────────
# Pin to mysql@8.0 — update path if you upgrade MySQL
[[ -d "/opt/homebrew/Cellar/mysql@8.0/8.0.43_3/bin" ]] \
  && export PATH="/opt/homebrew/Cellar/mysql@8.0/8.0.43_3/bin:$PATH"

# ── PostgreSQL (macOS Homebrew) ───────────────────────────────────────────────
[[ -d "/opt/homebrew/opt/postgresql@18/bin" ]] \
  && export PATH="/opt/homebrew/opt/postgresql@18/bin:$PATH"

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
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# ── FZF defaults ──────────────────────────────────────────────────────────────
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
