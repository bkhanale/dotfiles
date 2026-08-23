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

# ── eza ───────────────────────────────────────────────────────────────────────
# Symbols Nerd Font Mono glyphs fill the cell edge-to-edge, so the default
# 1-space gap after the icon looks cramped against the ~2 cells of column
# padding before it. Bump to 2 for symmetric spacing.
export EZA_ICON_SPACING=2

# ── Language / locale ─────────────────────────────────────────────────────────
export LANG='en_US.UTF-8'
export LC_ALL='en_US.UTF-8'

# ── Node.js ───────────────────────────────────────────────────────────────────
# Set NODE_OPTIONS per-project via .env / direnv instead of globally
# export NODE_OPTIONS='--max-old-space-size=8192'

# ── opencode ──────────────────────────────────────────────────────────────────
[[ -d "$HOME/.opencode/bin" ]] && export PATH="$HOME/.opencode/bin:$PATH"

# ── GPG ───────────────────────────────────────────────────────────────────────
export GPG_TTY="$(tty)"

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
