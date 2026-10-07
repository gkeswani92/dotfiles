View all my PRs with review status, CI status, comments, deploy status, and Graphite stack grouping.

# Your Task: PR Control Center

**Your Goal:** Fetch all of gkeswani92's open and recently merged/closed PRs from shop/world, enrich with deploy status from Infra Central, detect Graphite stacks, analyze CI failures, and render a single actionable dashboard.

---

## Performance Optimization

**IMPORTANT:** Run independent data fetches IN PARALLEL by making multiple tool calls in a SINGLE message.

- Step 1 (GitHub fetch) and Step 2 (Infra Central query) are INDEPENDENT — run them in parallel.
- Within Step 1, the three `gh pr list` calls are independent — run them in parallel.
- Step 4 (Buildkite failures) can only run after Step 1 completes.
- Step 3 (stack detection) and Step 5 (action items) run after all data is gathered.

---

## Step 1: Fetch PRs from GitHub

Run these three commands IN PARALLEL using Bash:

### 1a. Open PRs

```bash
gh pr list --author gkeswani92 --repo shop/world --state open --limit 50 \
  --json number,title,headRefName,baseRefName,state,createdAt,reviewDecision,statusCheckRollup,comments,url
```

### 1b. Recently merged PRs

```bash
gh pr list --author gkeswani92 --repo shop/world --state merged --limit 30 \
  --json number,title,headRefName,baseRefName,state,mergedAt,createdAt,reviewDecision,statusCheckRollup,comments,url
```

Filter client-side: keep only PRs where `mergedAt` is within the last 10 days.

### 1c. Recently closed (non-merged) PRs

```bash
gh pr list --author gkeswani92 --repo shop/world --state closed --limit 20 \
  --json number,title,headRefName,baseRefName,state,mergedAt,closedAt,createdAt,reviewDecision,statusCheckRollup,comments,url
```

Filter client-side: keep only PRs where `mergedAt` is null (truly closed, not merged) AND `closedAt` is within the last 10 days. These may be Graphite stack children that were merged via merge queue.

### 1d. Fetch unresolved review comments for OPEN PRs only

For each open PR from step 1a, fetch review threads:

```bash
gh pr view <number> --repo shop/world --json reviewThreads
```

Count threads where `isResolved == false`. Run these in parallel if there are multiple open PRs.

---

## Step 2: Fetch Deploy Status from Infra Central

**Run IN PARALLEL with Step 1.** Use `mcp__infra-central-mcp__execute_query`:

```sql
SELECT DISTINCT
  pr.number AS pr_number,
  dd.status AS deploy_status,
  dd.finished_at AS deployed_at,
  dd.rollback
FROM github_pull_requests pr
JOIN conveyor_commit_events ce_merge
  ON ce_merge.event_source_type = 'Github::PullRequest'
  AND ce_merge.event_source_id = pr.id
  AND ce_merge.event = 'merged'
JOIN conveyor_commit_events ce_deploy
  ON ce_deploy.github_commit_id = ce_merge.github_commit_id
  AND ce_deploy.event = 'deployment_ended'
  AND ce_deploy.event_source_type = 'Deploy::Deployment'
JOIN deploy_deployments dd
  ON dd.id = ce_deploy.event_source_id
WHERE pr.author_login = 'gkeswani92'
  AND pr.merged_at > DATE_SUB(NOW(), INTERVAL 10 DAY)
ORDER BY pr.merged_at DESC
```

**Known limitations:**
- Infra Central has indexing lag for very recent PRs (merged in last few hours)
- Graphite stack PRs merged via merge queue may show as CLOSED in GitHub's API and may be missing from IC
- For stack children without IC data, show "deployed via #bottom_pr" in the output
- If a PR has multiple deploy records, show the latest `deployed` one; note if any were `canceled`

---

## Step 3: Build Stacks & Detect Graphite Grouping

**Stack detection algorithm:**

1. Build a map: `headRefName -> PR` for ALL fetched PRs (open + merged + closed)
2. For each PR, check if its `baseRefName` matches another PR's `headRefName`
3. If yes: it's a child of that PR. If `baseRefName == main`: it's a root or standalone
4. Build chains: root -> child -> grandchild (follow the baseRefName links)
5. Stacks with only 1 PR are "standalone"
6. Order PRs within a stack: bottom of stack (based on main) first, top last

**Graphite closed PR heuristic:** Treat a CLOSED (non-merged) PR as effectively "merged" if:
- `reviewDecision == "APPROVED"` AND CI passed
- AND `headRefName` follows Graphite naming patterns (e.g., contains the author's name or `gt/` prefix)
- Show these as "Merged (via queue)" in the output

---

## Step 4: Fetch Buildkite Failure Details

For any PR where `statusCheckRollup` contains a check with `status == "FAILURE"` or `conclusion == "FAILURE"`:

1. Extract the Buildkite build URL from the failing check's `targetUrl`
2. Parse the pipeline name and build number from the URL (format: `buildkite.com/shopify/<pipeline>/builds/<number>`)
3. Use `mcp__buildkite-mcp__list_failed_job_ids` with the pipeline and build number to get failed jobs
4. Use `mcp__buildkite-mcp__get_job_failures` for the top prioritized failed job
5. Read the downloaded log file and grep for error patterns: `FAIL`, `Error:`, `assertion`, `NoMethodError`, `undefined method`
6. Extract a 2-3 line summary of the failure

Limit to analyzing the top 3 CI-failing PRs to avoid excessive API calls.

---

## Step 5: Generate Action Items

Analyze all gathered data and output a prioritized action list using these rules:

| Priority | Condition | Action |
|----------|-----------|--------|
| HIGH | Open PR, CI failing | "Fix CI failure on #NNN: [brief summary from Step 4]" |
| HIGH | Open PR, changes requested | "Changes requested on #NNN -- address reviewer feedback" |
| MEDIUM | Open PR, has unresolved review comments | "Address X unresolved comments on #NNN" |
| MEDIUM | Stack with mix of merged + open | "Stack has merged PRs waiting on open #NNN -- unblock it" |
| LOW | Open PR, no review yet, waiting > 2 days | "Needs review -- #NNN has been waiting since DATE" |
| INFO | Open PR, approved, CI passing, no unresolved comments | "Ready to merge -- consider merging #NNN" |
| INFO | Merged PR, deploy canceled | "Deploy was canceled for #NNN -- check if re-deploy needed" |
| INFO | Merged PR, not yet in IC | "Recently merged #NNN -- deploy status pending" |
| DONE | Stack fully merged and deploying/deployed | "Stack 'X' fully merged and deploying -- no action needed" |

---

## Output Format

Render the full report in this order:

### 1. Header

```
# PR Control Center -- gkeswani92 (last 10 days)
```

### 2. Action Items (at the TOP)

```
## Action Items

1. [RED_CIRCLE] Fix CI failure on #467755 -- `test_legal_entity_transfer_archiving` NoMethodError
2. [YELLOW_CIRCLE] Address 2 unresolved comments on #467755
3. [GREEN_CIRCLE] Stack "completeness-operators" fully merged and deploying -- no action needed
4. [INFO] #499109 merged today -- deploy status pending in Infra Central
```

Use emoji indicators: RED for high priority, YELLOW for medium, GREEN for done/good, INFO for informational.

### 3. Stacks (grouped)

For each stack with 2+ PRs, render a section:

```
## Stack: <descriptive name from branch> (<N> PRs) -- <stack summary status>

| # | Title | State | Reviews | CI | Comments | Deploy |
|---|-------|-------|---------|----|----------|--------|
| ... | ... | ... | ... | ... | ... | ... |
```

If a PR has CI failures analyzed in Step 4, add a line below its row:
```
  [ARROW] CI Failure: <pipeline> -- `<test_name>`
     <error class>: <error message> (line NNN)
```

Stack summary status examples: "Merged + Deployed", "Merged + Deploying", "1 Merged, 1 Open", "All Open"

### 4. Standalone PRs

```
## Standalone PRs

| # | Title | State | Reviews | CI | Comments | Deploy |
|---|-------|-------|---------|----|----------|--------|
| ... | ... | ... | ... | ... | ... | ... |
```

### 5. Summary footer

```
---
Summary: NN PRs total | X open | Y merged | Z closed | W deployed | V deploying
```

### Column Definitions

| Column | Source | Logic |
|--------|--------|-------|
| # | GitHub | PR number, linked to URL |
| Title | GitHub | Truncated to ~55 chars |
| State | GitHub | Open / Merged / Closed / Merged (via queue) |
| Reviews | GitHub | `reviewDecision`: Approved / Changes Requested / Pending / -- |
| CI | GitHub | From `statusCheckRollup`: count non-SKIPPED checks. Show `X/Y passed` or `N failing` |
| Comments | GitHub | Open PRs: "X unresolved" (from reviewThreads). Merged/Closed: total comment count |
| Deploy | Infra Central | "deployed DATE" / "deploying" / "canceled" / "via #NNN" / "--" |

---

## Edge Cases

- **Graphite CLOSED PRs**: Treat as "Merged (via queue)" if reviewDecision == APPROVED and CI passed and branch follows Graphite naming conventions
- **IC missing data**: Show "--" in the Deploy column, not an error
- **PRs with multiple deploy records**: Show the latest `deployed` one; if any were `canceled`, note it in parentheses
- **Stack children without IC data**: Show "via #NNN" where NNN is the bottom-of-stack PR number (the one based on main)
- **Empty results**: If no PRs found, say "No PRs found for gkeswani92 in the last 10 days"
- **CI check counting**: Exclude checks with status "SKIPPED" or conclusion "SKIPPED" from the count
