---
name: notify
description: Send a push notification to Bhushan's phone (ntfy.bhu.sh) when an agent needs his input, approval, a decision, or a credential and would otherwise sit blocked, or to surface something important that needs his attention (a failure, a finished long-running job, a risky action needing a go-ahead). Use it right before you ask a blocking question so work does not stall while he is away.
---

# notify — ping Bhushan's phone via ntfy

Use this when you are about to block on Bhushan and want him to unblock you fast:
you need a decision, an approval, a credential/secret, or a choice between
options to get unstuck — or you want to surface something important (a failure, a
long job that just finished, a risky action that needs his go-ahead).

Send the notification FIRST, then ask your question the normal way. The point is
that he gets pinged on his phone and can act quickly.

## How to send

Call the publisher (it handles auth + delivery):

```bash
~/.claude/skills/notify/ntfy-send.sh \
  --title "<short scannable summary of what you need>" \
  --priority 4 \
  --tags question \
  "<the ask + which project/repo + enough context to decide from a phone>"
```

- `--title` — the phone's headline. Short and specific ("Approval: deploy to prod?").
- `--priority` — 1–5. Default **4 (high)** alerts the phone. Use **5** for urgent /
  deploy-blocking; **3 or lower** for FYI you don't need to act on immediately.
- `--tags` — comma-separated ntfy emoji shortcodes for a glanceable icon, e.g.
  `question`, `warning`, `white_check_mark`, `rotating_light`, `robot`, `key`.
- `--click` — optional URL opened when the notification is tapped (PR, dashboard, etc.).
- **Body** — the final argument, or piped via stdin. ALWAYS name the project/repo
  and give enough context to decide without opening a laptop.

Long or multi-line bodies read better from stdin:

```bash
printf 'Deploy %s to prod?\nTests: green\nMigrations: 2 pending' "$branch" \
  | ~/.claude/skills/notify/ntfy-send.sh --title "Approval: prod deploy" --tags warning --priority 5
```

## When NOT to use

- Not for routine progress or anything he doesn't need to act on.
- Don't re-ping for the same ask — send once, then wait for his response.
- The Notification hook already auto-pings when Claude Code is idle-waiting on
  input or needs permission; use this skill for richer, intentional asks on top.

## Notes

- Topic `claude-code` on https://ntfy.bhu.sh (his phone is subscribed).
- Token comes from `pass show ai/ntfy-token`; the script keeps it out of argv/logs.
- On failure the script prints the error and exits non-zero — surface that to
  Bhushan rather than silently continuing (the ping did NOT reach his phone).
