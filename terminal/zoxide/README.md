# Zoxide - Smart Directory Navigation

Zoxide is a smarter cd command for your terminal that remembers which directories you use most frequently, so you can "jump" to them with minimal typing.

## Features

- **Fast**: Quickly jump to directories without typing full paths
- **Smart**: Uses a weighted algorithm to prioritize recent/frequent directories
- **Seamless**: Works with your existing muscle memory for cd
- **Interactive**: Fuzzy search for directories when you're not sure
- **Cross-shell**: Works in bash, zsh, fish, and others

## Usage

With zoxide installed, you can use the following commands:

| Command | Description |
|---------|-------------|
| `z foo` | Jump to a directory that contains "foo" |
| `z foo bar` | Jump to a directory that contains "foo" and "bar" |
| `z -` | Jump back to the previous directory |
| `zi` | Interactive selection using fzf |
| `zl` | List all directories in the database with their scores |
| `zc foo` | Jump to a subdirectory of the current directory that contains "foo" |
| `zf` | Alias for `zi` (fuzzy find) |

## Examples

```bash
# Jump to a directory you frequently visit
z projects

# Jump to a specific project using multiple keywords
z node project

# Jump back to the previous directory
z -

# Use interactive selection when you're not sure
zi

# List all tracked directories
zl
```

## Customization

The configuration for zoxide is in `config.zsh`. 

By default, we:
- Initialize zoxide with zsh
- Set up `cd` as an alias for `z` to make the transition seamless
- Add several useful aliases for common operations

## Notes

- The more you use zoxide, the smarter it gets about your navigation patterns
- The z command will match any part of the path, not just the directory name
- You can still use absolute paths with z: `z /usr/local/bin` works like normal
- The database of directories is stored in `~/.local/share/zoxide/db.sqlite`