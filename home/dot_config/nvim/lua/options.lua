-- lua/options.lua — Neovim editor options

local opt = vim.opt

-- ── Appearance ────────────────────────────────────────────────────────────────
opt.number         = true
opt.relativenumber = true
opt.signcolumn     = "yes"
opt.cursorline     = true
opt.colorcolumn    = "100"
opt.termguicolors  = true
opt.showmode       = false  -- mode shown by statusline instead
opt.laststatus     = 3      -- global statusline

-- ── Indentation ───────────────────────────────────────────────────────────────
opt.tabstop     = 2
opt.shiftwidth  = 2
opt.expandtab   = true
opt.smartindent = true
opt.breakindent = true

-- ── Search ────────────────────────────────────────────────────────────────────
opt.ignorecase = true
opt.smartcase  = true
opt.hlsearch   = true
opt.incsearch  = true

-- ── Files / undo ──────────────────────────────────────────────────────────────
opt.undofile   = true
opt.undodir    = vim.fn.expand("~/.cache/nvim/undo")
opt.swapfile   = false
opt.backup     = false
opt.updatetime = 300

-- ── Behaviour ─────────────────────────────────────────────────────────────────
opt.wrap         = false
opt.scrolloff    = 8
opt.sidescrolloff = 8
opt.splitright   = true
opt.splitbelow   = true
opt.mouse        = "a"
opt.clipboard    = "unnamedplus"
opt.completeopt  = { "menu", "menuone", "noselect" }
opt.pumheight    = 10
opt.conceallevel = 0

-- ── Performance ───────────────────────────────────────────────────────────────
opt.lazyredraw  = false  -- false required for nice animations
opt.timeoutlen  = 300

-- Ensure cache dirs exist
local cache_dirs = {
  vim.fn.expand("~/.cache/nvim/undo"),
  vim.fn.expand("~/.cache/nvim/swap"),
}
for _, dir in ipairs(cache_dirs) do
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, "p")
  end
end
