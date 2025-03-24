# Local Development Configuration

This directory contains configurations and scripts to streamline local development workflows, particularly using Zellij as a terminal multiplexer.

## Contents

- `zellij/`: Layouts for Zellij terminal multiplexer
  - `bp-full.kdl`: Complete development environment layout
  - `bp-orgs-only.kdl`: Organizations-only development layout

## Zellij Layouts

[Zellij](https://zellij.dev/) is a modern terminal multiplexer (like Tmux) that allows multiple terminal panes to be managed within a single window.

### bp-full.kdl

This layout sets up a complete development environment with multiple panes for:
- Identity services
- Business platform with pre-contract enabled
- Billing services
- Core services with workers
- Admin web interface
- Service monitoring and seeding

The layout is designed to start all necessary services for full-stack development, arranging them in a logical and accessible manner.

### bp-orgs-only.kdl

A more focused layout that includes only the organizational components needed for development, reducing resource usage when the full stack isn't required.

## Usage

The layouts can be activated via aliases defined in the shell configuration:

```bash
# Start full development environment
bp-full-local-dev

# Start organizations-only development environment
bp-orgs-only-dev
```

These aliases are automatically set up by the dotfiles installation.

## Customization

To create custom layouts:

1. Create a new .kdl file in the zellij directory
2. Define your layout using Zellij's layout language
3. Add a symlink in your install.sh:
   ```bash
   ln -sf $DOTFILES_PATH/local-development/zellij/your-layout.kdl ~/.config/zellij/your-layout.kdl
   ```
4. Add an alias to your .zshrc:
   ```bash
   alias your-layout-name="zellij --layout ~/.config/zellij/your-layout.kdl"
   ```

For detailed layout configuration options, refer to the [Zellij documentation](https://zellij.dev/documentation/).