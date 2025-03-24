# Neovim Configuration with LazyVim

This directory contains a Neovim configuration based on [LazyVim](https://www.lazyvim.org/), a Neovim setup with sensible defaults and carefully selected plugins.

## Features

- 💤 Based on [LazyVim](https://www.lazyvim.org/) for efficient plugin management
- 🔌 Preconfigured with essential plugins for a great development experience
- 🎨 Configured with themes matching your terminal preferences
- ⚡ Fast and optimized for macOS
- 🔍 Full LSP (Language Server Protocol) support
- 🌳 Syntax highlighting with Treesitter
- 🔎 Fuzzy finding with Telescope
- 🧩 Git integration

## Installation

The included `install-neovim.sh` script automates the setup process:

1. It checks for Neovim installation, installing it if needed (using Homebrew on macOS)
2. Sets up LazyVim with our custom configurations
3. Configures additional language support and themes

To install, run:

```bash
./install-neovim.sh
```

## Key Bindings

LazyVim comes with many useful key bindings. Here are some highlights:

- `<Space>` - Leader key
- `<Space>ff` - Find files
- `<Space>fg` - Live grep
- `<Space>e` - File explorer
- `<Space>gg` - Lazygit
- `<C-h/j/k/l>` - Navigate between windows

Custom key bindings:

- `<Space>w` - Save file
- `<Space>F` - Format document
- `<C-\>` - Toggle terminal
- `<Space>sr` - Replace current word

## Included Language Support

- JavaScript/TypeScript
- HTML/CSS
- Python
- Ruby
- Go
- YAML with schema support
- GraphQL
- Markdown

## Themes

The configuration includes themes that match your terminal preferences:

- Catppuccin (default)
- Tokyo Night
- Dracula
- Nord
- Everforest
- Kanagawa
- Rose Pine

Change themes with `:Lazygit` → Colorscheme

## Customization

LazyVim follows a simple structure for customization:

- `lua/config/options.lua` - Editor options
- `lua/config/keymaps.lua` - Custom key mappings
- `lua/plugins/` - Plugin configurations

## Enabling LazyVim Extras

LazyVim provides optional "extras" for additional functionality. To enable them:

1. Edit `~/.config/nvim/lua/config/lazy.lua`
2. Uncomment the desired extras, for example:
   ```lua
   { import = "lazyvim.plugins.extras.lang.typescript" },
   { import = "lazyvim.plugins.extras.lang.json" },
   ```
3. Save and restart Neovim
4. Run `:Lazy sync` to install the new plugins

See the [LazyVim Extras documentation](https://www.lazyvim.org/extras) for all available extras.

## Updating

To update LazyVim and its plugins:

1. Open Neovim
2. Run `:LazyUpdate`