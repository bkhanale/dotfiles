# conf.d/completions.zsh — completion styles and configuration

# ── Completion styles ─────────────────────────────────────────────────────────
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%B%d%b'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# ── Completion for specific tools ─────────────────────────────────────────────
# mise
command -v mise &>/dev/null && eval "$(mise completion zsh)"

# kubectl
command -v kubectl &>/dev/null \
  && [[ ! -f "$XDG_CACHE_HOME/zsh/kubectl_completion" ]] \
  && kubectl completion zsh > "$XDG_CACHE_HOME/zsh/kubectl_completion"
[[ -f "$XDG_CACHE_HOME/zsh/kubectl_completion" ]] \
  && source "$XDG_CACHE_HOME/zsh/kubectl_completion"
