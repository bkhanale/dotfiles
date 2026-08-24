# AGENTS.md — facts for AI agents working in this dotfiles repo

Scope: this repo only. chezmoi never copies this file elsewhere. Per-project
agent rules belong in that project's own `CLAUDE.md`/`AGENTS.md`.

## chezmoi

- chezmoi-managed. Source lives in `home/`; `.chezmoiroot` = `home`, so
  `home/dot_config/` → `~/.config/`.
- Never edit `~/.zshrc` (or any target) directly — edit the source under `home/`.
- Naming: `dot_foo`→`~/.foo`, `private_foo`→mode 0600, `executable_foo`→mode 0755,
  `foo.tmpl`→Go-template-rendered, `run_`→every apply, `run_once_`→once ever
  (keyed on script hash), `run_onchange_`→when script content changes.
- Verify after edits: `chezmoi apply` then `chezmoi diff` (must be clean).

### Templates

- Guard OS with `{{ if eq .chezmoi.os "darwin" }}` / `"linux"`. Both Arch and
  Debian are `"linux"`; split with `{{ if eq .chezmoi.osRelease.id "debian" }}`.
- User data: `.name`, `.email`, `.gpgKey`. Built-ins: `.chezmoi.os`,
  `.chezmoi.arch`, `.chezmoi.hostname`, `.chezmoi.homeDir`.
- **Pitfall:** `promptStringOnce` fails silently when `chezmoi init` runs from a
  bash script — prompts leave `chezmoi.toml` empty, then apply dies with
  `map has no entry for key "name"`. Fix (see `install.sh`): pre-write the
  `[data]` block via bash `read`, then `chezmoi init --apply` renders the full
  template and `promptStringOnce` returns the pre-written values.

## Shell (zsh, no framework)

- Do not add oh-my-zsh/Prezto/any framework, powerline, or pure prompt. Prompt is
  Starship. Do not hard-code `~/` — use `$XDG_CONFIG_HOME`/`$XDG_DATA_HOME`/
  `$XDG_CACHE_HOME`/`$XDG_STATE_HOME`.
- `ZDOTDIR` is set in `~/.zshenv` (`home/dot_zshenv`) → zsh loads config from
  `~/.config/zsh/`. Because `ZDOTDIR` is set *after* zsh already read `~/.zshenv`,
  `$ZDOTDIR/.zshenv` (`home/dot_config/zsh/dot_zshenv`) is never sourced — it is
  documentation only.
- `dot_zshrc` is thin: runs `compinit`, sources `conf.d/*.zsh` alphabetically,
  loads plugins, inits Starship, then sources per-machine overrides last.
- New zsh module: add `conf.d/mymodule.zsh`, one concern per file. Numeric prefix
  (`10_`) only when order matters. No conditional sourcing inside `conf.d/` — put
  the logic in the file.

### Per-machine overrides (never committed)

- `~/.config/zsh/secrets.zsh` — tokens/keys/passwords. `~/.config/zsh/local.zsh`
  — non-secret per-machine config (PATH, work aliases, env overrides).
- Both are gitignored AND in `home/.chezmoiignore`; both sourced at end of
  `dot_zshrc` (secrets first). `*.example` templates are committed.
- Never commit real secrets. A new tracked config that needs an env var:
  document it in `secrets.zsh.example` (secret) or `local.zsh.example` (not).
  Do not bake a default into `conf.d/*`.

## Platform differences

Package sources: macOS `Brewfile`, Arch `packages.arch.txt`, Debian/Ubuntu
`packages.debian.txt`. `install.sh` routes Linux by `/etc/os-release`:
`ID`/`ID_LIKE` = arch → arch branch, = debian/ubuntu → debian branch.

| Concern | macOS | Arch | Debian/Ubuntu |
|---|---|---|---|
| pinentry | pinentry-mac | pinentry-curses | pinentry-curses |
| chezmoi/starship/zoxide/zellij | brew | pacman | upstream installer → `~/.local/bin` (apt versions too old/buggy) |
| neovim | brew | pacman | upstream tarball `~/.local/nvim` (need ≥0.11 for `vim.lsp.config`) |
| `bat`/`fd` binary | `bat`/`fd` | `bat`/`fd` | `batcat`/`fdfind` (install.sh symlinks to `~/.local/bin`) |
| native build deps | Xcode CLT | base-devel | build-essential |
| ghostty | brew cask | pacman | not packaged (install manually only if local terminal wanted) |
| cmux | brew cask (macOS-only) | — | — |

Debian also compiles `terminfo/ghostty.terminfo` into `~/.terminfo` for SSH
sessions with `TERM=xterm-ghostty`.

## AI coding agents (Claude Code + OpenCode + Codex)

- Tracked configs: `dot_claude/settings.json` (+`keybindings.json`),
  `dot_config/ccstatusline/settings.json`, `dot_config/opencode/{opencode,tui}.json`,
  `dot_codex/private_{config,plan.config,review.config}.toml`.
- One source of truth: `CLAUDE.md` is a thin `@AGENTS.md` import. OpenCode lists
  `AGENTS.md`/`CLAUDE.md` in `instructions`; Codex auto-loads `AGENTS.md`.
- **Not tracked (intentional):** the `claude`/`opencode`/`codex` binaries
  (self-updating installers) and all runtime state under `~/.claude`/`~/.codex`
  (sessions, projects, history, caches, `auth.json`). API keys live in
  `secrets.zsh`; Codex login in `~/.codex/auth.json`.
- **Local-only, never commit:** Claude hooks/skills/plugins/marketplaces
  (gitignored: `home/dot_claude/hooks/`, `home/dot_claude/skills/`) and MCP
  server definitions for any agent. Skills/rules are managed in a separate repo.
- Schemas (validate against, don't guess keys — some silently reject unknown
  fields): Claude `json.schemastore.org/claude-code-settings.json`; OpenCode
  `opencode.ai/config.json` (models are `provider/model`); Codex
  `developers.openai.com/codex/config-schema.json`.
- **Codex pitfall:** it writes runtime keys (`projects.*.trust_level`,
  `tui.*`) back into `~/.codex/config.toml`. Those are NOT tracked — if
  `chezmoi diff` shows them, run `chezmoi apply --force`; don't promote upstream.
- ccstatusline: prefer `/statusline` in Claude Code over hand-editing JSON;
  renderer uses the global `ccstatusline` executable (npm-installed separately).

## Ghostty

- `~/.config/ghostty/config` from `config.tmpl`. Format is `key = value`, not TOML.
- **Verify keys — website docs are incomplete.** Authoritative:
  `ghostty +show-config --default --docs` (every key), `+list-keybinds --default`,
  `+show-config` (validate). If a key isn't in `--default --docs`, it doesn't exist.
  Non-existent keys people assume: `audible-bell` (use `bell-features`),
  `dynamic-title` (comes via `shell-integration-features = title`).
- Startup-only (reload won't apply; need full quit): `macos-titlebar-style`,
  `macos-option-as-alt`, font selection, `shell-integration` mode, `command`.
- macOS native tabs (`Cmd+T`) need `macos-titlebar-style` = native/transparent/tabs;
  `hidden`/`window-decoration = none` silently disables tabs.
- Keybind syntax: raw bytes `keybind = shift+enter=text:\x1b\r`; action
  `keybind = super+grave_accent=toggle_quick_terminal`. Don't rebind macOS defaults.

## cmux (macOS-only, 14+)

- Ghostty-based terminal, installed as auto-updating brew cask; runs alongside
  Ghostty (not a replacement). Excluded off darwin via `home/.chezmoiignore` guard.
- **Reads the same `~/.config/ghostty/config`** — never duplicate terminal
  settings (font, colors, keybinds) into `cmux.json`.
- `dot_config/cmux/cmux.json` is JSONC, cmux-only settings with no Ghostty
  equivalent. Kept deliberately thin.
- Don't guess keys: the auto-created `~/.config/cmux/cmux.json` template is the
  version-matched key list; schema at
  `raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json`.
  Validate `cmux config doctor`; reload both configs `cmux reload-config`. Back up
  before hand-editing. cmux `shortcuts` are app-actions only — raw-byte terminal
  binds stay in Ghostty config.

## Brewfile

- Do NOT add `tap "homebrew/bundle"` (deprecated; `brew bundle` is built in).
- Casks go at the bottom after all `brew` lines. Verify with `brew bundle`.

## GPG / pass

- **Perms pitfall:** after chezmoi touches `~/.gnupg`, keyboxd may go read-only
  (`Attempt to write a readonly SQL database`). Fix (install.sh does this):
  `chmod 700 ~/.gnupg`; dirs 700, files 600; `gpgconf --kill all`.
- Signing: `git commit` `Inappropriate ioctl for device` → ensure `GPG_TTY=$(tty)`
  (exported in `conf.d/exports.zsh`). pinentry missing → `gpgconf --kill gpg-agent`.
- `pass` is the local vault at default `~/.password-store` (deliberately not moved
  via `PASSWORD_STORE_DIR`: agents run plain bash, which ignores that var). Its own
  git repo, synced independently — never nest inside this repo.
- Key model: one GPG key per device; private keys never leave their device; store
  encrypted to all devices' keys (`.gpg-id`). `gpgKey` doubles as git signingkey
  and pass identity. Init on apply via `run_init-password-store.sh.tmpl` (a `run_`,
  not `run_once_`, so it retries before the key exists; every guard exits 0 fast).
- Agent access: `pass show ai/<name>` (agent-readable convention `ai/`; human-only
  elsewhere). Every-shell env vars live in one `env/shell` entry that `secrets.zsh`
  evals with a single `gpg -dq` — do NOT add one `pass show` per var (~190ms each
  at startup). Templates can pull via `{{ pass "ai/example" }}`.

## install.sh

Single bootstrap for all OSes. Non-destructive — backs up (`.pre-chezmoi.bak`,
`cp -p`), never deletes. Idempotent/re-runnable; each step short-circuits.
Runs `chezmoi init --apply --force` (init renders full `chezmoi.toml`; force
avoids TTY prompts). Deliberately does NOT remove version managers/oh-my-zsh/etc.
or extract secrets from old configs. Don't add a removal step — back up, don't delete.

**Bash land-mines (all fixed; keep them fixed):**
- Bare `return` after `[[ ]] || ...` propagates exit 1 under `set -e` → write
  `return 0` when early-exit is the success path.
- `read -r` on closed stdin returns 1 → `set -e` aborts silently. Guard `[[ -t 0 ]]`
  or accept env vars (`CHEZMOI_NAME`/`CHEZMOI_EMAIL`/`CHEZMOI_GPG_KEY`).
- `chezmoi init --apply` without `--force` in non-tty mode prompts and fails.

## Neovim

`home/dot_config/nvim/`, entry `init.lua`, plugins via lazy.nvim (bootstrapped in
`lua/plugins.lua`). No plugin-manager install scripts outside `plugins.lua`.

## Conventions

- Git commits: do NOT add `Co-Authored-By` trailers.
- Shell scripts: `shellcheck`-clean. A local pre-commit hook (`.githooks/pre-commit`,
  enable with `git config core.hooksPath .githooks`) lints staged `*.sh`.
- Portability: no personal names, usernames, private hostnames, org names, or
  service endpoints in tracked files — those go in `local.zsh`. Use placeholders
  (`your-github-user`, `example.com`, `my-project`) in examples.
