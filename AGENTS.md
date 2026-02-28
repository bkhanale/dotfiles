# AGENTS.md — Instructions for AI Coding Agents

This file documents conventions for AI agents (Copilot, Claude, etc.) working in this dotfiles repo.

---

## Repo Overview

This is a **chezmoi**-managed dotfiles repo. Source files live in `home/` and map to the home directory on apply. chezmoi handles templating, encryption, and cross-platform differences.

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

User data (from `chezmoi.toml.tmpl` prompts) is available as:
- `.name`
- `.email`
- `.gpgKey`

Built-in chezmoi data:
- `.chezmoi.os` — `"darwin"` or `"linux"`
- `.chezmoi.arch` — `"amd64"`, `"arm64"`, etc.
- `.chezmoi.hostname`
- `.chezmoi.homeDir`

---

## Directory Layout

```
home/dot_config/zsh/
├── dot_zshenv          # ZDOTDIR + XDG env vars — loaded for ALL zsh instances
├── dot_zshrc           # interactive shell bootstrap — thin; sources conf.d/*
└── conf.d/             # modular files sourced alphabetically by dot_zshrc
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
- chezmoi ignores it via `.chezmoiignore`

**Never** commit real tokens, passwords, or API keys. If you see a secret in a tracked file, remove it immediately and rotate the credential.

---

## Neovim

Config lives in `home/dot_config/nvim/`. Entry point is `init.lua`. Plugins are managed by `lazy.nvim` (auto-bootstrapped in `lua/plugins.lua`). Do not add plugin manager install scripts outside of `plugins.lua`.

---

## mise (Version Manager)

Global tool config: `home/dot_config/mise/config.toml`.
`prefer_precompiled = true` is set globally — do not override this per-tool unless there is a compelling reason (and document it).
Do not add version manager init snippets (`nvm`, `pyenv`, `jenv`, `rvm`) anywhere — mise replaces all of them.

---

## What NOT to Do

- Do not add oh-my-zsh, Prezto, or any Zsh framework
- Do not add nvm, pyenv, jenv, or rvm — use mise
- Do not commit to `~/.zshrc` directly — the source is `home/dot_config/zsh/dot_zshrc`
- Do not use `~/` hard-coded paths in config files — use XDG variables
- Do not add powerline or pure prompt — the prompt is Starship
