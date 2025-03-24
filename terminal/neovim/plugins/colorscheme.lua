return {
  -- Theme configuration
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },

  -- Add the themes that match your terminal themes
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      term_colors = true,
      transparent_background = false,
      styles = {
        comments = { "italic" },
        conditionals = { "italic" },
        loops = {},
        functions = {},
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        treesitter = true,
        which_key = true,
        mason = true,
        lsp_trouble = true,
      },
    },
  },

  -- Add other themes that match your terminal themes
  { "folke/tokyonight.nvim", priority = 1000 },
  { "dracula/vim", name = "dracula", priority = 1000 },
  { "nordtheme/vim", name = "nord", priority = 1000 },
  { "sainnhe/everforest", priority = 1000 },
  { "rebelot/kanagawa.nvim", priority = 1000 },
  { "rose-pine/neovim", name = "rose-pine", priority = 1000 },
}