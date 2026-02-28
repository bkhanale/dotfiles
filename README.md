# dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/). Supports **macOS** (Homebrew) and **Arch Linux** (pacman/yay).

## Stack

| Concern | Tool |
|---|---|
| Dotfile manager | chezmoi |
| Shell | Zsh (XDG-clean, no oh-my-zsh) |
| Prompt | Starship (Tokyo Night Night) |
| Terminal | Alacritty |
| Multiplexer | Zellij |
| Version managers | mise (replaces nvm, pyenv, jenv, rvm) |
| Editor | Neovim (lazy.nvim, minimal) |
| Colour theme | Tokyo Night Night |
| Font | FiraCode Nerd Font Mono |

---

## Quick Start

### Fresh macOS machine

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install chezmoi
chezmoi init --apply bkhanale/dotfiles
mise install
```

### Fresh Arch Linux machine

```sh
sudo pacman -Syu --noconfirm git base-devel
# install yay (AUR helper)
git clone https://aur.archlinux.org/yay.git /tmp/yay && cd /tmp/yay && makepkg -si --noconfirm
# install chezmoi
yay -S --noconfirm chezmoi
chezmoi init --apply bkhanale/dotfiles
mise install
```

### Already have chezmoi

```sh
chezmoi init --apply bkhanale/dotfiles
```

---

## Prerequisites

- A Nerd Font installed and selected in your terminal (FiraCode Nerd Font Mono recommended — included in Brewfile)
- A GPG key if you want signed commits (optional; leave blank when prompted)

---

## Repo Structure

```
dotfiles/
├── chezmoi.toml.tmpl        # chezmoi config — prompts for name/email/GPG key once
├── Brewfile                 # macOS package manifest (brew bundle)
├── install.sh               # one-command bootstrap
├── home/                    # maps to ~/ via chezmoi
│   ├── dot_config/
│   │   ├── zsh/
│   │   │   ├── dot_zshenv         # sets ZDOTDIR, XDG vars
│   │   │   ├── dot_zshrc          # thin bootstrap; sources conf.d/*
│   │   │   └── conf.d/            # modular config files sourced alphabetically
│   │   ├── starship.toml
│   │   ├── alacritty/
│   │   ├── zellij/
│   │   ├── nvim/
│   │   ├── git/
│   │   └── mise/
│   └── dot_gnupg/
└── AGENTS.md                # instructions for AI coding agents
```

---

## Secrets

Secrets live in `~/.config/zsh/secrets.zsh`, which is **gitignored**. Copy the example to get started:

```sh
cp ~/.config/zsh/secrets.zsh.example ~/.config/zsh/secrets.zsh
# then fill in your real values
$EDITOR ~/.config/zsh/secrets.zsh
```

Expected variables:

```sh
export CLAUDE_GH_MCP_TOKEN=""
export SENTRY_AUTH_TOKEN=""
export VAULT_ADDR=""
export VAULT_TOKEN=""
export REQUESTLY_LEGACY_PATH=""
```

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

1. Install Homebrew (macOS) or ensure `git` + `yay` (Arch).
2. Run the quick-start commands above.
3. Copy `~/.config/zsh/secrets.zsh.example` → `secrets.zsh` and fill in values.
4. Run `mise install` to pull runtimes.
5. Import your GPG key: `gpg --import private-key.asc`

---

## Post-Install Checklist

- [ ] `chezmoi diff` is clean (no pending changes)
- [ ] Alacritty opens, Zellij starts, Starship prompt renders
- [ ] `mise doctor` passes
- [ ] `gpg --list-secret-keys` shows your signing key
- [ ] `git commit` produces a signed commit
- [ ] `time zsh -i -c exit` < 200 ms
