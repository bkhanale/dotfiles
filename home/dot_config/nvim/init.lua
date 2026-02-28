-- nvim/init.lua — Neovim entry point

-- Disable netrw early (required for nvim-tree / neo-tree)
vim.g.loaded_netrw       = 1
vim.g.loaded_netrwPlugin = 1

-- Leader key must be set before loading plugins
vim.g.mapleader      = " "
vim.g.maplocalleader = "\\"

-- Load modules
require("options")
require("keymaps")
require("plugins")
