-- Additional language support plugins beyond LazyVim defaults
return {
  -- Ruby support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        solargraph = {}, -- Ruby LSP
      },
    },
  },
  
  -- Go support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        gopls = {}, -- Go LSP
      },
    },
  },
  
  -- Python support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {}, -- Python LSP
      },
    },
  },
  
  -- GraphQL support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        graphql = {}, -- GraphQL LSP
      },
    },
  },
  
  -- YAML with schema support
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                ["https://json.schemastore.org/github-workflow.json"] = "/.github/workflows/*",
                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose*.yml",
                ["https://json.schemastore.org/openapi-3.0.json"] = "*api*.yml",
              },
            },
          },
        },
      },
    },
  },
  
  -- Add treesitter grammars for additional languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "ruby",
        "go",
        "python",
        "yaml",
        "json",
        "graphql",
        "dockerfile",
        "sql",
        "markdown",
        "markdown_inline"
      })
    end,
  },
  
  -- Add formatters for these languages
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters_by_ft = {
        ruby = { "rubocop" },
        go = { "gofmt", "goimports" },
        python = { "black", "isort" },
      },
    },
  },
  
  -- Add linters for these languages
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = {
      linters_by_ft = {
        ruby = { "rubocop" },
        go = { "golangci_lint" },
        python = { "flake8" },
      },
    },
  },
}