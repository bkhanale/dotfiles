# conf.d/tools.zsh — initialise CLI tools that require eval hooks

# ── zoxide (smart cd replacement) ─────────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"

# ── direnv (per-directory env vars) ──────────────────────────────────────────
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# ── fzf keybindings and completions ──────────────────────────────────────────
if command -v fzf &>/dev/null; then
  if [[ -n "$HOMEBREW_PREFIX" ]]; then
    _fzf_dir="$HOMEBREW_PREFIX/opt/fzf"
    [[ -f "$_fzf_dir/shell/key-bindings.zsh" ]]  && source "$_fzf_dir/shell/key-bindings.zsh"
    [[ -f "$_fzf_dir/shell/completion.zsh" ]]     && source "$_fzf_dir/shell/completion.zsh"
    unset _fzf_dir
  elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
  elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
    [[ -f /usr/share/doc/fzf/examples/completion.zsh ]] \
      && source /usr/share/doc/fzf/examples/completion.zsh
  fi
fi

# ── gh (GitHub CLI) completion ────────────────────────────────────────────────
command -v gh &>/dev/null && eval "$(gh completion -s zsh)"

# ── nvm (Node version manager) ────────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
if [[ -n "$HOMEBREW_PREFIX" && -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ]]; then
  source "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
  [[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ]] \
    && source "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"
elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
fi

# Auto-switch Node when entering a dir with .nvmrc (and at shell startup,
# which is what Claude Code's per-command shells rely on).
if command -v nvm &>/dev/null; then
  autoload -U add-zsh-hook
  # nvm only knows about .nvmrc — walk up to find .node-version ourselves.
  _find_node_version_file() {
    local dir="${1:-$PWD}"
    while [[ "$dir" != "/" && -n "$dir" ]]; do
      [[ -f "$dir/.node-version" ]] && { print -r -- "$dir/.node-version"; return; }
      dir="${dir:h}"
    done
  }
  load-nvmrc() {
    if [[ -n "$(nvm_find_nvmrc)" ]]; then
      nvm use 2>/dev/null || nvm install
      return
    fi
    local version_file="$(_find_node_version_file "$PWD")"
    if [[ -n "$version_file" ]]; then
      local v="${$(<"$version_file")//[[:space:]]/}"
      nvm use "$v" 2>/dev/null || nvm install "$v"
    fi
  }
  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi
