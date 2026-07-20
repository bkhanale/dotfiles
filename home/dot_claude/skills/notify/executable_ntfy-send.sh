#!/usr/bin/env bash
# ntfy-send.sh — publish a push notification to ntfy.bhu.sh/claude-code.
#
# The single place that talks to ntfy. Shared by the `notify` skill
# (agent-invoked) and the Notification hook (automatic safety net).
#
# Usage:
#   ntfy-send.sh [--title T] [--priority 1-5] [--tags a,b] [--click URL] <message...>
#   echo "message" | ntfy-send.sh [flags]        # body from stdin
#
# Auth: bearer token from `pass show ai/ntfy-token` (override the entry with
# NTFY_PASS_ENTRY), handed to curl via a config file on a file descriptor
# (process substitution) so the token never appears in argv / `ps` / logs.

set -euo pipefail

TOPIC_URL="${NTFY_TOPIC_URL:-https://ntfy.bhu.sh/claude-code}"
PASS_ENTRY="${NTFY_PASS_ENTRY:-ai/ntfy-token}"

title=""
priority="4"
tags=""
click=""
msg_parts=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title|-t)    title="${2:-}"; shift 2 ;;
    --priority|-p) priority="${2:-}"; shift 2 ;;
    --tags)        tags="${2:-}"; shift 2 ;;
    --click)       click="${2:-}"; shift 2 ;;
    --)            shift; msg_parts+=("$@"); break ;;
    -*)            echo "ntfy-send: unknown flag: $1" >&2; exit 2 ;;
    *)             msg_parts+=("$1"); shift ;;
  esac
done

# Body: from remaining args if any, otherwise from stdin.
if [[ ${#msg_parts[@]} -gt 0 ]]; then
  body="${msg_parts[*]}"
elif [[ ! -t 0 ]]; then
  body="$(cat)"
else
  echo "ntfy-send: no message given (pass as args or pipe via stdin)" >&2
  exit 2
fi

if [[ -z "${body//[[:space:]]/}" ]]; then
  echo "ntfy-send: message is empty" >&2
  exit 2
fi

# Fetch the token; fail clearly if the pass entry is missing or locked.
if ! token="$(pass show "$PASS_ENTRY" 2>/dev/null)"; then
  echo "ntfy-send: could not read token from 'pass show ${PASS_ENTRY}'" >&2
  exit 1
fi
token="${token%%$'\n'*}"   # first line only
if [[ -z "$token" ]]; then
  echo "ntfy-send: token from 'pass show ${PASS_ENTRY}' is empty" >&2
  exit 1
fi

# Non-secret headers are safe in argv.
hdr=(-H "X-Priority: ${priority}")
[[ -n "$title" ]] && hdr+=(-H "X-Title: ${title}")
[[ -n "$tags"  ]] && hdr+=(-H "X-Tags: ${tags}")
[[ -n "$click" ]] && hdr+=(-H "X-Click: ${click}")

# Auth via config-fd so the token stays out of argv/ps; body via stdin.
if curl -sS --max-time 10 --retry 2 --retry-delay 1 \
     --config <(printf 'header = "Authorization: Bearer %s"\n' "$token") \
     "${hdr[@]}" \
     --data-binary @- \
     "$TOPIC_URL" <<<"$body" >/dev/null; then
  echo "ntfy-send: sent to ${TOPIC_URL}" >&2
else
  rc=$?
  echo "ntfy-send: publish failed (curl exit ${rc})" >&2
  exit 1
fi
