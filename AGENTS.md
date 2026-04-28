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
When `chezmoi init` is invoked from inside a bash script (e.g. `migrate.sh`), the prompts often fail silently, leaving `~/.config/chezmoi/chezmoi.toml` empty. Then `chezmoi apply` fails with:

```
template: ...: map has no entry for key "name"
```

**Correct approach**: Write `~/.config/chezmoi/chezmoi.toml` directly in the script using bash `read` prompts, then call `chezmoi apply`:

```bash
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<EOF
[data]
  name    = "$_name"
  email   = "$_email"
  gpgKey  = "$_gpg"
EOF
chezmoi apply --source="$DOTFILES_DIR"
```

---

## Directory Layout

```
home/
├── dot_zshenv          # ZDOTDIR + XDG env vars — loaded for ALL zsh instances
└── dot_config/zsh/
    ├── dot_zshenv      # empty, bypasses default ~/.zshenv loading
    ├── dot_zshrc       # interactive shell bootstrap — thin; sources conf.d/*
    └── conf.d/         # modular files sourced alphabetically by dot_zshrc
    ├── aliases.zsh
    ├── completions.zsh
    ├── exports.zsh
    ├── functions.zsh
    ├── keybindings.zsh
    └── tools.zsh
```

- **Never put secrets in tracked files.** Secrets go in `~/.config/zsh/secrets.zsh` (gitignored).
- **Never hard-code paths** — use XDG variables (`$XDG_CONFIG_HOME`, `$XDG_DATA_HOME`, `$XDG_CACHE_HOME`).
- OS-specific logic belongs in `.tmpl` files using chezmoi template guards.

---

## Platform Differences

| Concern | macOS | Arch Linux |
|---|---|---|
| Package manager | Homebrew (`Brewfile`) | pacman / yay (`packages.arch.txt`) |
| GPG pinentry | `pinentry-mac` | `pinentry-curses` |
| Font path | managed by Homebrew Cask | system fonts dir |
| chezmoi install | `brew install chezmoi` | `yay -S chezmoi` |

---

## Adding a New Config File

1. Create the file at `home/dot_config/<tool>/<file>` (or `home/dot_config/<tool>/<file>.tmpl` if it needs templating).
2. If it references secrets, document the expected env var in `home/dot_config/zsh/secrets.zsh.example`.
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

## Secrets Convention

- Gitignored file: `~/.config/zsh/secrets.zsh`
- Example template committed: `home/dot_config/zsh/secrets.zsh.example`
- The file is sourced at the end of `dot_zshrc` if it exists
- chezmoi ignores it via `home/.chezmoiignore`

**Never** commit real tokens, passwords, or API keys. If you see a secret in a tracked file, remove it immediately and rotate the credential.

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

`migrate.sh` does this automatically.

### Signing failures

- If `git commit` fails with `Inappropriate ioctl for device`: ensure `GPG_TTY=$(tty)` is set. It is exported in `conf.d/exports.zsh`.
- If pinentry doesn't appear: run `gpgconf --kill gpg-agent` to force a restart.

---

## migrate.sh

`migrate.sh` is the clean-slate migration script for moving an existing machine to this dotfiles setup. It:

1. Installs Homebrew packages
2. Removes old version managers — including handling **root-owned files** in `~/.rvm` (passenger gem builds with sudo leave root-owned files; the script uses `sudo rm -rf` when detected)
3. Writes `~/.config/chezmoi/chezmoi.toml` via interactive bash prompts (not `promptStringOnce`)
4. Runs `chezmoi apply`
5. Fixes `~/.gnupg` permissions
6. Writes `~/.config/zsh/secrets.zsh` by extracting values from the old `~/.zshrc`
7. Removes old dotfiles (backs up `~/.zshrc` to `~/.zshrc.pre-migration.bak`)

Do not change the ordering of steps — the sequence is intentional.

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
