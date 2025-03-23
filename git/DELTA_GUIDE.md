# Git Delta Configuration Guide

[Git Delta](https://github.com/dandavison/delta) is a syntax-highlighting pager for git, diff, and grep output. This document provides guidance on how to configure and use git-delta effectively.

## Current Configuration

Our configuration in `.gitconfig` sets up delta with:

- Side-by-side view for easier comparison
- Line numbers for better reference
- Navigation using 'n' and 'N' keys
- Nord syntax highlighting theme
- Custom colors for additions and deletions
- Terminal decorations for improved visuals

## Using Delta

With the current configuration, delta will automatically be used when you run:

- `git diff`
- `git show`
- `git log -p`
- Interactive rebase

## Useful Delta Features

### Navigation

- `n`: Move to next diff section
- `N`: Move to previous diff section
- `/`: Search for patterns
- `q`: Quit the pager

### Viewing Options

If you need to temporarily override the side-by-side view:

```
# View in side-by-side mode (already default in our config)
git -c delta.side-by-side=true diff

# View in traditional unified view
git -c delta.side-by-side=false diff
```

### Syntax Themes

To try a different syntax theme temporarily:

```
git -c delta.syntax-theme=Dracula diff
```

Available themes include:
- Nord (current)
- Dracula
- Monokai
- GitHub
- OneHalfDark
- OneHalfLight
- Solarized (Dark/Light)
- TwoDark

## Troubleshooting

If you encounter any issues with delta:

1. Ensure delta is properly installed:
   ```
   which delta
   ```

2. Check your git configuration:
   ```
   git config --list | grep -i delta
   ```

3. For wide diffs, try disabling side-by-side view temporarily:
   ```
   git -c delta.side-by-side=false diff
   ```

4. If colors look wrong, try setting delta.light based on your terminal:
   ```
   # For light terminal backgrounds
   git -c delta.light=true diff
   
   # For dark terminal backgrounds (current default)
   git -c delta.light=false diff
   ```

## Customization Options

To further customize delta, you can add these options to your `.gitconfig`:

```
[delta]
  # Theme options
  minus-style                   = syntax "#3f2d3d"  # Style for removed lines
  plus-style                    = syntax "#283f3d"  # Style for added lines
  
  # Feature toggles
  hyperlinks = false                # Enable hyperlinks in HTML output
  tabs = 4                          # Set tab width
  line-numbers-left-format = "{nm:>4} "  # Format for line numbers
  keep-plus-minus-markers = false   # Show +/- markers at line starts
  
  # File features  
  file-style = bold yellow ul       # Style for file headers
  file-decoration-style = none      # Decorations for file headers
  hunk-header-style = syntax line-number  # Style for hunk headers
  
  # Other options
  width = auto                      # Width of side-by-side view
```

## Keyboard Shortcuts in Side-by-Side Mode

- `j` or `Down Arrow`: Scroll down
- `k` or `Up Arrow`: Scroll up
- `Space` or `Page Down`: Next page
- `b` or `Page Up`: Previous page
- `Home`: Go to top
- `End`: Go to bottom