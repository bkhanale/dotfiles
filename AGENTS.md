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
| Ghostty / Zellij | Brewfile (Cask + brew) | `pacman -S ghostty zellij` | not packaged — install upstream binaries manually |
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

## install.sh

`install.sh` is the single bootstrap entry point for all three OSes. It is
**non-destructive** — it never deletes anything. Order of operations:

1. Detect OS / Linux distro family
2. Install platform packages (Brewfile / packages.arch.txt / packages.debian.txt).
   On Linux this also compiles `terminfo/ghostty.terminfo` into `~/.terminfo`
   so SSH'd-in sessions with `TERM=xterm-ghostty` resolve correctly.
3. Back up existing `~/.zshrc`, `~/.zshenv`, `~/.zlogin`, `~/.bash_profile` to
   `<file>.pre-chezmoi.bak` (`cp -p`, never `mv` or `rm`)
4. Migrate `~/.zsh_history` into `$XDG_STATE_HOME/zsh/history`. If the new
   file doesn't exist, copy. If it does, **prepend** the old entries (chrono-
   logically older) and concatenate. A sentinel file
   (`$XDG_STATE_HOME/zsh/.zsh_history-migrated`) marks the merge as done so
   re-runs don't double-append. zsh tolerates duplicate entries at read time
   (`HIST_IGNORE_ALL_DUPS`), so we don't try to dedupe in the merge — that
   would risk dropping commands and require parsing the extended-history
   format. The original `~/.zsh_history` is left in place.
5. Write a minimal `~/.config/chezmoi/chezmoi.toml` (just a `[data]` block)
   via bash `read` prompts
6. Run `chezmoi init --apply --source=$SCRIPT_DIR`. `init` (not bare `apply`)
   is used so chezmoi renders `home/.chezmoi.toml.tmpl` and writes a
   *complete* chezmoi.toml — including `sourceDir` and the `[diff]`/`[edit]`
   /`[merge]` sections. `promptStringOnce` reads our pre-written `[data]`
   block, so it returns the existing values without prompting.
7. Fix `~/.gnupg` permissions
8. Offer to `chsh -s "$(command -v zsh)"` (interactive prompt; defaults to no).
   `chsh` itself prompts for the user's password — we can't bypass that
   (Debian's `/etc/pam.d/chsh` requires it), so this stays interactive.

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
