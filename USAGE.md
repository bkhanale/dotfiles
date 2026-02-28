# USAGE.md — Tool Usage Reference

Quick reference for getting the most out of the tools configured in this dotfiles setup.

---

## Table of Contents

1. [Alacritty — Terminal](#alacritty--terminal)
2. [Zellij — Terminal Multiplexer](#zellij--terminal-multiplexer)
3. [Neovim — Editor](#neovim--editor)
   - [Leader key & general](#leader-key--general)
   - [Windows & buffers](#windows--buffers)
   - [Telescope — fuzzy finder](#telescope--fuzzy-finder)
   - [LSP](#lsp)
   - [Completion (nvim-cmp)](#completion-nvim-cmp)
   - [Diagnostics](#diagnostics)
   - [Git (gitsigns)](#git-gitsigns)
   - [Comments](#comments)
   - [Plugin management (lazy.nvim)](#plugin-management-lazynvim)
4. [Shell — Zsh](#shell--zsh)
   - [Navigation aliases](#navigation-aliases)
   - [Modern CLI replacements](#modern-cli-replacements)
   - [Git aliases](#git-aliases)
   - [Custom functions](#custom-functions)
5. [fzf — Fuzzy Finder](#fzf--fuzzy-finder)
6. [zoxide — Smart cd](#zoxide--smart-cd)
7. [mise — Version Manager](#mise--version-manager)
8. [direnv — Per-directory Env](#direnv--per-directory-env)

---

## Alacritty — Terminal

Alacritty is a GPU-accelerated terminal. It has no built-in tab/pane support — use Zellij for that.

### Key bindings

| Binding | Action |
|---|---|
| `Cmd+Return` | Spawn a new Alacritty window |
| `Cmd+N` | Spawn a new Alacritty window |
| `Cmd+Q` | Quit Alacritty |
| `Cmd+C` | Copy selection |
| `Cmd+V` | Paste clipboard |
| `Cmd+=` | Increase font size |
| `Cmd+-` | Decrease font size |
| `Cmd+0` | Reset font size |

Alacritty passes all other key events through to the running process (i.e. Zellij or the shell). Font is **FiraCode Nerd Font Mono**, theme is **Tokyo Night Night**. Scrollback scrolls to 10,000 lines.

---

## Zellij — Terminal Multiplexer

Zellij is the multiplexer that runs inside Alacritty. It handles panes, tabs, and sessions. A status bar is shown at the bottom indicating your current mode and available bindings.

### Mode overview

Zellij is modal. Press the key combo to enter a mode, act, then press `Esc` or `Enter` to return to Normal.

| Key | Mode entered |
|---|---|
| `Ctrl-p` | **Pane** mode |
| `Ctrl-t` | **Tab** mode |
| `Ctrl-n` | **Resize** mode |
| `Ctrl-s` | **Scroll** mode |
| `Ctrl-o` | **Session** mode |
| `Ctrl-g` | **Locked** mode (all keys pass to terminal) |

### Alt shortcuts (work in Normal mode — no mode switch needed)

| Key | Action |
|---|---|
| `Alt-n` | New pane |
| `Alt-h / Alt-←` | Move focus to left pane |
| `Alt-l / Alt-→` | Move focus to right pane |
| `Alt-j / Alt-↓` | Move focus to pane below |
| `Alt-k / Alt-↑` | Move focus to pane above |
| `Alt-f` | Toggle floating pane |
| `Alt-i` | Toggle pane embed/float |
| `Alt-[1-9]` | Switch to tab by number |
| `Alt-+` / `Alt--` | Increase / decrease pane size |

### Pane mode (`Ctrl-p`, then…)

| Key | Action |
|---|---|
| `n` | New pane |
| `d` | New pane (split down) |
| `r` | New pane (split right) |
| `x` | Close pane |
| `f` | Toggle fullscreen |
| `z` | Toggle pane zoom |
| `w` | Toggle floating panes |
| `e` | Toggle embed pane |
| `h/j/k/l` or arrows | Move focus |
| `p` | Focus previous pane |

### Tab mode (`Ctrl-t`, then…)

| Key | Action |
|---|---|
| `n` | New tab |
| `x` | Close tab |
| `r` | Rename tab |
| `h` / `←` | Previous tab |
| `l` / `→` | Next tab |
| `[1-9]` | Go to tab N |
| `s` | Toggle active sync (broadcast to all panes) |

### Scroll mode (`Ctrl-s`, then…)

| Key | Action |
|---|---|
| `j` / `↓` | Scroll down |
| `k` / `↑` | Scroll up |
| `d` | Scroll half page down |
| `u` | Scroll half page up |
| `e` | Open scrollback in `nvim` |
| `/` | Search in scrollback |
| `n` / `N` | Next / previous search match |
| `Esc` / `q` | Exit scroll mode |

> **Tip:** `copy_on_select = true` is set — any text you select is automatically copied to the system clipboard.

### Session mode (`Ctrl-o`, then…)

| Key | Action |
|---|---|
| `w` | Open session manager (switch/kill sessions) |
| `d` | Detach from session |

Sessions are serialised to disk (`session_serialization = true`), so your layout is restored on reattach.

---

## Neovim — Editor

Configuration entry point: `~/.config/nvim/init.lua`. Plugins are managed by **lazy.nvim** and auto-bootstrapped on first launch.

### Leader key & general

The `<leader>` key is **`Space`**. Local leader is `\`.

Press `<Space>` and wait — **which-key** will pop up showing all available leader bindings.

| Binding | Action |
|---|---|
| `<leader>w` | Save file |
| `<leader>q` | Quit |
| `<leader>Q` | Force quit all |
| `<leader>nh` | Clear search highlights |

### Windows & buffers

| Binding | Action |
|---|---|
| `Ctrl-h/j/k/l` | Navigate between splits |
| `Ctrl-↑/↓` | Resize split height |
| `Ctrl-←/→` | Resize split width |
| `Shift-h` | Previous buffer |
| `Shift-l` | Next buffer |
| `<leader>bd` | Delete (close) current buffer |

In Visual mode:

| Binding | Action |
|---|---|
| `J` | Move selected lines down |
| `K` | Move selected lines up |
| `<` | Dedent (stay in visual mode) |
| `>` | Indent (stay in visual mode) |

Scrolling is centred — `Ctrl-d`, `Ctrl-u`, `n`, `N` all keep the cursor in the middle of the screen.

### Telescope — fuzzy finder

| Binding | Action |
|---|---|
| `<leader>ff` | Find files in project |
| `<leader>fg` | Live grep (ripgrep) across project |
| `<leader>fb` | Browse open buffers |
| `<leader>fr` | Recently opened files |
| `<leader>fh` | Search help tags |
| `<leader>fs` | LSP document symbols |

Inside a Telescope picker:

| Key | Action |
|---|---|
| `Ctrl-j` / `Ctrl-k` | Move up/down the results list |
| `Ctrl-n` / `Ctrl-p` | Next / previous history entry in prompt |
| `Ctrl-x` | Open in horizontal split |
| `Ctrl-v` | Open in vertical split |
| `Ctrl-t` | Open in new tab |
| `Ctrl-u` / `Ctrl-d` | Scroll preview up / down |
| `Esc` | Close picker |

Results are filtered by `node_modules`, `.git/`, and `.direnv/` automatically.

### LSP

LSP servers are installed/managed by **Mason** (`<:Mason>` to open the UI). Servers auto-install on first open: `lua_ls`, `bashls`, `pyright`, `ts_ls`, `jsonls`, `yamlls`, `dockerls`.

LSP keymaps activate automatically when a language server attaches to a buffer:

| Binding | Action |
|---|---|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | List all references |
| `gi` | Go to implementation |
| `K` | Show hover documentation |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code actions (fix, refactor, import, etc.) |
| `<leader>f` | Format file (async) |

Run `:Mason` to install/update individual servers. Run `:LspInfo` to check which servers are attached.

### Completion (nvim-cmp)

Completion triggers automatically. Sources: LSP → snippets (LuaSnip) → buffer words → file paths.

| Key | Action |
|---|---|
| `Ctrl-Space` | Force open completion menu |
| `Tab` | Select next item / expand/jump snippet |
| `Shift-Tab` | Select previous item / jump snippet backwards |
| `Enter` | Confirm selection |
| `Ctrl-e` | Abort / close completion menu |
| `Ctrl-b` / `Ctrl-f` | Scroll docs up / down |

### Diagnostics

| Binding | Action |
|---|---|
| `[d` | Jump to previous diagnostic |
| `]d` | Jump to next diagnostic |
| `<leader>d` | Open diagnostic in floating window |

### Git (gitsigns)

Gitsigns decorates the sign column with `▎` markers for added/changed/deleted lines.

| Binding | Action |
|---|---|
| `]c` | Next hunk |
| `[c` | Previous hunk |
| `:Gitsigns preview_hunk` | Preview diff inline |
| `:Gitsigns stage_hunk` | Stage hunk |
| `:Gitsigns reset_hunk` | Reset hunk |
| `:Gitsigns blame_line` | Show git blame for line |

### Comments

`Comment.nvim` uses **gcc** / **gc** motions:

| Key | Action |
|---|---|
| `gcc` | Toggle line comment |
| `gc{motion}` | Toggle comment over motion (e.g. `gcip` = paragraph) |
| `gc` (visual) | Toggle comment over selection |
| `gbc` | Toggle block comment on line |

### Plugin management (lazy.nvim)

| Command | Action |
|---|---|
| `:Lazy` | Open plugin manager UI |
| `:Lazy sync` | Install + update + clean in one step |
| `:Lazy update` | Update all plugins |
| `:Lazy clean` | Remove unused plugins |
| `:Lazy profile` | Show startup time breakdown |

---

## Shell — Zsh

### Navigation aliases

| Alias | Expands to |
|---|---|
| `..` | `cd ..` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |

### Modern CLI replacements

These shadow the standard tools when the modern versions are installed:

| Alias | Tool | Description |
|---|---|---|
| `ls` | `eza` | List with icons, dirs first |
| `ll` | `eza -la` | Long list with icons |
| `lt` | `eza --tree --level=2` | 2-level tree |
| `la` | `eza -a` | All files including hidden |
| `cat` | `bat --plain` | Syntax-highlighted pager |
| `grep` | `rg` | ripgrep (faster, respects `.gitignore`) |
| `find` | `fd` | fd (simpler syntax, faster) |

### Git aliases

| Alias | Command |
|---|---|
| `g` | `git` |
| `ga` / `gaa` | `git add` / `git add --all` |
| `gc` / `gcm` | `git commit` / `git commit -m` |
| `gca` | `git commit --amend` |
| `gco` / `gsw` | `git checkout` / `git switch` |
| `gb` / `gbd` | `git branch` / `git branch -d` |
| `gp` / `gpf` | `git push` / `git push --force-with-lease` |
| `gpl` | `git pull` |
| `gst` | `git status` |
| `gd` / `gds` | `git diff` / `git diff --staged` |
| `gl` / `gll` | `git log --oneline --graph` (last 20) / (all) |
| `grb` / `grbi` | `git rebase` / `git rebase -i` |
| `grs` / `grss` | `git restore` / `git restore --staged` |
| `gss` / `gsp` / `gsl` | `git stash` / `git stash pop` / `git stash list` |

### Custom functions

| Function | Usage | Description |
|---|---|---|
| `mkcd` | `mkcd my-dir` | Create dir and `cd` into it |
| `up` | `up 3` | Go up N directory levels (default 1) |
| `fcd` | `fcd` | Fuzzy-find a directory and `cd` into it |
| `fkill` | `fkill` | Pick and kill a process via fzf |
| `gflog` | `gflog` | Interactive fuzzy git log with diff preview |
| `extract` | `extract file.tar.gz` | Unpack any archive format |
| `port` | `port 3000` | Show what process is listening on a port |

### Kubernetes aliases (when `kubectl` / `kubectx` / `kubens` are installed)

| Alias | Command |
|---|---|
| `k` | `kubectl` |
| `kx` | `kubectx` (switch cluster context) |
| `kns` | `kubens` (switch namespace) |

### Docker aliases

| Alias | Command |
|---|---|
| `dps` | `docker ps` |
| `dc` | `docker compose` |

### Misc

| Alias | Action |
|---|---|
| `cls` | Clear screen |
| `reload` | Restart the shell (`exec zsh`) |
| `path` | Print `$PATH` one entry per line |
| `psg <term>` | `ps aux | grep <term>` |

---

## fzf — Fuzzy Finder

Shell key bindings (sourced from Homebrew):

| Binding | Action |
|---|---|
| `Ctrl-r` | Fuzzy search shell history |
| `Ctrl-t` | Fuzzy find a file and paste its path to the prompt |
| `Alt-c` | Fuzzy find a directory and `cd` into it |

`fzf` uses `fd` as the default command (respects `.gitignore`, shows hidden files). Default UI: 40% height, reverse layout, with a border.

---

## zoxide — Smart cd

zoxide learns your most-visited directories and lets you jump to them with partial names. It replaces the `cd` builtin.

| Command | Action |
|---|---|
| `cd foo` | Jump to the highest-ranked dir matching `foo` |
| `cd foo bar` | Match dirs containing both `foo` and `bar` |
| `cdi` | Interactive fuzzy jump using fzf (alias for `cd -i`) |
| `zoxide query -l` | List all tracked directories by rank |
| `zoxide remove <path>` | Remove a directory from the database |

---

## mise — Version Manager

`mise` replaces `nvm`, `pyenv`, `jenv`, and `rvm`. It is activated via `eval "$(mise activate zsh)"`.

### Common commands

| Command | Action |
|---|---|
| `mise list` | Show installed tool versions |
| `mise use node@22` | Set the Node.js version (writes `.mise.toml`) |
| `mise use --global python@3.13` | Set a global default |
| `mise install` | Install all versions in `mise.toml` / global config |
| `mise exec -- <cmd>` | Run a command in the mise-managed environment |
| `mise which node` | Show the path of the active `node` binary |
| `mise doctor` | Diagnose any mise problems |

### Global tool versions (from `~/.config/mise/config.toml`)

| Tool | Version |
|---|---|
| Node.js | 22.15.0 |
| Python | 3.13 |
| Java | temurin-21 |
| Ruby | 3.2.4 |

For per-project overrides, add a `.mise.toml` to the project root. Never modify the global config for project-specific versions.

---

## direnv — Per-directory Env

`direnv` automatically loads/unloads environment variables when you enter/leave a directory containing an `.envrc` file.

| Command | Action |
|---|---|
| `direnv allow` | Trust and load the `.envrc` in the current directory |
| `direnv deny` | Revoke trust for the current `.envrc` |
| `direnv reload` | Re-evaluate the current `.envrc` |
| `direnv edit .` | Edit the `.envrc` and allow it in one step |

Example `.envrc`:

```bash
export DATABASE_URL="postgres://localhost/myapp_dev"
export RAILS_ENV="development"
use mise  # activate mise-managed tools for this project
```
