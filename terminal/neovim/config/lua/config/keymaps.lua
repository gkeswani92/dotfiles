-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }

-- Better window navigation (matches tmux navigation)
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- Resize windows with arrows
keymap("n", "<C-Up>", ":resize -2<CR>", opts)
keymap("n", "<C-Down>", ":resize +2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- Stay in indent mode when changing indentation
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)

-- Move text up and down
keymap("v", "J", ":m '>+1<CR>gv=gv", opts)
keymap("v", "K", ":m '<-2<CR>gv=gv", opts)

-- Keep search matches in the middle
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)

-- Keep cursor in place when joining lines
keymap("n", "J", "mzJ`z", opts)

-- Better navigation with half page jumps
keymap("n", "<C-d>", "<C-d>zz", opts)
keymap("n", "<C-u>", "<C-u>zz", opts)

-- Terminal mode with escape
keymap("t", "<Esc>", "<C-\\><C-n>", opts)

-- Quick macros
keymap("n", "Q", "@qj", opts)
keymap("x", "Q", ":norm @q<CR>", opts)

-- Quick replace of the word under cursor
keymap("n", "<leader>sr", ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", { desc = "Replace Current Word" })

-- Quick format document (additional to LazyVim's format)
keymap("n", "<leader>F", function() vim.lsp.buf.format({ async = true }) end, { desc = "Format Document" })

-- Quickly select all text in buffer
keymap("n", "<C-a>", "ggVG", { desc = "Select All Text" })

-- Clear search highlights with escape
keymap("n", "<Esc>", ":noh<CR>", opts)

-- Move between buffers
keymap("n", "<S-l>", ":bnext<CR>", opts)
keymap("n", "<S-h>", ":bprev<CR>", opts)

-- Quickly save file
keymap("n", "<leader>w", ":w<CR>", { desc = "Save File" })