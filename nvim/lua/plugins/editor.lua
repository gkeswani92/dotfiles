-- Editor enhancements and customizations

return {
  -- Better surround (cs"' to change " to ')
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },

  -- Improved f/t motions
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        search = { enabled = false }, -- Don't hijack regular search
        char = { enabled = true }, -- Enable f/t enhancements
      },
    },
  },

  -- Better diagnostics list
  {
    "folke/trouble.nvim",
    opts = {
      focus = true,
    },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer Diagnostics (Trouble)" },
    },
  },

  -- Git signs in gutter
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "^" },
        changedelete = { text = "~" },
      },
      current_line_blame = true, -- Show blame on current line (like GitLens)
      current_line_blame_opts = {
        delay = 500,
      },
    },
  },

  -- Telescope fuzzy finder customization
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            preview_width = 0.55,
          },
        },
        sorting_strategy = "ascending",
        prompt_prefix = " ",
        selection_caret = " ",
      },
    },
    keys = {
      -- Add useful telescope shortcuts
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
      { "<leader>fc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
      { "<leader>fs", "<cmd>Telescope git_status<cr>", desc = "Git Status" },
    },
  },

  -- Which-key customization
  {
    "folke/which-key.nvim",
    opts = {
      preset = "modern",
      delay = 300,
    },
  },

  -- Smooth scrolling
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    opts = {
      mappings = { "<C-u>", "<C-d>", "<C-b>", "<C-f>" },
      hide_cursor = true,
      stop_eof = true,
      respect_scrolloff = true,
    },
  },

  -- Indent guides (v3 API)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {
      indent = {
        char = "│",
        tab_char = "│",
      },
      scope = { show_start = false, show_end = false },
    },
  },

  -- Auto-pairs for brackets
  {
    "echasnovski/mini.pairs",
    opts = {
      modes = { insert = true, command = false, terminal = false },
    },
  },
}
