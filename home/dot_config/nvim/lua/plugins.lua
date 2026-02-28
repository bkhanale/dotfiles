-- lua/plugins.lua — lazy.nvim plugin manager bootstrap + plugins

-- ── Bootstrap lazy.nvim ───────────────────────────────────────────────────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ── Plugins ───────────────────────────────────────────────────────────────────
require("lazy").setup({
  -- ── Colour scheme ────────────────────────────────────────────────────────
  {
    "catppuccin/nvim",
    name     = "catppuccin",
    priority = 1000,
    config   = function()
      require("catppuccin").setup({
        flavour          = "mocha",
        transparent_background = false,
        integrations     = {
          telescope  = true,
          treesitter = true,
          cmp        = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- ── Syntax highlighting ──────────────────────────────────────────────────
  {
    "nvim-treesitter/nvim-treesitter",
    build  = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "bash", "css", "dockerfile", "go", "html", "java",
          "javascript", "json", "lua", "markdown", "python",
          "ruby", "rust", "toml", "typescript", "yaml",
        },
        auto_install = true,
      })
    end,
  },

  -- ── Fuzzy finder ─────────────────────────────────────────────────────────
  {
    "nvim-telescope/telescope.nvim",
    branch       = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
      local telescope = require("telescope")
      telescope.setup({
        defaults = {
          file_ignore_patterns = { "node_modules", ".git/", ".direnv/" },
          layout_config        = { prompt_position = "top" },
          sorting_strategy     = "ascending",
        },
      })
      telescope.load_extension("fzf")
    end,
  },

  -- ── LSP ───────────────────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      -- Mason (LSP installer)
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", "bashls", "pyright", "ts_ls",
          "jsonls", "yamlls", "dockerls",
        },
        automatic_installation = true,
      })

      -- Capabilities with nvim-cmp completion
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- LSP on-attach keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local buf = ev.buf
          local map = function(m, lhs, rhs, desc)
            vim.keymap.set(m, lhs, rhs, { buffer = buf, desc = desc })
          end
          map("n", "gd",        vim.lsp.buf.definition,      "Go to definition")
          map("n", "gD",        vim.lsp.buf.declaration,     "Go to declaration")
          map("n", "gr",        vim.lsp.buf.references,      "References")
          map("n", "gi",        vim.lsp.buf.implementation,  "Implementation")
          map("n", "K",         vim.lsp.buf.hover,           "Hover docs")
          map("n", "<leader>rn", vim.lsp.buf.rename,         "Rename")
          map("n", "<leader>ca", vim.lsp.buf.code_action,    "Code action")
          map("n", "<leader>f",  function()
            vim.lsp.buf.format({ async = true })
          end, "Format")
        end,
      })

      -- Configure each server via vim.lsp.config (nvim 0.11+)
      vim.lsp.config("*", {
        capabilities = capabilities,
      })

      vim.lsp.config("lua_ls", {
        settings = { Lua = { diagnostics = { globals = { "vim" } } } },
      })

      vim.lsp.enable({
        "lua_ls",
        "bashls",
        "pyright",
        "ts_ls",
        "jsonls",
        "yamlls",
        "dockerls",
      })

      -- nvim-cmp completion
      local cmp    = require("cmp")
      local luasnip = require("luasnip")
      cmp.setup({
        snippet    = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping    = cmp.mapping.preset.insert({
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = true }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources    = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip"  },
          { name = "buffer"   },
          { name = "path"     },
        }),
      })
    end,
  },

  -- ── Git signs ─────────────────────────────────────────────────────────────
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "▎" },
          change       = { text = "▎" },
          delete       = { text = "" },
          topdelete    = { text = "" },
          changedelete = { text = "▎" },
          untracked    = { text = "▎" },
        },
      })
    end,
  },

  -- ── Status line ───────────────────────────────────────────────────────────
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme            = "catppuccin",
          section_separators   = { left = "", right = "" },
          component_separators = { left = "", right = "" },
          globalstatus     = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- ── Comment toggling ──────────────────────────────────────────────────────
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- ── Autopairs ─────────────────────────────────────────────────────────────
  {
    "windwp/nvim-autopairs",
    event  = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({ check_ts = true })
    end,
  },

  -- ── Which-key ─────────────────────────────────────────────────────────────
  {
    "folke/which-key.nvim",
    event  = "VeryLazy",
    config = function()
      require("which-key").setup()
    end,
  },

}, {
  -- lazy.nvim options
  ui = { border = "rounded" },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "matchit", "matchparen", "netrwPlugin",
        "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})
