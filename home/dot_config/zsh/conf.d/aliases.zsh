# conf.d/aliases.zsh — shell aliases

# ── Navigation ────────────────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── Modern CLI replacements ───────────────────────────────────────────────────
if command -v eza &>/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza --icons --group-directories-first -la'
  alias lt='eza --icons --tree --level=2'
  alias la='eza --icons --group-directories-first -a'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah'
fi

command -v bat &>/dev/null  && alias cat='bat --plain'
command -v rg &>/dev/null   && alias grep='rg'
command -v fd &>/dev/null   && alias find='fd'

# ── Git ───────────────────────────────────────────────────────────────────────
alias g='git'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gsw='git switch'
alias gb='git branch'
alias gbd='git branch -d'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpl='git pull'
alias gst='git status'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gll='git log --oneline --graph --decorate'
alias grb='git rebase'
alias grbi='git rebase -i'
alias grs='git restore'
alias grss='git restore --staged'
alias gsl='git stash list'
alias gsp='git stash pop'
alias gss='git stash'

# ── Kubernetes ────────────────────────────────────────────────────────────────
command -v kubectl  &>/dev/null && alias k='kubectl'
command -v kubectx  &>/dev/null && alias kx='kubectx'
command -v kubens   &>/dev/null && alias kns='kubens'

# ── Misc utilities ────────────────────────────────────────────────────────────
alias cls='clear'
alias reload='exec zsh'
alias path='echo $PATH | tr ":" "\n"'
alias which='type -a'
alias psg='ps aux | grep'
if command -v docker &>/dev/null; then
  alias dps='docker ps'
  alias dc='docker compose'
fi
alias cz='chezmoi'

# ── Project aliases ───────────────────────────────────────────────────────────
alias scli="$HOME/workspace/bkhanale/scripts/dist/cli"
