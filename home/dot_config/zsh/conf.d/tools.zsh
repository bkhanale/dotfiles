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
