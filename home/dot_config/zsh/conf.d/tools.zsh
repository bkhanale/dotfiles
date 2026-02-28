# conf.d/tools.zsh — initialise CLI tools that require eval hooks

# ── mise (version manager — replaces nvm, pyenv, jenv, rvm) ──────────────────
command -v mise &>/dev/null && eval "$(mise activate zsh)"

# ── zoxide (smart cd replacement) ─────────────────────────────────────────────
command -v zoxide &>/dev/null && eval "$(zoxide init zsh --cmd cd)"

# ── direnv (per-directory env vars) ──────────────────────────────────────────
command -v direnv &>/dev/null && eval "$(direnv hook zsh)"

# ── fzf keybindings and completions ──────────────────────────────────────────
if command -v fzf &>/dev/null; then
  if [[ "$(uname)" == "Darwin" ]] && command -v brew &>/dev/null; then
    _fzf_dir="$(brew --prefix)/opt/fzf"
    [[ -f "$_fzf_dir/shell/key-bindings.zsh" ]]  && source "$_fzf_dir/shell/key-bindings.zsh"
    [[ -f "$_fzf_dir/shell/completion.zsh" ]]     && source "$_fzf_dir/shell/completion.zsh"
    unset _fzf_dir
  elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
  fi
fi

# ── gh (GitHub CLI) completion ────────────────────────────────────────────────
command -v gh &>/dev/null && eval "$(gh completion -s zsh)"
