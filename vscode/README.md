# Visual Studio Code Configuration

This directory contains configuration files for Visual Studio Code that serve as a global baseline for all your projects. Project-specific settings will overlay these global settings when you work in different repositories.

## Contents

- `settings.json`: Global VS Code settings for editor behavior, formatting, and language-specific configurations

## Features

The baseline VS Code settings include:

### Editor Appearance
- Modern theme (One Dark Pro)
- JetBrains Mono font with ligatures
- Material icon theme
- Ruler guides at 80 and 120 characters
- Bracket pair colorization
- Indentation guides

### Code Editing
- Tab size of 2 spaces (4 for Python)
- Format on save with appropriate formatters per language
- Trailing whitespace trimming
- Final newline insertion
- Smooth cursor animations
- Enhanced suggestions and completions

### Language-Specific Settings
- **JavaScript/TypeScript**: Prettier formatting, single quotes
- **HTML/CSS**: Prettier formatting
- **Ruby**: 2-space indentation with Ruby formatter
- **Python**: 4-space indentation with Black formatter (88 character line length)
- **Markdown**: Word wrapping and formatting

### Git Integration
- Smart commit enabled
- Automatic fetch
- GitLens integration for better version control visibility

### Terminal
- Integrated terminal configuration with custom font
- Uses ZSH as the default shell

## How It Works

The `settings.json` file in this directory is linked to VS Code's user settings location:
- macOS: `~/Library/Application Support/Code/User/settings.json`

This creates a global configuration that applies to all VS Code projects. When you open a project that has its own `.vscode/settings.json` file, those project-specific settings will override these global settings.

## Customization

To modify these settings:

1. Edit the `settings.json` file in this directory
2. Run the install script to update the symlink: `./install.sh`
3. Restart VS Code to apply changes

Alternatively, you can modify settings directly through VS Code's Settings UI, but those changes won't be tracked in your dotfiles unless you copy them back to this file.

## Project-Specific Settings

For project-specific settings, create a `.vscode/settings.json` file in your project directory with only the settings you want to override from the global configuration.

Example project-specific `.vscode/settings.json`:
```json
{
  "editor.tabSize": 4,
  "python.formatting.provider": "yapf",
  "python.linting.enabled": true
}
```