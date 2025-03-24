-- Bootstrap lazy.nvim (LazyVim's package manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Configure LazyVim
require("lazy").setup({
  spec = {
    -- LazyVim as a base
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    
    -- Import our custom plugins
    { import = "plugins" },
    
    -- You can enable these extras later by uncommenting them
    -- { import = "lazyvim.plugins.extras.coding.copilot" },
    -- { import = "lazyvim.plugins.extras.linting.eslint" },
    -- { import = "lazyvim.plugins.extras.formatting.prettier" },
    -- { import = "lazyvim.plugins.extras.lang.json" },
    -- { import = "lazyvim.plugins.extras.lang.typescript" },
    -- { import = "lazyvim.plugins.extras.lang.ruby" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded
    lazy = false,
    -- Use LazyVim's default version for plugins
    version = false,
  },
  checker = { enabled = true }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})