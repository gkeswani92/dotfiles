-- Coding-specific plugins and LSP configuration

return {
  -- Better code comments
  {
    "folke/todo-comments.nvim",
    opts = {
      signs = true,
      keywords = {
        FIX = { icon = " ", color = "error", alt = { "FIXME", "BUG", "FIXIT", "ISSUE" } },
        TODO = { icon = " ", color = "info" },
        HACK = { icon = " ", color = "warning" },
        WARN = { icon = " ", color = "warning", alt = { "WARNING", "XXX" } },
        PERF = { icon = " ", alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
        NOTE = { icon = " ", color = "hint", alt = { "INFO" } },
      },
    },
  },

  -- Better completion menu
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, opts)
      local cmp = require("cmp")
      opts.mapping = cmp.mapping.preset.insert({
        ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
      })
    end,
  },

  -- LSP configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = true,
      },
      servers = {
        -- TypeScript/JavaScript - disabled (requires Node 22, you have 20)
        -- Re-enable after: nvm install 22 && nvm use 22
        ts_ls = { enabled = false },
        -- JSON
        jsonls = {},
        -- Lua
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              completion = { callSnippet = "Replace" },
            },
          },
        },
        -- Shopify Ruby LSP (manages its own bundle in .ruby-lsp/)
        ruby_lsp = {
          cmd = { "ruby-lsp" },
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern("Gemfile", ".git")(fname)
          end,
          init_options = {
            formatter = "rubocop",
            linters = { "rubocop" },
          },
        },
        rubocop = { enabled = false },
        solargraph = { enabled = false },
        sorbet = { enabled = false },
        -- Disable these (ruby_lsp + rubocop is enough)
        solargraph = { enabled = false },
        sorbet = { enabled = false },
        -- Add more LSPs as needed:
        -- gopls = {},
        -- pyright = {},
        -- rust_analyzer = {},
      },
    },
  },

  -- Better LSP UI
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    opts = {
      lightbulb = { enable = false },
      symbol_in_winbar = { enable = false },
    },
    keys = {
      { "gd", "<cmd>Lspsaga goto_definition<cr>", desc = "Go to Definition" },
      { "K", "<cmd>Lspsaga hover_doc<cr>", desc = "Hover Doc" },
      { "<leader>ca", "<cmd>Lspsaga code_action<cr>", desc = "Code Action" },
      { "<leader>rn", "<cmd>Lspsaga rename<cr>", desc = "Rename" },
      { "gr", "<cmd>Lspsaga finder<cr>", desc = "Find References" },
      { "[d", "<cmd>Lspsaga diagnostic_jump_prev<cr>", desc = "Prev Diagnostic" },
      { "]d", "<cmd>Lspsaga diagnostic_jump_next<cr>", desc = "Next Diagnostic" },
    },
  },

  -- Format on save
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        markdown = { "prettier" },
        -- ruby = { "rubocop" },
        -- python = { "black" },
        -- go = { "gofmt" },
      },
    },
  },
}
