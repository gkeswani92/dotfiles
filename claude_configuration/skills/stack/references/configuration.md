# CLI Configuration

This document covers all Graphite CLI configuration options.

## Configuration Locations

### User-Level Configuration

Stored in `~/.config/graphite/` (respects `$XDG_CONFIG_HOME` if set).

Files:
- `user_config` - User preferences and settings
- `auth_token` - GitHub authentication token

### Repository-Level Configuration

Stored in `.git/graphite/` within each repository.

Files:
- `repo_config` - Repository-specific settings
- `branch_metadata` - Tracked branch information

## Shell Completion Setup

Enable tab completion for `gt` commands:

```bash
# zsh (add to ~/.zshrc)
gt completion >> ~/.zshrc

# bash (add to ~/.bashrc or ~/.bash_profile)
gt completion >> ~/.bashrc

# fish
gt fish >> ~/.config/fish/completions/gt.fish
```

After adding, restart your shell or source the config file.

## Interactive Configuration

Run `gt config` to interactively configure settings:

```bash
gt config
```

This opens a menu to configure all options described below.

## Branch Naming Settings

Configure automatic branch name generation from commit messages.

### Custom Prefix

Add a prefix to all generated branch names:

```bash
gt config
# Select: Branch naming → Custom prefix
# Enter: "dc" (your initials)

# Result: dc/feat-add-user-endpoint
```

### Date Prepending

Add date prefix to branch names:

```bash
gt config
# Select: Branch naming → Prepend date
# Enable: Yes

# Result: 2024-01-15/feat-add-user-endpoint
# Or with custom prefix: dc/2024-01-15/feat-add-user-endpoint
```

### Character Restrictions

Control allowed characters in branch names:

| Option | Description | Default |
|--------|-------------|---------|
| Allow slashes | Permit `/` in names | Yes |
| Allow uppercase | Permit uppercase letters | No |
| Replacement character | Replace invalid chars | `-` |

```bash
gt config
# Select: Branch naming → Character restrictions
```

## Submit Settings

### PR Metadata Editing

Choose where to edit PR title/description:

```bash
gt config
# Select: Submit → Edit PR info
# Options:
#   - Web UI (opens browser)
#   - CLI (opens $EDITOR)
#   - Never (use commit message)
```

### PR Description Content

Configure what's included in PR descriptions:

| Option | Description |
|--------|-------------|
| GitHub templates | Include `.github/PULL_REQUEST_TEMPLATE.md` |
| Commit messages | Include commit message body |
| Both | Include both |
| Neither | Empty description |

```bash
gt config
# Select: Submit → PR description content
```

## Rebase Behavior

### Preserve Commit Dates

Enable `--committer-date-is-author-date` during rebases:

```bash
gt config
# Select: Rebase → Preserve commit dates
# Enable: Yes
```

This keeps original commit timestamps instead of using rebase time.

## Empty Branch Handling

Configure behavior when operations result in empty branches:

```bash
gt config
# Select: Empty branches → After operations
# Options:
#   - Keep (preserve empty branches)
#   - Delete (remove empty branches)
#   - Prompt (ask each time)
```

## Default Utilities

### Editor

Set the editor for interactive operations:

```bash
# In gt config
gt config
# Select: Utilities → Editor

# Or via environment variable
export GT_EDITOR="code --wait"
export GT_EDITOR="vim"
export GT_EDITOR="nano"
```

Default: Uses `$GIT_EDITOR` or `$EDITOR`

### Pager

Set the pager for long output:

```bash
# In gt config
gt config
# Select: Utilities → Pager

# Or via environment variable
export GT_PAGER="less -FRX"
export GT_PAGER="bat"
```

Default: Uses `$GIT_PAGER` or `$PAGER`

Recommended: `LESS=FRX` or `LV=-c` for best experience.

## Additional Settings

### Tips

Toggle inline CLI hints and tips:

```bash
gt config
# Select: Tips → Show tips
# Enable/Disable
```

### Yubikey Reminders

Enable notifications for hardware key operations:

```bash
gt config
# Select: Yubikey → Remind to touch
# Enable: Yes
```

Shows reminder when Yubikey touch is required (e.g., GPG signing).

### Automatic Updates

Control CLI update behavior:

```bash
gt config
# Select: Updates
# Options:
#   - Auto-update (update automatically)
#   - Prompt (ask before updating)
#   - Never (disable updates)
```

## Repository-Level Settings

### Git Remote

Customize which remote Graphite uses:

```bash
gt config
# Select: Repository → Git remote
# Enter: "upstream" (default: "origin")
```

Useful for fork workflows where `origin` is your fork and `upstream` is the main repo.

### GitHub Repository Override

Override inferred GitHub repository:

```bash
gt config
# Select: Repository → GitHub info
# Enter owner: "myorg"
# Enter repo: "myrepo"
```

Useful when Git remote URL doesn't match GitHub repository.

## Multiple GitHub Accounts

Support for multiple GitHub profiles with separate auth tokens (v1.7.2+).

### Define Profiles

Edit `~/.config/graphite/user_config`:

```json
{
  "profiles": {
    "work": {
      "authToken": "ghp_work_token_here"
    },
    "personal": {
      "authToken": "ghp_personal_token_here"
    }
  },
  "defaultProfile": "work"
}
```

### Set Default Profile (v1.7.9+)

```bash
gt config
# Select: Set default profile
# Choose: work / personal
```

### Use Environment Variable (v1.7.2-1.7.8)

```bash
# For specific commands
GRAPHITE_PROFILE=personal gt submit

# Or export for session
export GRAPHITE_PROFILE=personal
gt submit
```

### Per-Repository Profile

Set profile for specific repositories:

```bash
cd ~/personal-projects/repo
gt config
# Select: Repository → Profile
# Choose: personal
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `GT_EDITOR` | Override editor for interactive operations |
| `GT_PAGER` | Override pager for long output |
| `GRAPHITE_PROFILE` | Select auth profile |
| `GRAPHITE_DISABLE_TELEMETRY` | Disable anonymous usage telemetry |
| `XDG_CONFIG_HOME` | Override config directory location |

## Config File Format

### User Config Example

`~/.config/graphite/user_config`:

```json
{
  "branchPrefix": "dc",
  "branchDate": false,
  "allowSlashesInBranchNames": true,
  "allowUppercaseInBranchNames": false,
  "submitEditPrInfo": "web",
  "submitIncludeCommitMessages": true,
  "submitIncludeGithubTemplates": true,
  "preserveCommitDates": false,
  "emptyBranchBehavior": "prompt",
  "showTips": true,
  "yubikeyReminder": false,
  "autoUpdate": true,
  "defaultProfile": "work",
  "profiles": {
    "work": {
      "authToken": "ghp_xxx"
    }
  }
}
```

### Repository Config Example

`.git/graphite/repo_config`:

```json
{
  "remote": "origin",
  "owner": "myorg",
  "repo": "myrepo",
  "profile": "work"
}
```

## Troubleshooting Configuration

### Reset to Defaults

```bash
# Remove user config
rm ~/.config/graphite/user_config

# Remove repo config
rm -rf .git/graphite/

# Reconfigure
gt config
```

### View Current Config

```bash
# Show all settings
gt config --show

# Or read config files directly
cat ~/.config/graphite/user_config
cat .git/graphite/repo_config
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
gt --debug <command>
```

Shows detailed information about config loading and command execution.
