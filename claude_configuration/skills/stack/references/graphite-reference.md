# Graphite Reference

## Overview

Graphite is a platform for creating, reviewing, and merging stacked pull requests with GitHub. The `gt` CLI simplifies git commands and enables PR stacking to help developers move faster and stay unblocked by breaking large changes into small, incremental, reviewable pieces.

## Core Concepts

### What is Stacking?

Stacking organizes related code changes as a sequence of dependent pull requests rather than one large PR. Benefits:
- Stay unblocked while waiting for reviews
- Smaller PRs get reviewed faster
- Clearer review context for each change
- Merge independently as reviews complete

### Stack Structure

```
main
 └── feature-api (PR #1) ← bottom of stack
      └── feature-frontend (PR #2)
           └── feature-tests (PR #3) ← top of stack
```

## Quick Start

### Installation

```bash
# macOS
brew install withgraphite/tap/graphite

# npm
npm install -g @withgraphite/graphite-cli

# Authenticate
gt auth --token <github-token>
```

### Basic Workflow

```bash
# 1. Create first branch in stack
gt checkout main
# make changes...
gt create --all --message "feat(api): add user endpoint"

# 2. Stack another PR on top
# make more changes...
gt create --all --message "feat(frontend): add user page"

# 3. Submit entire stack
gt submit --stack  # or: gt ss

# 4. Sync with trunk and cleanup
gt sync
```

## Essential Commands

### Navigation

| Command | Alias | Description |
|---------|-------|-------------|
| `gt checkout` | `gt co` | Switch to branch (interactive picker) |
| `gt up` | `gt u` | Move up one branch in stack |
| `gt down` | `gt d` | Move down one branch in stack |
| `gt top` | `gt t` | Jump to top of stack |
| `gt bottom` | `gt b` | Jump to bottom of stack |
| `gt log` | - | Display full stack with PR info |
| `gt log short` | `gt ls` | List all branches in stack |

### Creating & Modifying

| Command | Alias | Description |
|---------|-------|-------------|
| `gt create -am "msg"` | `gt c -am` | Create branch, stage all, commit |
| `gt modify -a` | `gt m -a` | Stage all and amend current commit |
| `gt modify -c` | `gt m -c` | Add new commit (don't amend) |
| `gt modify -cam "msg"` | - | Stage all, add commit with message |

### Syncing & Submitting

| Command | Alias | Description |
|---------|-------|-------------|
| `gt sync` | - | Pull trunk, restack, cleanup merged |
| `gt submit` | - | Push current + downstack, create PRs |
| `gt submit --stack` | `gt ss` | Push entire stack |
| `gt submit -u` | - | Update existing PRs only |

### Reorganizing

| Command | Alias | Description |
|---------|-------|-------------|
| `gt restack` | - | Rebase stack on updated parents |
| `gt move` | - | Change branch parent |
| `gt fold` | - | Merge branch into parent |
| `gt split` | `gt sp` | Split branch by commit/hunk/file |
| `gt squash` | `gt sq` | Combine commits |
| `gt reorder` | - | Rearrange branches in stack |
| `gt absorb` | `gt ab` | Distribute staged changes to relevant commits |

### Collaboration & Recovery

| Command | Description |
|---------|-------------|
| `gt get <branch>` | Fetch teammate's stack locally |
| `gt track` | Start managing existing git branch |
| `gt untrack` | Stop tracking branch |
| `gt freeze` | Lock branch against modifications |
| `gt undo` | Reverse last Graphite operation |

## Common Workflows

### Addressing Review Feedback

```bash
# 1. Checkout the PR needing changes
gt checkout first_pr_in_stack

# 2. Make edits, then amend
gt modify -a

# 3. Resubmit (auto-restacks dependent branches)
gt submit --stack
```

### Adding Changes to Middle of Stack

```bash
# Stage specific changes
git add specific_file.js

# Absorb distributes to relevant commits downstack
gt absorb
```

### Splitting a Large Branch

```bash
# Interactive split by commit, hunk, or file
gt split
```

### Merging Stack

Navigate to Graphite web UI to merge, or use `gt merge` for the topmost PR. The merge queue handles dependent PRs automatically.

## Web Features

### PR Inbox

An "email client" for PRs with sections:
- Needs your review
- Approved / Returned to you
- Merging / Recently merged
- Drafts / Waiting for review

Customize with filters, search (Cmd+K), and shareable filter links.

### AI Reviews

Automatic code analysis identifying:
- Logic bugs and edge cases
- Security vulnerabilities
- Performance issues
- Debug statements / accidentally committed code

Configure in repository settings. Focuses on real bugs, not style nitpicks.

### Automations

Create rules that trigger when PRs match criteria:
- Add reviewers (individuals or teams)
- Apply labels
- Post comments
- Send Slack notifications

Configure via Graphite web app → Automations.

## Merge Queue

Stack-aware merge queue that:
- Validates stacked PRs in parallel (not sequentially)
- Enables fast-forward merges without re-running CI
- Keeps trunk stable with automatic rebasing

Strategies: **Rebase** (preserve commits), **Squash** (one commit per PR), or **Fast-Forward**.

Setup: Configure GitHub branch protection, then enable in Graphite repository settings.

## GT MCP Integration

Enable AI agents to create stacked PRs automatically:

```bash
# Claude Code
claude mcp add graphite gt mcp

# Cursor (add to settings)
{
  "mcpServers": {
    "graphite": { "command": "gt", "args": ["mcp"] }
  }
}
```

Requires CLI version 1.6.7+.

## CI Optimizations

Reduce CI runs for stacked PRs by configuring Graphite's CI optimizer:
- Configure which PRs in stack run CI (top, bottom, all)
- API endpoint returns boolean for skip decision
- Fail-safe: if API errors, CI runs normally

See `references/integrations.md` for GitHub Actions and Buildkite setup.

## Configuration

### Shell Completion

```bash
gt completion >> ~/.zshrc   # zsh
gt completion >> ~/.bashrc  # bash
gt fish >> ~/.config/fish/completions/gt.fish
```

### Branch Naming

Configure via `gt config`:
- Custom prefix (e.g., initials)
- Date prepending
- Character restrictions

### Multiple GitHub Accounts

Define profiles in `~/.config/graphite/user_config` for separate auth tokens.

## Monorepo Optimizations

In large monorepos with thousands of branches, `gt` commands can be slow. The main bottlenecks are:

1. **Branch enumeration** - `git for-each-ref` lists all branches
2. **Metadata reading** - Spawns one git process per tracked branch
3. **Git fetch** - Negotiates with thousands of remote refs

### Cleanup Stale Branches

Untrack all branches with CLOSED or MERGED PRs (requires `gh` CLI):

```bash
bash ~/.claude/skills/graphite/scripts/cleanup-stale-branches.sh
```

See `scripts/cleanup-stale-branches.sh` for the full script.

### Other Optimizations

- **Use `gt restack` instead of `gt sync`** when you don't need to fetch from remote
- **Use direct checkout** (`gt checkout branch-name`) instead of interactive picker
- **Limit git fetch refspec** to only fetch branches you need:
  ```bash
  git config remote.origin.fetch '+refs/heads/main:refs/remotes/origin/main'
  git config --add remote.origin.fetch '+refs/heads/your-prefix/*:refs/remotes/origin/your-prefix/*'
  ```
- **Enable git maintenance** for faster git operations:
  ```bash
  git maintenance start
  git commit-graph write --reachable
  ```

## Troubleshooting Quick Reference

| Issue | Solution |
|-------|----------|
| Stack out of sync | `gt sync` to pull trunk and restack |
| Merge conflicts | Resolve conflicts, then `gt continue` |
| Wrong parent branch | `gt move` to reassign parent |
| Need to undo | `gt undo` reverses last operation |
| Branch not tracked | `gt track` to add existing branch |
| Slow gt commands | Run cleanup script above, use `gt restack` instead of `gt sync` |

## Background Agents

Describe tasks in plain language; Graphite spins up sandboxes to write code, run tests, and open PRs:
- Quick fixes from phone/browser without cloning
- Generate boilerplate and scaffolding
- Add tests without context-switching
- $10 free credits; unlimited with own Claude API key

## Graphite Chat

AI assistant in PR review interface:
- Request PR summaries and explanations
- Propose fixes applied with one click
- Search codebase for related code
- Debug CI failures with full context

## Additional Resources

### Reference Files

For detailed documentation, consult:

**CLI & Commands:**
- **`references/commands.md`** - Complete command reference with all options, Git vs gt comparison, installation, authentication

**Workflows:**
- **`references/stacking-workflows.md`** - Detailed stacking patterns, advanced workflows, collaboration, common scenarios
- **`references/best-practices.md`** - Reviewing stacked PRs, creating stacks, organization setup, anti-patterns

**Platform Features:**
- **`references/merge-queue.md`** - Merge queue setup, optimizations (parallel CI, batching, fast-forward), troubleshooting
- **`references/ai-features.md`** - AI reviews, Graphite Chat, Background Agents, GT MCP integration, customization
- **`references/web-features.md`** - PR inbox, insights, admin, automations, merging, plans & billing

**Configuration:**
- **`references/integrations.md`** - Slack, VS Code, Linear, Jira, CI optimizations setup
- **`references/configuration.md`** - Full CLI configuration options, branch naming, multi-account

### External Links

- Documentation: https://graphite.com/docs
- LLM-optimized docs: https://graphite.com/docs/llms-full.txt
- Activate CLI: https://app.graphite.com/activate
