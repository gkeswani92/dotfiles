# Vim Configuration

This directory contains configuration files for Vim, enhancing the editing experience with custom settings and color schemes.

## Contents

- `.vimrc`: Vim configuration file
- `colors/`: Vim color schemes
  - `molokai.vim`: Molokai color scheme based on Monokai for TextMate

## Vim Configuration (`.vimrc`)

The Vim configuration sets up various editor behaviors and preferences, making Vim more user-friendly and powerful.

Key features may include:
- Syntax highlighting
- Line numbering
- Tab and indentation settings
- Search improvements
- Key mappings for productivity
- Status line configuration

## Color Schemes

### Molokai

Molokai is a dark color scheme for Vim based on the Monokai theme for TextMate by Wimer Hazenberg. This color scheme features:

- Vibrant, high-contrast colors
- Good readability for code
- Support for various programming languages
- Separate colors for different syntax elements

## Usage

The Vim configuration and color schemes are automatically installed during dotfiles setup.

To manually apply the Vim configuration:

1. Copy or symlink the .vimrc file to your home directory:
   ```bash
   ln -sf ~/dotfiles/vim/.vimrc ~/.vimrc
   ```

2. Create the colors directory and copy the color schemes:
   ```bash
   mkdir -p ~/.vim/colors
   cp ~/dotfiles/vim/colors/* ~/.vim/colors/
   ```

3. To use the Molokai color scheme, add to your .vimrc:
   ```vim
   colorscheme molokai
   ```

## Customization

To add your own customizations, you can create a `.vimrc.local` file in your home directory and include it from the main `.vimrc`:

```vim
" Source local customizations if present
if filereadable(expand("~/.vimrc.local"))
  source ~/.vimrc.local
endif
```

This allows for machine-specific configurations without modifying the main dotfiles.