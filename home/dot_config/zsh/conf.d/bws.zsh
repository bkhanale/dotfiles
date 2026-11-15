# conf.d/bws.zsh — pass-like helpers for Bitwarden Secrets Manager (bws)
#
# Needs BWS_ACCESS_TOKEN (secrets.zsh) and BWS_PROJECT_ID (local.zsh).
#   bws-ls              list secret keys
#   bws-show KEY        print one secret value
#   bws-insert KEY      prompt for a hidden value and create the secret
#   bws-edit KEY        prompt for a hidden value and replace the secret value

# Print the id of the secret named $1 (empty if it does not exist).
_bws_id() {
  bws secret list -o json | jq -r --arg k "$1" '.[] | select(.key == $k) | .id'
}

bws-ls() {
  bws secret list -o json | jq -r '.[].key' | sort
}

bws-show() {
  (( $# == 1 )) || { print -u2 "usage: bws-show KEY"; return 2; }
  local val
  val="$(bws secret list -o json | jq -r --arg k "$1" '.[] | select(.key == $k) | .value')"
  [[ -n $val ]] || { print -u2 "bws-show: no secret named $1"; return 1; }
  print -r -- "$val"
}

bws-insert() {
  (( $# == 1 )) || { print -u2 "usage: bws-insert KEY"; return 2; }
  [[ $1 =~ '^[A-Z][A-Z0-9_]*$' ]] || { print -u2 "bws-insert: use UPPER_SNAKE_CASE"; return 2; }
  [[ -n ${BWS_PROJECT_ID:-} ]] || { print -u2 "bws-insert: set BWS_PROJECT_ID in local.zsh"; return 1; }
  [[ -z $(_bws_id "$1") ]] || { print -u2 "bws-insert: $1 exists, use bws-edit"; return 1; }
  local val
  read -rs "val?Value for $1: "; print
  [[ -n $val ]] || { print -u2 "bws-insert: empty value"; return 1; }
  bws secret create -o none -- "$1" "$val" "$BWS_PROJECT_ID" && print "created $1"
}

bws-edit() {
  (( $# == 1 )) || { print -u2 "usage: bws-edit KEY"; return 2; }
  local id val
  id="$(_bws_id "$1")"
  [[ -n $id ]] || { print -u2 "bws-edit: no secret named $1"; return 1; }
  read -rs "val?New value for $1: "; print
  [[ -n $val ]] || { print -u2 "bws-edit: empty value"; return 1; }
  bws secret edit -o none --value="$val" -- "$id" && print "updated $1"
}
