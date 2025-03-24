-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use macOS clipboard
vim.opt.clipboard = "unnamedplus"

-- Font settings for GUI clients
vim.opt.guifont = "JetBrains Mono:h14"

-- Set relative line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Increase command line height for better visibility
vim.opt.cmdheight = 1

-- Decrease updatetime for faster response
vim.opt.updatetime = 200

-- Enable persistent undo history
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undodir"

-- Enable mouse support
vim.opt.mouse = "a"

-- Set colorcolumn to mark 120 characters
vim.opt.colorcolumn = "120"

-- Disable swap file creation
vim.opt.swapfile = false

-- Keep signcolumn on
vim.opt.signcolumn = "yes"

-- Scroll offset
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

-- Use spaces instead of tabs
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Enable smart indent
vim.opt.smartindent = true

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
vim.opt.foldenable = false  -- Disable folding by default (enable with zM when needed)

-- Terminal configuration for better macOS experience
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.cmd("startinsert")
  end,
})