---
name: buildkite
description: Query Buildkite build status, jobs, logs, and artifacts
---

# Buildkite CLI

Query Buildkite build status, jobs, logs, and artifacts.

## First-Time Setup

If CLI returns `Error: Not authenticated`, tell the user to run:

```bash
.ai-shared/skills/buildkite/scripts/buildkite auth
```

This opens Buildkite in the browser for token generation. User pastes token directly into terminal.

**Important**: Never ask user to share their token with you. Auth happens directly in CLI.

## Commands

```bash
CLI=.ai-shared/skills/buildkite/scripts/buildkite

# Set up credentials (user runs manually)
$CLI auth

# List organizations
$CLI orgs

# List pipelines
$CLI pipelines [org]

# List recent builds (default: 10)
$CLI builds [org] [pipeline] [limit]

# Get build status with jobs
$CLI status <build#> [org] [pipeline]

# List jobs for a build
$CLI jobs <build#> [org] [pipeline]

# Get job log
$CLI log <build#> <job-id> [org] [pipeline]
$CLI log --tail <build#> <job-id> [...]    # last 100 lines

# List artifacts
$CLI artifacts <build#> [org] [pipeline] [filter]

# Get artifact download URL
$CLI artifact-url <build#> <filename> [org] [pipeline]
```

## Parsing Buildkite URLs

When given a URL like `buildkite.com/shopify/shop-client/builds/123`:
- org = `shopify`
- pipeline = `shop-client`
- build# = `123`

## Workflow Examples

### Check a failing build

```bash
# Get build status
$CLI status 123

# Find the failed job ID from output, then get logs
$CLI log 123 <job-id>

# Or just the tail
$CLI log --tail 123 <job-id>
```

### Download artifacts

```bash
# List available artifacts
$CLI artifacts 123

# Filter by name
$CLI artifacts 123 shopify shop-client report

# Get download URL for specific file
$CLI artifact-url 123 report.html
```

## Tool Path

| Tool | Path |
|------|------|
| buildkite | `.ai-shared/skills/buildkite/scripts/buildkite` |
