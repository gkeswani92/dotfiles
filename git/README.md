# Git Configuration

This directory contains Git configuration files and custom scripts to enhance the Git experience.

## Contents

- `.gitconfig`: Shared aliases, editor, diff/pager settings, and LFS
- `personal.gitconfig`: Personal name/email
- `work.gitconfig`: Work name/email, Shopify URL rewrites, dev Git include, and World maintenance
- `plugins/`: Git plugins (delta, interactive-rebase)
- `scripts/`: Custom Git scripts for improved workflows

## Machine Profile and Local Signing

`install.sh` uses the machine role stored in `~/.config/dotfiles/profile` for Git, shell/work integrations, and AI alike. Configure without installing software:

```bash
./install.sh --config-only --dry-run
./install.sh --config-only
```

Live `~/.gitconfig` is a local file that includes shared settings, the selected role's config, and `~/.config/dotfiles/git/<role>.local.gitconfig`, in that order. It must not be linked to a tracked file. Machine-local overrides are never committed, and each role has its own file.

When migrating, an existing matching email allows that role's `user.signingkey`, `commit.gpgsign`, `tag.gpgsign`, and `gpg.*` preferences to be preserved locally. A different role's signer is **not** copied. No private key material, credentials, or authentication stores are installed or moved. Set a work signer on the work machine rather than copying the personal key settings.

```bash
# Normal Git reads the includes; --global needs --includes for inspection.
git config --show-origin --get user.email
git config --global --includes --get user.signingkey
# Set local preferences without editing the repository or managed include wrapper.
git config --file ~/.config/dotfiles/git/personal.local.gitconfig commit.gpgsign true
```

The installer preserves local override files. Unknown existing Git configs and custom Zellij config/layouts require `--replace-conflicts`; inspect the preview before replacing them. Replaced configs are archived under `~/.dotfiles-backup/machine-*/`, and old `~/.gitconfig` symlink contents are frozen as a regular file. Compare independent old config files with your local overrides to retain additional custom settings. Repository-specific Git config and deliberate environment overrides still take precedence over global settings.

To change the machine role, use `./install.sh --config-only --reconfigure-profile` or the full installer. Do not use `--ai-only` for a role change after Git is configured. Reload the shell afterwards.

## Custom Git Scripts

The full installer links executable scripts into `~/.local/bin`, already on the dotfiles shell PATH. No sudo is needed and old `/usr/local/bin` copies are left intact. Independent local command conflicts require explicit backup/replacement.

### git-cob

Fuzzy branch checkout - uses fzf to interactively select and checkout branches.

Usage:
```bash
git cob
```

### git-credit

Quickly add co-author to commit messages for pair programming.

Usage:
```bash
git credit "Colleague Name" colleague@example.com
```

### git-delete-local-merged

Remove local branches that have been merged into the current branch.

Usage:
```bash
git delete-local-merged
```

### git-undo

Undo the last commit while keeping changes.

Usage:
```bash
git undo
```

### git-unpushed

Display commits that exist locally but haven't been pushed to remote.

Usage:
```bash
git unpushed
```

### git-up

Enhanced version of git pull that shows a better summary of changes.

Usage:
```bash
git up
```

## Git Aliases

The `.gitconfig` file contains several useful aliases:

- `git hist`: Pretty log with graph
- `git graph`: Detailed graph of commits
- `git d`: Show differences
- `git dc`: Show differences in cached files
- `git ds`: Show differences in staged files
- `git log`: Simplified log format
- `git br`: List branches
- `git co`: Checkout
- `git st`: Status
- `git cm`: Commit
- `git push`: Push current branch to origin
- `git pull`: Pull current branch from origin

## Git Plugins

- **git-delta**: Enhanced diff viewer with syntax highlighting and side-by-side view
- **git-interactive-rebase-tool**: Better UI for interactive rebase operations