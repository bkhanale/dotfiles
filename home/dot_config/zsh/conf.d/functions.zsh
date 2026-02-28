# conf.d/functions.zsh — custom shell functions

# mkcd — create a directory and cd into it
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# up [n] — go up n directory levels (default 1)
up() {
  local levels="${1:-1}"
  local path='..'
  for (( i=1; i<levels; i++ )); do
    path="../$path"
  done
  cd "$path"
}

# fcd — fuzzy-find and cd into a directory
fcd() {
  local dir
  dir="$(fd --type d --hidden --exclude .git | fzf --preview 'eza --tree --level=1 {}')" \
    && cd "$dir"
}

# fkill — fuzzy kill a process
fkill() {
  local pid
  pid="$(ps aux | tail -n +2 | fzf --multi | awk '{print $2}')"
  [[ -n "$pid" ]] && echo "$pid" | xargs kill "${1:--9}"
}

# gflog — fuzzy git log browser (requires fzf + bat)
gflog() {
  git log --oneline --color=always "$@" \
    | fzf --ansi --no-sort --reverse \
          --preview 'git show {1} | bat --color=always -l diff' \
          --bind 'enter:execute(git show {1} | bat --color=always -l diff | less -R)'
}

# extract — extract any archive
extract() {
  case "$1" in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.rar)     unrar x "$1" ;;
    *.gz)      gunzip "$1"  ;;
    *.tar)     tar xf "$1"  ;;
    *.tbz2)    tar xjf "$1" ;;
    *.tgz)     tar xzf "$1" ;;
    *.zip)     unzip "$1"   ;;
    *.Z)       uncompress "$1" ;;
    *.7z)      7z x "$1"   ;;
    *)         echo "'$1' cannot be extracted via extract()" ;;
  esac
}

# port — show what's listening on a port
port() {
  lsof -i ":${1:?usage: port <number>}"
}
