#!/usr/bin/env bash
# ntfy-notification.sh — Claude Code `Notification` hook.
#
# Fires when Claude Code needs attention: a permission prompt, or ~60s idle
# while waiting on the user's input. Parses the hook JSON from stdin and pushes
# a phone notification via the shared publisher so work doesn't sit blocked.
#
# Bhushan does NOT want false positives. Only a permission prompt is a genuine
# block (the agent cannot proceed until he responds), so this hook pings ONLY on
# permission messages. Everything else is suppressed: the idle-timeout event
# ("Claude is waiting for your input") fires after ~60s of no typing even when
# he's right there; computer-use / login / other messages aren't actionable;
# empty or unparseable payloads carry no signal; and any future message type is
# suppressed by default. (His MDM managed-settings.json forces
# defaultMode=default and disables bypassPermissions, so permission prompts do
# occur.) Intentional asks with context go through the `notify` skill instead.
#
# Safety net, not the star: it must NEVER hang or block the session. Time-boxed
# via the publisher's curl --max-time, and always exits 0.

SEND="${NTFY_SEND:-$HOME/.claude/skills/notify/ntfy-send.sh}"

payload="$(cat)"

if command -v jq >/dev/null 2>&1; then
  message="$(printf '%s' "$payload" | jq -r '.message // empty' 2>/dev/null)"
  cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"
else
  message="$(printf '%s' "$payload" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
  cwd="$(printf '%s' "$payload" | sed -n 's/.*"cwd"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
fi

# Allowlist: ping ONLY on a genuine permission block. Suppress everything else
# (idle timeout, computer-use/login/other messages, empty/unparseable payloads,
# and any future message type) so there are no false positives.
shopt -s nocasematch
if [[ "$message" != *permission* ]]; then
  exit 0
fi
shopt -u nocasematch

project="$(basename "${cwd:-$PWD}")"

if [[ -x "$SEND" ]]; then
  "$SEND" --title "Claude needs you — ${project}" --priority 4 --tags bell "$message" >/dev/null 2>&1 || true
fi

exit 0
