-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua

local opt = vim.opt

-- UI
opt.relativenumber = true -- Relative line numbers
opt.number = true -- Show current line number
opt.scrolloff = 8 -- Keep 8 lines above/below cursor
opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
opt.cursorline = true -- Highlight current line
opt.termguicolors = true -- True color support
opt.signcolumn = "yes" -- Always show sign column

-- Tabs & Indentation (matching your .vimrc)
opt.tabstop = 2 -- 2 spaces for tabs
opt.shiftwidth = 2 -- 2 spaces for indent width
opt.expandtab = true -- Use spaces instead of tabs
opt.autoindent = true -- Copy indent from current line
opt.smartindent = true -- Smart autoindenting

-- Line wrapping
opt.wrap = false -- Disable line wrap
opt.textwidth = 120 -- Line width (matching your VSCode ruler)

-- Search
opt.ignorecase = true -- Ignore case when searching
opt.smartcase = true -- Unless capital letter in search
opt.hlsearch = true -- Highlight search results
opt.incsearch = true -- Show matches as you type

-- Split windows
opt.splitright = true -- Split vertical window to the right
opt.splitbelow = true -- Split horizontal window to the bottom

-- Clipboard
opt.clipboard = "unnamedplus" -- Use system clipboard

-- Files
opt.swapfile = false -- Disable swap files
opt.backup = false -- Disable backup files
opt.undofile = true -- Enable persistent undo
opt.undolevels = 10000 -- Maximum undo levels

-- Performance
opt.updatetime = 200 -- Faster completion
opt.timeoutlen = 300 -- Faster key sequence completion

-- Misc
opt.mouse = "a" -- Enable mouse support
opt.confirm = true -- Confirm to save changes before closing
opt.conceallevel = 0 -- Don't hide characters (e.g., in markdown)
