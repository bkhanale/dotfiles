# dotfiles

Cross-platform dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports **macOS** (Homebrew), **Arch Linux** (pacman/yay), and **Debian / Ubuntu** (apt).

## Stack

| Concern | Tool |
|---|---|
| Dotfile manager | chezmoi |
| Shell | Zsh (XDG-clean, no oh-my-zsh) |
| Prompt | Starship (Tokyo Night Night) |
| Terminal | Ghostty |
| Multiplexer | Zellij |
| Editor | Neovim (lazy.nvim, minimal) |
| AI coding agents | Claude Code + OpenCode + Codex (configs tracked, CLIs self-installed) |
| Colour theme | Tokyo Night Night |
| Font | FiraCode Nerd Font Mono |

---

## Quick Start

Replace `your-github-user` with the owner of your fork.

### Fresh macOS machine

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
chezmoi init --apply your-github-user/dotfiles
```

### Fresh Arch Linux machine

```sh
sudo pacman -Syu --noconfirm git base-devel
# install yay (AUR helper)
git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm
# install chezmoi
yay -S --noconfirm chezmoi
chezmoi init --apply your-github-user/dotfiles
```

### Fresh Debian / Ubuntu machine

```sh
sudo apt-get update && sudo apt-get install -y curl git
# install chezmoi into ~/.local/bin
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"
chezmoi init --apply your-github-user/dotfiles
```

Or, the all-in-one bootstrap (clones the repo, installs apt packages, starship, Nerd Fonts, and applies dotfiles):

```sh
git clone https://github.com/your-github-user/dotfiles "$HOME/.local/share/dotfiles"
bash "$HOME/.local/share/dotfiles/install.sh"
```

For headless / SSH bootstrap (no tty), pre-seed the chezmoi data via env vars:

```sh
ssh host 'git clone https://github.com/your-github-user/dotfiles "$HOME/.local/share/dotfiles" && \
  CHEZMOI_NAME="Your Name" \
  CHEZMOI_EMAIL="you@example.com" \
  CHEZMOI_GPG_KEY="" \
  bash "$HOME/.local/share/dotfiles/install.sh"'
```

(`chsh` still needs a password and is skipped in non-tty mode — run
`sudo chsh -s "$(command -v zsh)" "$USER"` afterwards.)

> Ghostty and Zellij are not packaged for Debian — install them manually from
> [ghostty.org](https://ghostty.org/docs/install/binary) and
> [zellij.dev](https://zellij.dev/documentation/installation) if you need them.

### Already have chezmoi

```sh
chezmoi init --apply your-github-user/dotfiles
```

### Onto a machine with existing dotfiles

`install.sh` is non-destructive. Running it on a machine with an existing
`~/.zshrc`, `~/.zshenv`, etc. will:

- back each one up to `<file>.pre-chezmoi.bak` before chezmoi overwrites it
- copy `~/.zsh_history` into `$XDG_STATE_HOME/zsh/history` (the original is
  left in place — delete it whenever you're confident)
- leave version managers (nvm, pyenv, jenv, rvm), oh-my-zsh, and any other
  unrelated tooling completely alone — clean those up yourself when ready

```sh
git clone https://github.com/your-github-user/dotfiles "$HOME/.local/share/dotfiles"
bash "$HOME/.local/share/dotfiles/install.sh"
```

---

## Prerequisites

- A Nerd Font installed and selected in your terminal (FiraCode Nerd Font Mono recommended — installed by `install.sh` on every supported OS)
- A GPG key if you want signed commits (optional; leave blank when prompted)

---

## Repo Structure

```
dotfiles/
├── Brewfile                 # macOS package manifest (brew bundle)
├── packages.arch.txt        # Arch Linux package list (yay)
├── packages.debian.txt      # Debian / Ubuntu package list (apt)
├── terminfo/ghostty.terminfo # xterm-ghostty terminfo source — compiled by install.sh
├── install.sh               # one-command bootstrap (macOS / Arch / Debian)
├── home/                    # maps to ~/ via chezmoi
│   ├── .chezmoi.toml.tmpl   # chezmoi config — prompts for name/email/GPG key once
│   ├── dot_zshenv           # sets ZDOTDIR, XDG vars
│   ├── dot_config/
│   │   ├── zsh/
│   │   │   ├── dot_zshenv         # placeholder; zsh reads ~/.zshenv, not $ZDOTDIR/.zshenv
│   │   │   ├── dot_zshrc          # thin bootstrap; sources conf.d/* + secrets.zsh + local.zsh
│   │   │   ├── secrets.zsh.example
│   │   │   ├── local.zsh.example
│   │   │   └── conf.d/            # modular config files sourced alphabetically
│   │   ├── starship.toml
│   │   ├── ghostty/
│   │   ├── zellij/
│   │   ├── nvim/
│   │   ├── git/
│   │   ├── opencode/        # OpenCode config (opencode.json, tui.json)
│   │   └── ccstatusline/    # Claude Code status-line config
│   ├── dot_claude/          # Claude Code base settings and keybindings
│   ├── dot_codex/           # Codex config + plan/review profiles → ~/.codex/
│   └── dot_gnupg/
├── AGENTS.md                # shared project instructions (Codex reads directly)
└── CLAUDE.md                # thin @AGENTS.md import for Claude Code
```

---

## Agentic Dev (Claude Code + OpenCode + Codex)

All three CLIs receive the same repo-root guidance: Codex reads `AGENTS.md`,
Claude Code reads the thin `CLAUDE.md` import, and OpenCode declares both in
its instructions list.

| Tool | Source | Target |
|---|---|---|
| Claude Code | `home/dot_claude/settings.json` | `~/.claude/settings.json` |
| Claude keybindings | `home/dot_claude/keybindings.json` | `~/.claude/keybindings.json` |
| Claude statusline | `home/dot_config/ccstatusline/settings.json` | `~/.config/ccstatusline/settings.json` |
| OpenCode (config) | `home/dot_config/opencode/opencode.json` | `~/.config/opencode/opencode.json` |
| OpenCode (TUI) | `home/dot_config/opencode/tui.json` | `~/.config/opencode/tui.json` |
| Codex | `home/dot_codex/private_config.toml` | `~/.codex/config.toml` |
| Codex profiles | `home/dot_codex/private_{plan,review}.config.toml` | `~/.codex/{plan,review}.config.toml` |

### What this repo does NOT manage

- The `claude`, `opencode`, and `codex` binaries themselves — all three ship
  installers with built-in auto-update. PATH for Claude Code and OpenCode is set in
  `dot_zshenv` / `conf.d/exports.zsh`.
- Session state, credentials, plugin caches, history, and project/session data
  under `~/.claude/` and `~/.codex/` — runtime data, never committed.
- User- or service-specific Claude hooks, skills, plugins, and marketplaces.
- MCP server definitions for Codex or OpenCode. Configure integrations locally
  on each machine instead of committing endpoints or credentials.
- Per-project `CLAUDE.md` / `AGENTS.md` — those live in each project repo.

To install the CLIs on a fresh machine:

```sh
# Claude Code (macOS / Linux)
curl -fsSL https://claude.ai/install.sh | bash

# OpenCode (macOS / Linux)
curl -fsSL https://opencode.ai/install | bash

# Codex (macOS / Linux)
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

---

## Per-Machine Overrides

Two files live at `~/.config/zsh/` for things that vary between machines.
Both are **gitignored** AND listed in `home/.chezmoiignore`, so `chezmoi apply`
will never overwrite them — edit them freely on each machine.

| File | For |
|---|---|
| `secrets.zsh` | Tokens, API keys, passwords (e.g. `GITHUB_TOKEN`, `OPENAI_API_KEY`) |
| `local.zsh`   | Non-secret per-machine config (PATH additions, work-only aliases, env overrides) |

Both are sourced from `dot_zshrc` after `conf.d/*`, so anything you set wins
over the tracked defaults. Get started by copying the examples:

```sh
cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
cp ~/.config/zsh/local.zsh.example   ~/.config/zsh/local.zsh
chmod 600 ~/.config/zsh/secrets.zsh
$EDITOR ~/.config/zsh/secrets.zsh ~/.config/zsh/local.zsh
```

The example files are intentionally generic — there is no canonical list of
expected variables. Add whatever your workflow needs.

---

## Updating Dotfiles

```sh
# on source machine — edit files, then push
chezmoi cd
# make changes…
git add -A && git commit -m "feat: ..." && git push

# on any machine — pull and apply
chezmoi update
```

Or edit-in-place and let chezmoi sync back to the source:

```sh
chezmoi edit ~/.config/zsh/conf.d/aliases.zsh
chezmoi apply
```

---

## Adding a New Machine

1. Install the platform package manager — Homebrew (macOS), `git` + `yay` (Arch), or `apt` (Debian / Ubuntu) — then run the quick-start commands above (or `bash install.sh` from a clone).
2. Copy the per-machine override examples (`secrets.zsh.example` → `secrets.zsh`, `local.zsh.example` → `local.zsh`) and fill in whatever you need.
3. Import your GPG key: `gpg --import private-key.asc`

---

## Post-Install Checklist

- [ ] `chezmoi diff` is clean (no pending changes)
- [ ] Ghostty opens, Zellij starts, Starship prompt renders
- [ ] `gpg --list-secret-keys` shows your signing key
- [ ] `git commit` produces a signed commit
- [ ] `time zsh -i -c exit` < 200 ms

---

## Troubleshooting

### GPG: `Attempt to write a readonly SQL database`

chezmoi apply can set wrong permissions on `~/.gnupg/`. Fix:

```sh
chmod 700 ~/.gnupg
find ~/.gnupg -type d -exec chmod 700 {} \;
find ~/.gnupg -type f -exec chmod 600 {} \;
gpgconf --kill all
```

### GPG: `Inappropriate ioctl for device` during git commit

Ensure `GPG_TTY=$(tty)` is exported. It is set in `conf.d/exports.zsh` — open a fresh shell.

### chezmoi: `map has no entry for key "name"`

The data file is missing. Run:

```sh
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml <<'EOF'
[data]
  name    = "Your Name"
  email   = "you@example.com"
  gpgKey  = "YOUR_KEY_ID"
EOF
chezmoi apply
```
