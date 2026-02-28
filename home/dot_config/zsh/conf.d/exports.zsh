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
export NODE_OPTIONS='--max-old-space-size=4096'

# ── OpenSSL (macOS Homebrew) ──────────────────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
  _brew_prefix="$(brew --prefix)"
  if [[ -d "$_brew_prefix/opt/openssl" ]]; then
    export LDFLAGS="-L$_brew_prefix/opt/openssl/lib $LDFLAGS"
    export CPPFLAGS="-I$_brew_prefix/opt/openssl/include $CPPFLAGS"
    export PKG_CONFIG_PATH="$_brew_prefix/opt/openssl/lib/pkgconfig:$PKG_CONFIG_PATH"
  fi
  unset _brew_prefix
fi

# ── MySQL / PostgreSQL (macOS Homebrew) ───────────────────────────────────────
if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
  _brew_prefix="$(brew --prefix)"
  [[ -d "$_brew_prefix/opt/mysql-client/bin" ]] \
    && export PATH="$_brew_prefix/opt/mysql-client/bin:$PATH"
  [[ -d "$_brew_prefix/opt/postgresql@16/bin" ]] \
    && export PATH="$_brew_prefix/opt/postgresql@16/bin:$PATH"
  unset _brew_prefix
fi

# ── Vault ─────────────────────────────────────────────────────────────────────
# VAULT_ADDR and VAULT_TOKEN are set in secrets.zsh

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
