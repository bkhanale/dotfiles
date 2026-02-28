-- lua/keymaps.lua — key mappings

local map = vim.keymap.set
local opts = { noremap = true, silent = true }

-- ── Window navigation ─────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", opts)
map("n", "<C-j>", "<C-w>j", opts)
map("n", "<C-k>", "<C-w>k", opts)
map("n", "<C-l>", "<C-w>l", opts)

-- ── Window resizing ───────────────────────────────────────────────────────────
map("n", "<C-Up>",    "<cmd>resize +2<CR>",          opts)
map("n", "<C-Down>",  "<cmd>resize -2<CR>",          opts)
map("n", "<C-Left>",  "<cmd>vertical resize -2<CR>", opts)
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", opts)

-- ── Buffer navigation ─────────────────────────────────────────────────────────
map("n", "<S-h>", "<cmd>bprevious<CR>", opts)
map("n", "<S-l>", "<cmd>bnext<CR>",     opts)
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })

-- ── Move lines ────────────────────────────────────────────────────────────────
map("v", "J", ":m '>+1<CR>gv=gv", opts)
map("v", "K", ":m '<-2<CR>gv=gv", opts)

-- ── Stay in indent mode ────────────────────────────────────────────────────────
map("v", "<", "<gv", opts)
map("v", ">", ">gv", opts)

-- ── Keep cursor centred on jumps ──────────────────────────────────────────────
map("n", "<C-d>", "<C-d>zz", opts)
map("n", "<C-u>", "<C-u>zz", opts)
map("n", "n",     "nzzzv",   opts)
map("n", "N",     "Nzzzv",   opts)

-- ── Clear search highlight ────────────────────────────────────────────────────
map("n", "<leader>nh", "<cmd>nohlsearch<CR>", { desc = "Clear highlights" })

-- ── Save and quit ─────────────────────────────────────────────────────────────
map("n", "<leader>w", "<cmd>write<CR>",  { desc = "Save" })
map("n", "<leader>q", "<cmd>quit<CR>",   { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa!<CR>",    { desc = "Quit all" })

-- ── Telescope ─────────────────────────────────────────────────────────────────
map("n", "<leader>ff", "<cmd>Telescope find_files<CR>",  { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",   { desc = "Live grep" })
map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",     { desc = "Buffers" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>",   { desc = "Help tags" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>",    { desc = "Recent files" })
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "Document symbols" })

-- ── LSP (set in LspAttach autocmd in plugins.lua) ────────────────────────────
-- gd, gr, K, etc. are mapped on buffer attach

-- ── Diagnostics ───────────────────────────────────────────────────────────────
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Diagnostic float" })

-- ── File tree (nvim-tree) ─────────────────────────────────────────────────────
map("n", "<leader>e",  "<cmd>NvimTreeToggle<CR>",   { desc = "Toggle file tree" })
map("n", "<leader>ef", "<cmd>NvimTreeFocus<CR>",    { desc = "Focus file tree" })
map("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>",  { desc = "Refresh file tree" })
