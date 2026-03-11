# Integrations

This document covers all Graphite integrations including IDE extensions, notifications, issue trackers, AI tools, and CI optimization.

## VS Code Extension

### Overview

Create and manage stacked PRs visually within VS Code, eliminating the need for CLI.

### Installation

1. Open VS Code Extensions (Cmd/Ctrl + Shift + X)
2. Search "Graphite"
3. Install the Graphite extension
4. Authenticate when prompted

### Features

- Visual stack view in sidebar
- Create branches and PRs from editor
- Navigate stack with clicks
- View PR status and reviews
- Submit stacks without terminal

## Menu Bar App (macOS)

### Overview

Monitor PRs directly from the macOS menu bar.

### Installation

1. Download from Graphite website
2. Install and launch
3. Authenticate with GitHub

### Features

- PR status at a glance
- Quick access to PRs needing attention
- Notifications for reviews and merges
- Click to open PRs in browser

## Slack Notifications

### Overview

Real-time, actionable PR notifications directly in Slack.

### Setup

1. Go to Graphite Settings → Notifications
2. Click "Connect Slack"
3. Select your Slack workspace
4. Grant required permissions

### Permissions Granted

The Graphite Slack app requests:
- Send messages and start direct conversations
- Manage files within selected channels
- View workspace members and shared content
- Display previews of Graphite links

### Features

**Direct Actions from Slack:**
- Approve PRs (up to 25 lines) without leaving Slack
- Comment on PRs
- Request changes
- Merge PRs

**Customizable Notifications:**
- Review requests
- Comments and mentions
- Status changes
- Merge completions

### Configuration

In Graphite Settings → Notifications:
- Enable/disable notification types
- Set quiet hours
- Choose DM vs channel notifications

## Linear Integration

### Overview

View, link, and create Linear issues directly from PRs.

### Setup

1. Go to Graphite Settings → Integrations
2. Click "Connect Linear"
3. Authorize Graphite access
4. Select Linear workspace

### Features

**From Graphite PR page:**
- View linked Linear issues
- Create new Linear issues
- Link existing issues to PRs
- See issue status and priority

**Automatic Linking:**
- PRs referencing Linear IDs auto-link
- Branch names with Linear IDs auto-link
- Format: `TEAM-123` or `team-123`

## Jira Integration

### Overview

Connect Jira issues with Graphite PRs for seamless workflow tracking.

### Setup

1. Go to Graphite Settings → Integrations
2. Click "Connect Jira"
3. Authorize with Atlassian
4. Select Jira instance

### Features

**From Graphite PR page:**
- View linked Jira issues
- Create new Jira issues
- Link existing issues
- See issue status, assignee, priority

**Automatic Linking:**
- PRs referencing Jira IDs auto-link
- Branch names with Jira IDs auto-link
- Format: `PROJECT-123`

## GT MCP (AI Agent Integration)

### Overview

Enable AI agents to automatically create stacked PRs by breaking large AI-generated changes into smaller, reviewable PRs.

### Benefits

- **Better code review**: Large AI diffs become manageable stacked PRs
- **Chronological reasoning**: Agents validate each step sequentially
- **Improved clarity**: Changes presented in logical order

### Requirements

CLI version 1.6.7 or later:

```bash
# Update via Homebrew
brew update && brew upgrade withgraphite/tap/graphite

# Update via npm
npm install -g @withgraphite/graphite-cli@stable
```

### Claude Code Setup

```bash
claude mcp add graphite gt mcp
```

### Cursor Setup

Add to Cursor settings (Tools & Integrations):

```json
{
  "mcpServers": {
    "graphite": {
      "command": "gt",
      "args": ["mcp"]
    }
  }
}
```

### Usage

Once configured, AI agents can:
- Create stacked PRs from large changes
- Break work into logical increments
- Submit stacks for review automatically

### Status

GT MCP is currently in beta. Some workflows may lack full support.

## CI Optimizations

### Overview

Reduce unnecessary CI runs for stacked PRs using Graphite's CI optimizer API.

### How It Works

Each CI run calls Graphite's API to determine whether to skip:

```bash
# API returns boolean: whether CI should be skipped
curl https://api.graphite.dev/v1/ci/should-skip?pr=123
```

### Configuration Options

| Option | Description |
|--------|-------------|
| Bottom-of-stack PRs | Always run CI on foundational PRs |
| Top-of-stack CI | Run CI on final PR in stack |
| All PRs | Traditional behavior (run all) |

### Fail-Safe Design

The system is defensive:
- If API request fails → CI runs normally
- If API returns error → CI runs normally
- PRs in merge queue → CI always runs
- PRs merging as stacks → CI always runs

### GitHub Actions Setup

```yaml
name: CI

on: [pull_request]

jobs:
  optimize_ci:
    runs-on: ubuntu-latest
    outputs:
      skip: ${{ steps.check.outputs.skip }}
    steps:
      - id: check
        run: |
          RESULT=$(curl -s "https://api.graphite.dev/v1/ci/should-skip?pr=${{ github.event.pull_request.number }}&repo=${{ github.repository }}")
          echo "skip=$RESULT" >> $GITHUB_OUTPUT

  test:
    needs: optimize_ci
    if: needs.optimize_ci.outputs.skip != 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  build:
    needs: optimize_ci
    if: needs.optimize_ci.outputs.skip != 'true'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run build
```

### Buildkite Setup

**Option 1: Separate Pipeline**

Create a "Graphite CI optimizer" pipeline that runs before other pipelines:

```yaml
# graphite-optimizer.yml
steps:
  - label: "Check CI Skip"
    command: |
      SKIP=$(curl -s "https://api.graphite.dev/v1/ci/should-skip?pr=$BUILDKITE_PULL_REQUEST")
      if [ "$SKIP" = "true" ]; then
        echo "Skipping CI for this PR"
        buildkite-agent meta-data set "skip_ci" "true"
      fi
```

**Option 2: Add to Existing Pipeline**

```yaml
steps:
  - label: "Graphite CI Check"
    command: |
      SKIP=$(curl -s "https://api.graphite.dev/v1/ci/should-skip?pr=$BUILDKITE_PULL_REQUEST")
      buildkite-agent meta-data set "skip_ci" "$SKIP"

  - wait

  - label: "Tests"
    command: npm test
    if: build.meta_data.skip_ci != "true"
```

### Additional Optimization Strategies

**Dependency Management Tools:**
- Bazel, Buck - Run only affected tests
- Use target-level caching

**Workflow Orchestration:**
- Turborepo - Cache results based on file hashes
- Nx - Smart rebuilds with dependency graph

**Graphite Merge Queue:**
- Enables batching and parallel CI
- Reduces redundant CI runs

## Automations

### Overview

Create rules that trigger actions when PRs match specified criteria.

### Setup

1. Go to Graphite web app → Automations
2. Click "Create rule"
3. Select repository
4. Configure conditions and actions

### Available Triggers

**PR Filters:**
- Author (specific users or teams)
- Labels
- Base branch
- PR state (draft, ready, merged)

**File Patterns:**
- Glob patterns: `**/*.ts`, `src/components/**`
- Directory matching: `**/myteam/**`

### Available Actions

| Action | Description |
|--------|-------------|
| Add reviewers | Request review from users or teams |
| Assign users | Assign PR to users (including author) |
| Apply labels | Add labels to the PR |
| Post comment | Add comment with context/reminders |
| Slack notification | Send message to channel |
| Post GIF | Celebrate with GIPHY |

### Rule Behavior

- Rules match once per PR
- If PR doesn't initially match, re-evaluated on each update
- After matching once, won't trigger again
- Editing rules doesn't re-evaluate already-matched PRs

### Example Rules

**Auto-assign reviewers by directory:**
```
Condition: Files match `src/backend/**`
Action: Add reviewer @backend-team
```

**Label PRs by type:**
```
Condition: Title contains "fix:" or "bug:"
Action: Add label "bug"
```

**Notify on large PRs:**
```
Condition: Changed files > 10
Action: Slack notify #code-review
```
