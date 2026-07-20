# AGENTS.md — Instructions for AI Coding Agents

This file documents conventions for AI agents (Copilot, Claude, etc.) working in this dotfiles repo.

---

## Repo Overview

This is a **chezmoi**-managed dotfiles repo. Source files live in `home/` and map to the home directory on apply. chezmoi handles templating, encryption, and cross-platform differences.

`.chezmoiroot` is set to `home/` — chezmoi treats `home/` as the source root, so `home/dot_config/` maps to `~/.config/`.

---

## chezmoi Naming Conventions

| Source filename       | Target path              |
|-----------------------|--------------------------|
| `dot_foo`             | `~/.foo`                 |
| `dot_config/`         | `~/.config/`             |
| `dot_zshrc`           | `~/.zshrc`               |
| `foo.tmpl`            | `~/foo` (after template render) |
| `private_foo`         | `~/foo` (mode 0600)      |
| `executable_foo`      | `~/foo` (mode 0755)      |

Files ending in `.tmpl` are rendered as Go templates before being written to the target.

---

## Template Syntax

```
{{- if eq .chezmoi.os "darwin" }}
# macOS-only content
{{- else if eq .chezmoi.os "linux" }}
# Linux-only content
{{- end }}
```

User data (from `~/.config/chezmoi/chezmoi.toml`) is available as:
- `.name`
- `.email`
- `.gpgKey`

Built-in chezmoi data:
- `.chezmoi.os` — `"darwin"` or `"linux"`
- `.chezmoi.arch` — `"amd64"`, `"arm64"`, etc.
- `.chezmoi.hostname`
- `.chezmoi.homeDir`

### chezmoi Data — Critical Note

**Do NOT rely on `promptStringOnce` being called interactively from a bash script.**
When `chezmoi init` is invoked from inside a bash script (e.g. `install.sh`), the prompts often fail silently, leaving `~/.config/chezmoi/chezmoi.toml` empty. Then `chezmoi apply` fails with:

```
template: ...: map has no entry for key "name"
```

**Correct approach** (used by `install.sh:write_chezmoi_config` + `apply_chezmoi`): pre-populate `chezmoi.toml`'s `[data]` block via bash `read`, then run `chezmoi init --apply` so the full template (with `sourceDir`, `[diff]`, `[edit]`, `[merge]`) is rendered. `promptStringOnce` returns the pre-written values without prompting.

```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<EOF
[data]
  name    = "$_name"
  email   = "$_email"
  gpgKey  = "$_gpg"
EOF
chezmoi init --apply --source="$SCRIPT_DIR"
```

---

## Directory Layout

```
home/
├── dot_zshenv          # ZDOTDIR + XDG env vars — loaded for ALL zsh instances
└── dot_config/zsh/
    ├── dot_zshenv      # placeholder (see note below); zsh does NOT source this
    ├── dot_zshrc       # interactive shell bootstrap — thin; sources conf.d/*
    ├── secrets.zsh.example
    ├── local.zsh.example
    └── conf.d/         # modular files sourced alphabetically by dot_zshrc
    ├── aliases.zsh
    ├── completions.zsh
    ├── exports.zsh
    ├── functions.zsh
    ├── keybindings.zsh
    └── tools.zsh
```

> **About `$ZDOTDIR/.zshenv`** — zsh's startup order is `/etc/zsh/zshenv` →
> `$HOME/.zshenv` → (if interactive) `$ZDOTDIR/.zshrc` etc. The
> `$ZDOTDIR/.zshenv` path is **not** read in this setup because `ZDOTDIR` is
> set inside `~/.zshenv` (after that file has already been read). The file at
> `home/dot_config/zsh/dot_zshenv` exists only as documentation; deleting it
> would change nothing.

- **Never put secrets in tracked files.** Secrets go in `~/.config/zsh/secrets.zsh` (gitignored + chezmoi-ignored).
- **Per-machine, non-secret config goes in `~/.config/zsh/local.zsh`** — also gitignored + chezmoi-ignored, sourced from `dot_zshrc` after `conf.d/*`.
- **Never hard-code paths** — use XDG variables (`$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_CACHE_HOME`, `$XDG_STATE_HOME`).
- OS-specific logic belongs in `.tmpl` files using chezmoi template guards.

---

## Platform Differences

| Concern | macOS | Arch Linux | Debian / Ubuntu |
|---|---|---|---|
| Package manager | Homebrew (`Brewfile`) | pacman / yay (`packages.arch.txt`) | apt (`packages.debian.txt`) |
| GPG pinentry | `pinentry-mac` | `pinentry-curses` | `pinentry-curses` |
| Font path | managed by Homebrew Cask | system fonts dir (pacman) | `~/.local/share/fonts` (manual zip from ryanoasis/nerd-fonts) |
| chezmoi install | `brew install chezmoi` | `yay -S chezmoi` | `get.chezmoi.io` installer → `~/.local/bin` |
| Starship install | `brew install starship` | `pacman -S starship` | `starship.rs/install.sh` → `~/.local/bin` (not in apt) |
| Zoxide install | `brew install zoxide` | `pacman -S zoxide` | upstream installer → `~/.local/bin` (apt ships buggy v0.4.3 — `cd` recurses infinitely) |
| Neovim install | Brewfile | `pacman -S neovim` | upstream tarball → `~/.local/nvim/` (apt ships ≤ 0.7.2; we need ≥ 0.11 for `vim.lsp.config` / `vim.lsp.enable`) |
| Native plugin build deps | Xcode CLT (auto via brew) | `base-devel` (installed unconditionally) | `build-essential` (in packages.debian.txt) — needed by telescope-fzf-native + treesitter |
| Zellij install | `brew install zellij` | `pacman -S zellij` | upstream installer → `~/.local/bin` (static musl tarball; not in apt) |
| Ghostty install | Brewfile cask | `pacman -S ghostty` | not packaged — install manually only if you want Ghostty as a *local* terminal on the box (SSH'd-into VMs don't need it) |
| `bat` binary name | `bat` | `bat` | `batcat` (install.sh symlinks to `~/.local/bin/bat`) |
| `fd` binary name | `fd` | `fd` | `fdfind` (install.sh symlinks to `~/.local/bin/fd`) |

### Detecting Linux distro family

`install.sh` routes Linux installs by reading `/etc/os-release`:

- `ID=arch` (and arch-derivatives via `ID_LIKE=arch`) → arch branch
- `ID=debian` or `ID=ubuntu` (and derivatives via `ID_LIKE=debian`) → debian branch

Templates use `{{ if eq .chezmoi.os "linux" }}` for both — the linux branch values
(e.g. `/usr/bin/pinentry-curses`, `helper = cache`, `window-decoration = true`)
are valid on both Arch and Debian. If you ever need to split them, switch to
`{{ if eq .chezmoi.osRelease.id "debian" }}`.

---

## Adding a New Config File

1. Create the file at `home/dot_config/<tool>/<file>` (or `home/dot_config/<tool>/<file>.tmpl` if it needs templating).
2. If it references a secret, document the expected env var in `home/dot_config/zsh/secrets.zsh.example`. If it references non-secret per-machine config, document it in `local.zsh.example`.
3. If it's macOS/Linux specific, wrap content with `{{- if eq .chezmoi.os "darwin" }}` guards.
4. Run `chezmoi apply` to verify, then `chezmoi diff` to confirm it's clean.

---

## Extending conf.d

To add a new Zsh module:

1. Create `home/dot_config/zsh/conf.d/mymodule.zsh`.
2. Files are sourced alphabetically — use a numeric prefix (`10_mymodule.zsh`) only if ordering matters.
3. Keep each file focused: one concern per file.
4. Do not source files conditionally inside `conf.d/` — put that logic in the file itself.

---

## Per-Machine Override Files

Two parallel files at `~/.config/zsh/`. Both are gitignored AND in
`home/.chezmoiignore` so `chezmoi apply` will never overwrite them. Both are
sourced at the end of `dot_zshrc` (after `conf.d/*`) if present, in this order:

| File | Contents |
|---|---|
| `secrets.zsh` | Tokens, API keys, passwords (e.g. `GITHUB_TOKEN`, `OPENAI_API_KEY`) |
| `local.zsh`   | Non-secret per-machine config — PATH additions, work-only aliases, env overrides |

Each has a corresponding `*.example` template committed to the repo. The
examples are intentionally generic — there is no canonical list of expected
variables, since users have wildly different needs.

**Never** commit real tokens, passwords, or API keys. If you see a secret in
a tracked file, remove it immediately and rotate the credential.

### When adding a new tracked config that depends on an env var

Document the var in `home/dot_config/zsh/secrets.zsh.example` (if secret) or
`local.zsh.example` (if not). Do **not** add a default value to `conf.d/*` —
that becomes a baked-in opinion that everyone inherits.

---

## Neovim

Config lives in `home/dot_config/nvim/`. Entry point is `init.lua`. Plugins are managed by `lazy.nvim` (auto-bootstrapped in `lua/plugins.lua`). Do not add plugin manager install scripts outside of `plugins.lua`.

---

## Agentic Dev (Claude Code + OpenCode + Codex)

All three AI CLIs are first-class in this repo. Their configs are tracked;
their binaries and runtime state are not.

### Tracked files

| Source path | Target | Purpose |
|---|---|---|
| `home/dot_claude/settings.json` | `~/.claude/settings.json` | Claude Code config (permissions, plugins, voice, statusLine) |
| `home/dot_config/ccstatusline/settings.json` | `~/.config/ccstatusline/settings.json` | Status-line layout for Claude Code (rendered by `npx ccstatusline`) |
| `home/dot_config/opencode/opencode.json` | `~/.config/opencode/opencode.json` | OpenCode model, MCP servers, agent profiles, instructions list |
| `home/dot_config/opencode/tui.json` | `~/.config/opencode/tui.json` | OpenCode TUI theme + scroll/diff prefs |
| `home/dot_codex/private_config.toml` | `~/.codex/config.toml` (mode 0600) | Codex CLI config (approvals, sandbox, reasoning, TUI theme) |

`opencode.json` declares `"instructions": ["AGENTS.md", "CLAUDE.md", ".cursor/rules/*.md"]`,
so OpenCode picks up the same project-level guidance as Claude Code (which
auto-loads `CLAUDE.md`). Codex auto-loads `AGENTS.md` from the project root
(see `project_doc_fallback_filenames` in the Codex config schema). Keep
`CLAUDE.md` as a thin `@AGENTS.md` import so there is exactly one source of
truth.

### NOT tracked (intentionally)

- The `claude`, `opencode`, and `codex` **binaries** — all three ship native
  installers with built-in auto-update. Install once per machine:
  ```sh
  curl -fsSL https://claude.ai/install.sh | bash   # → ~/.local/bin/claude
  curl -fsSL https://opencode.ai/install | bash    # → ~/.opencode/bin/opencode
  brew install codex                               # macOS; or `npm i -g @openai/codex`
  ```
  PATH is already wired up: `~/.local/bin` in `dot_zshenv`, `~/.opencode/bin`
  in `conf.d/exports.zsh`. `codex` lands in Homebrew's bin (already on PATH).
- Runtime state under `~/.claude/` and `~/.codex/`: `sessions/`, `projects/`,
  `history.jsonl`, `file-history/`, `plugins/cache/`, `shell-snapshots/`,
  `telemetry/`, `auth.json`, `logs_*.sqlite*`, `state_*.sqlite*`,
  `models_cache.json`, `memories/`, etc. These regenerate per-machine and
  would churn `chezmoi diff` constantly. Only the single tracked config file
  per tool is managed; chezmoi leaves siblings alone.
- Anthropic / OpenAI API keys — keep them in
  `~/.config/zsh/secrets.zsh` (gitignored + chezmoi-ignored). Codex's
  ChatGPT-login credentials live in `~/.codex/auth.json` (also untracked).

### When editing the configs

- **Claude Code** — `dot_claude/settings.json` follows the schema at
  `https://json.schemastore.org/claude-code-settings.json` (already pinned via
  `$schema`). When in doubt about valid keys, check the docs rather than
  guessing — Claude Code rejects unknown fields silently in some versions.
- **OpenCode** — `opencode.json` follows `https://opencode.ai/config.json`.
  Models are `provider/model` strings (e.g. `anthropic/claude-sonnet-4-5`).
  Agent definitions under `agent.<name>` scope tool permissions per sub-agent
  (read-only `plan` and `review` agents are pre-defined).
- **Codex** — `dot_codex/private_config.toml` follows
  `https://developers.openai.com/codex/config-schema.json` (pinned via the
  `#:schema` line). Reference: <https://developers.openai.com/codex/config>.
  Codex writes runtime state (`projects.<path>.trust_level`,
  `tui.model_availability_nux.*`, etc.) back into `~/.codex/config.toml` over
  time — those keys are intentionally NOT in the tracked file. If
  `chezmoi diff` shows them after a session, run `chezmoi apply --force` to
  drop them; do not promote them upstream.
- **ccstatusline** — schema is the `ccstatusline` npm package; prefer editing
  via `/statusline` inside Claude Code over hand-rolling JSON.

### Sub-agents and project overrides

Per-project agent rules belong in that project's own `CLAUDE.md` /
`AGENTS.md` / `.cursor/rules/*.md`, not in this dotfiles repo. The repo-root
`AGENTS.md` here is for *this* repo only; chezmoi never copies it elsewhere.

---

## Ghostty

Config lives in `home/dot_config/ghostty/config.tmpl` → `~/.config/ghostty/config`. Format is `key = value` per line (NOT TOML), comments start with `#`.

### Verify config keys before writing them — do not guess

The Ghostty website docs are incomplete. Authoritative sources, in order of preference:

```bash
# Print the full default config with inline doc comments for every key:
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config --default --docs

# Print every default keybinding (action → key chord):
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-keybinds --default

# Validate the current config (catches unknown fields, bad values):
/Applications/Ghostty.app/Contents/MacOS/ghostty +show-config
```

If a key isn't in `+show-config --default --docs`, it does not exist. Common mistakes:

- `audible-bell` — does NOT exist. Bell behavior is controlled via `bell-features` (default empty = silent).
- `dynamic-title` — does NOT exist. Title updates come automatically via `shell-integration-features = title`.

### Startup-only options — reload won't apply them

`reload_config` (default `Cmd+Shift+,`) does NOT pick up changes to certain options. These require a full quit (`Cmd+Q`) and relaunch:

- `macos-titlebar-style`
- `macos-option-as-alt`
- `font-family` and other font selection options
- `shell-integration` (the mode itself; features can reload)
- `command`

If you change one of these, tell the user to fully quit and reopen.

### macOS native tabs require a titlebar

`Cmd+T` (`new_tab`) silently falls back to opening a new window when no titlebar is rendered. Required: `macos-titlebar-style` must be `native`, `transparent`, or `tabs`. Using `hidden` (or `window-decoration = none`) disables tabs entirely with no warning.

### Default macOS keybinds worth knowing (don't re-bind)

```
super+t          new_tab
super+n          new_window
super+w          close_surface
super+d          new_split:right
super+shift+d    new_split:down
super+shift+,    reload_config
super+,          open_config
super+=          increase_font_size
super+-          decrease_font_size
super+0          reset_font_size
super+[ / super+]   previous_tab / next_tab
super+1..9       goto_tab:N
super+alt+arrow  goto_split:direction
```

### Key-binding syntax

- Send raw bytes: `keybind = shift+enter=text:\x1b\r`
- Bind a built-in action: `keybind = super+grave_accent=toggle_quick_terminal`
- Modifiers: `super` (Cmd), `alt` (Opt), `ctrl`, `shift`. Use `+` to combine.

---

## cmux

[cmux](https://cmux.com/docs) is a **macOS-only** (14+) Ghostty-*based* terminal
and workspace manager for AI coding agents, installed as a Homebrew cask
(`cask "cmux"`, auto-updating). It runs *alongside* Ghostty — it is not a
replacement.

### It shares Ghostty's config — do NOT duplicate terminal settings

cmux embeds Ghostty and reads the **same** `~/.config/ghostty/config` that
standalone Ghostty uses (managed by `dot_config/ghostty/config.tmpl`). So all
terminal look & feel — font, Tokyo Night colours, scrollback, shell integration,
and keybinds (`shift+enter`, the Cmd+arrow natural-editing binds) — is already
"ported" for free. **Never copy those into `cmux.json`.** Ghostty's own guidance,
printed by `cmux --help`: *"prefer Ghostty config for terminal behavior Ghostty
already supports."* A few Ghostty window keys (`macos-titlebar-style`,
`window-decoration`) have no effect inside cmux since it draws its own chrome —
harmless, and they still apply to standalone Ghostty.

### cmux.json — cmux-only app behavior

`home/dot_config/cmux/cmux.json` → `~/.config/cmux/cmux.json`. Format is **JSONC**
(JSON with comments + trailing commas). It holds only settings with no Ghostty
equivalent (appearance, sidebar, notifications, browser, app shortcuts,
workspaces). The tracked file is a deliberately thin "faithful port" — only the
handful of settings that mirror the Ghostty config or keep cmux visually
consistent:

| Ghostty pref | cmux.json key |
|---|---|
| `copy-on-select` | `terminal.copyOnSelect: true` |
| `confirm-close-surface = false` | `app.warnBeforeClosingTab: false` |
| dark Tokyo Night theme | `app.appearance: "dark"` + `sidebarAppearance.matchTerminalBackground: true` |

Everything else stays at cmux defaults, except two personal-preference
toggles: `sendAnonymousTelemetry` and `reorderOnNotification` are both set to
`false` (the latter stops the sidebar reshuffling workspaces to the top when
they get a notification).

### macOS-only

cmux does not exist on Linux, so `.config/cmux/cmux.json` is excluded off darwin
via a `{{ if ne .chezmoi.os "darwin" }}` guard in `home/.chezmoiignore` (rather
than an OS `.tmpl` guard, which would still write an empty file on Linux).

### Editing & verifying — do not guess keys

- cmux auto-creates a fully-commented `cmux.json` template on first launch when
  the file is missing, and does **not** write runtime/Settings-window state back
  into it (those live in the app store + a legacy `settings.json`). So the
  tracked file stays authoritative and `chezmoi diff` stays clean — unlike Codex.
- The installed template at `~/.config/cmux/cmux.json` is the authoritative,
  version-matched list of every key and default (regenerate by removing it and
  relaunching cmux). The JSON schema is at
  `https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json`.
- Validate with `cmux config doctor` (or `cmux config validate`). Reload without
  an app restart with `cmux reload-config` — it reloads BOTH `cmux.json` and the
  Ghostty config.
- cmux shortcuts (`shortcuts.bindings` in `cmux.json`) are **app-level actions
  only** — they cannot send raw bytes to the shell. Terminal keybinds like
  `shift+enter=text:...` must stay in the Ghostty config.
- Before hand-editing an existing `cmux.json`, back it up to a timestamped `.bak`
  (cmux's own guidance).

---

## Brewfile

- Do **not** add `tap "homebrew/bundle"` — this tap is deprecated and was removed. `brew bundle` is now built into Homebrew itself.
- Casks go at the bottom of the Brewfile after all `brew` lines.
- After adding a new formula, run `brew bundle --file=Brewfile` to verify it installs cleanly.

---

## GPG

### Permissions (critical)

After `chezmoi apply` writes to `~/.gnupg/`, directory permissions can become incorrect, causing `keyboxd` to open its SQLite database read-only. This manifests as:

```
gpg: error writing keyring '[keyboxd]': Attempt to write a readonly SQL database
```

**Fix** (always run after chezmoi apply touches `.gnupg`):

```bash
chmod 700 ~/.gnupg
find ~/.gnupg -type d -exec chmod 700 {} \;
find ~/.gnupg -type f -exec chmod 600 {} \;
gpgconf --kill all   # restart keyboxd and gpg-agent fresh
```

`install.sh:fix_gnupg_perms` does this automatically.

### Signing failures

- If `git commit` fails with `Inappropriate ioctl for device`: ensure `GPG_TTY=$(tty)` is set. It is exported in `conf.d/exports.zsh`.
- If pinentry doesn't appear: run `gpgconf --kill gpg-agent` to force a restart.

---

## pass — Secrets Vault

[pass](https://www.passwordstore.org/) (password-store) is the local secrets
vault. It is in all three package lists and initialized by
`home/run_init-password-store.sh.tmpl` on `chezmoi apply` (a plain `run_`
script, not `run_once_` — on a fresh machine the first apply runs before the
GPG key exists, so it must be able to retry; every guard exits 0 fast).

### Key model: one GPG key per device, store encrypted to all of them

- Each machine generates its own GPG key (`gpg --full-gen-key`,
  ECC/Curve25519). **Private keys never leave the device they were created
  on** — only public keys move between machines.
- The key ID is what chezmoi prompts for as `gpgKey`; it doubles as the git
  `signingkey` (`dot_config/git/config.tmpl`) and the pass identity. Add each
  device's public key to GitHub (multiple signing keys per account are fine).
- The store's `.gpg-id` lists every device's key; pass encrypts each secret
  to all of them. **Enroll a new device**: generate its key → export the
  *public* key → import + trust it on an existing device →
  `pass init KEY_A KEY_B ...` (re-encrypts the whole store) → `pass git push`
  → new device clones/pulls and can decrypt with its own key.
- **Lost/compromised device**: re-run `pass init` with the remaining key IDs,
  rotate any secrets that device had accessed, delete its key from GitHub.

### Store location & sync

- The store stays at the default `~/.password-store`. Deliberately NOT
  relocated via `PASSWORD_STORE_DIR`: that var would only be set in zsh
  startup files, and AI agents often run plain `bash`, which would silently
  look at the default path anyway. This is a documented exception to the
  "use XDG variables" rule.
- The store is its own git repo, synced independently. Never nest it inside
  this dotfiles repo — its `.gpg` blobs would churn here, and the repos have
  different audiences.
- **No GitHub required — and none is used.** A remote is only needed for
  multi-device sync, and a self-hosted bare repo over SSH works fine:
  `ssh <box> git init --bare '~/password-store.git'` then
  `pass git remote add origin <box>:password-store.git`. Secret *contents*
  are GPG ciphertext, but entry *names* are plaintext file paths — metadata
  that should not sit on a third-party host.

### AI agent access

- Agents read secrets with `pass show <path>` — plain stdout, no daemon.
  gpg-agent caching (`default-cache-ttl 3600` in
  `private_dot_gnupg/private_gpg-agent.conf.tmpl`) makes this non-interactive
  after the first pinentry unlock of a session.
- Convention: secrets agents may read live under `ai/`
  (e.g. `pass show ai/github-token`); human-only secrets live elsewhere
  (e.g. `personal/`). Note: `dot_claude/settings.json` currently sets
  `defaultMode: bypassPermissions`, which makes allowlist scoping moot — if
  you ever tighten the mode, allowlist only `Bash(pass show ai/*)`.
- chezmoi templates can also pull secrets at apply time via the built-in
  `pass` template function (`{{ pass "ai/example" }}` inside a `.tmpl` file)
  — useful for rendering `private_` config files that need an embedded token.

### Shell startup pattern: one entry, one gpg spawn

Env vars exported in every shell live in a single multiline entry,
`env/shell`, containing `export FOO=...` lines; `secrets.zsh` evals it with
one direct `gpg -dq` call (~130ms). Do NOT add one `pass show` per variable —
each spawn costs ~190ms at every shell startup (measured: 3 vars = ~570ms via
`pass show` vs ~150ms via the single-entry eval). Rotate/edit with
`pass edit env/shell`. On-demand secrets that don't need to be in every
shell's env get individual `ai/`/`personal/` entries instead — see
`secrets.zsh.example`.

---

## install.sh

`install.sh` is the single bootstrap entry point for all three OSes. It is
**non-destructive** — it never deletes anything. Order of operations:

1. Detect OS / Linux distro family
2. Install platform packages (Brewfile / packages.arch.txt / packages.debian.txt).
   On Linux this also compiles `terminfo/ghostty.terminfo` into `~/.terminfo`
   so SSH'd-in sessions with `TERM=xterm-ghostty` resolve correctly.
3. Back up existing `~/.zshrc`, `~/.zshenv`, `~/.zlogin`, `~/.bash_profile` to
   `<file>.pre-chezmoi.bak` (`cp -p`, never `mv` or `rm`).
   **Skipped on re-runs** when `~/.config/chezmoi/chezmoi.toml` already
   exists — backing up chezmoi-managed files would just stamp useless copies.
4. Migrate `~/.zsh_history` into `$XDG_STATE_HOME/zsh/history`. If the new
   file doesn't exist, copy. If it does, **prepend** the old entries (chrono-
   logically older) and concatenate. A sentinel file
   (`$XDG_STATE_HOME/zsh/.zsh_history-migrated`) marks the merge as done so
   re-runs don't double-append. zsh tolerates duplicate entries at read time
   (`HIST_IGNORE_ALL_DUPS`), so we don't try to dedupe in the merge — that
   would risk dropping commands and require parsing the extended-history
   format. The original `~/.zsh_history` is left in place.
5. Write a minimal `~/.config/chezmoi/chezmoi.toml` (just a `[data]` block).
   Three modes:
   - **Interactive** (tty stdin): bash `read` prompts for name/email/GPG.
   - **Non-interactive** (env): `CHEZMOI_NAME`, `CHEZMOI_EMAIL`,
     `CHEZMOI_GPG_KEY` (last one optional/blank).
   - **Non-interactive without env vars**: errors loudly. Previously this
     mode silently exited (closed stdin → `read` returns 1 → `set -e`),
     which is what made `ssh host 'bash install.sh'` skip everything.
6. Run `chezmoi init --apply --force --source=$SCRIPT_DIR`. `init` (not bare
   `apply`) is used so chezmoi renders `home/.chezmoi.toml.tmpl` and writes a
   *complete* chezmoi.toml — including `sourceDir` and the `[diff]`/`[edit]`
   /`[merge]` sections. `promptStringOnce` reads our pre-written `[data]`
   block, so it returns the existing values without prompting. `--force`
   makes apply non-interactive: chezmoi won't prompt before overwriting
   destination files that diverge from source (e.g. someone running
   `git config --global --add safe.directory /opt/foo` adds a `[safe]` block
   to `~/.config/git/config` outside chezmoi). install.sh is a bootstrap, so
   it enforces source state — push local edits back to source before re-running.
7. Fix `~/.gnupg` permissions
8. Offer to `chsh -s "$(command -v zsh)"` (interactive prompt; defaults to no).
   `chsh` itself prompts for the user's password — we can't bypass that
   (Debian's `/etc/pam.d/chsh` requires it), so this stays interactive. Skipped
   in non-tty runs (warning printed instead). For automation, run
   `sudo chsh -s "$(command -v zsh)" "$USER"` separately if you have NOPASSWD
   sudo or a cached sudo timestamp.

### Idempotency / re-runs

`install.sh` is safe to re-run. Each step short-circuits when its work is
already done: package managers report "already installed", `backup_existing_configs`
returns early once chezmoi.toml exists, `migrate_zsh_history` keys off a
sentinel file, `write_chezmoi_config` keeps an existing config, and
`apply_chezmoi` uses `--force` so a re-run can't get stuck on a TTY prompt.

### Common pitfalls (fixed; here as land-mine markers)

- **Bare `return` after `[[ ]] || ...`** — under `set -e`, `return` with no
  argument propagates the failed test's exit status (1), aborting the calling
  function and main. Always write `return 0` when the early-exit is the
  intended success path.
- **`read -r` against closed stdin** — returns 1, `set -e` aborts silently.
  Always guard with `[[ -t 0 ]]` or accept env vars instead.
- **`chezmoi init --apply` without `--force` in non-tty mode** — chezmoi
  prompts ("file has changed since chezmoi last wrote it?") and fails
  ("could not open a new TTY") if any destination diverges from source.

**Things install.sh deliberately does NOT do:**

- Remove version managers (nvm/pyenv/jenv/rvm), oh-my-zsh, p10k, or any
  other unrelated user tooling. The user can clean those up themselves once
  they've confirmed the new setup works.
- Extract secrets from an old `~/.zshrc`. Users copy `secrets.zsh.example`
  and `local.zsh.example` and fill in their own values.

If you find yourself wanting to add a removal step, push back — the rule is
"back up, don't delete."

---

## Git Commits

- Do not add `Co-Authored-By` trailers to commits

---

## What NOT to Do

- Do not add oh-my-zsh, Prezto, or any Zsh framework
- Do not commit to `~/.zshrc` directly — the source is `home/dot_config/zsh/dot_zshrc`
- Do not use `~/` hard-coded paths in config files — use XDG variables
- Do not add powerline or pure prompt — the prompt is Starship
- Do not add `tap "homebrew/bundle"` to the Brewfile — it's deprecated
- Do not rely on `promptStringOnce` working interactively inside bash scripts
