# Web Features

This document covers Graphite's web platform features: PR Inbox, Insights, Admin, and Merging.

## PR Inbox

### Overview

The PR inbox functions as an "email client" for managing pull requests. It helps organize and prioritize which PRs need attention.

### Default Sections

| Section | Description |
|---------|-------------|
| Needs your review | PRs awaiting your review |
| Approved | PRs you've approved |
| Returned to you | PRs with feedback on your changes |
| Merging and recently merged | PRs in merge process |
| Drafts | Draft PRs |
| Waiting for review | PRs awaiting others' reviews |

### Repository Limits

| Plan | Default Repositories |
|------|---------------------|
| Free | Up to 3 |
| Team | Up to 30 |
| Enterprise | Up to 30 |

PRs from non-default repos can still be viewed but won't appear in inbox.

### Customization

**Creating New Sections:**
1. Click "add new section" button
2. Configure filters and preferences
3. Rearrange by dragging

**Section Management:**
- Edit via ⚙️ icon on section headers
- Rearrange sections by dragging in left menu
- Share filter configurations via generated links

**Shareable Filter Links:**
- Generate link to share filter configuration
- Link can dynamically replace GitHub username
- Useful for team-wide filter standards

### Search

- Fuzzy search across PR titles, descriptions, and authors
- Access via sidebar or Cmd+K keyboard shortcut
- Real-time filtering

## Insights (Beta)

### Overview

Engineering velocity metrics to measure and improve team efficiency. Create, save, and share custom views with queries.

### Available Metrics

**Aggregated Team Statistics:**
- Total PRs merged
- Average PRs merged per person
- Average PRs reviewed per person
- Median publish-to-merge time
- Median review response time
- Median wait time to first review
- Average review cycles until merge

**Historical Graphs:**
- PR reviews by user
- PR merges by user
- Graphite adoption status

**Individual User Metrics:**
- Granular performance data per team member
- Table format for comparison

### Time Period Configuration

| Period | Options |
|--------|---------|
| Fixed | Week, month, quarter, year |
| Custom | Any date range |

**Historical Data Availability:**

| Plan | History |
|------|---------|
| Starter | 2 months |
| Standard/Enterprise | Up to 2 years |

### User Filtering

Filter by:
- Individual contributors
- User groups
- Organization-wide aggregate

## Admin Features

### Becoming a Graphite Admin

Automatic admin status through:
- **GitHub privileges**: Admin or owner in GitHub
- **Team creation**: Creating a team in Graphite
- **Payment entry**: Entering payment details
- **Admin promotion**: Promoted by other admins

**Note**: Graphite admin status does not extend GitHub privileges.

### User Management

Access via Settings > Billing:

**Adding Members:**
- Invite teammates
- Appear in membership list after accepting

**Role Assignment:**
- Admin or Member roles
- Admins can promote anyone to admin

**Member Removal:**
- Click ellipsis menu next to names
- Remove from team

**Access Restrictions:**
- "Restrict access" enables read-only mode
- Admins retain privileges in read-only mode

### Billing Management

Subscriptions via Stripe (Settings > Billing > Manage plan):
- Any organization member can access portal
- Designated payment managers update payment methods

## Merging PRs

### Overview

Click purple "Merge" button on PR title bar to initiate merging.

### Merge Behavior by Stack Position

| Position | Behavior |
|----------|----------|
| First PR or solo | Merges only that PR |
| Mid-stack | "Merge N" merges all PRs up to position N |
| Top of stack | Merges all PRs in stack |

### Pre-Merge Configuration

Modal options before merging:
- Select merge strategy (pre-filled from GitHub defaults)
- Edit custom commit titles and messages
- Use GitHub admin merge privileges to bypass blockers

**Note**: Admin bypass unavailable with GitHub rulesets.

### Merge Process

1. Graphite merges PRs one-by-one
2. Automatic rebasing as needed
3. GitHub comment tracks merge status
4. Upstack PRs automatically rebased

### Conflict Resolution

If rebase conflicts occur:

```bash
gt sync && gt restack && gt submit --stack
# Resolve conflicts with:
gt continue
```

Then re-queue merge from affected PR.

### Automatic Rebasing

Graphite creates temporary `graphite-base/*` branches for rebasing upstack PRs. Requires merging through Graphite UI (not GitHub).

### CI Configuration

Configure CI to ignore `graphite-base/*` branches:

```yaml
# GitHub Actions example
on:
  pull_request:
    branches-ignore:
      - 'graphite-base/**'
```

## Code Indexing

### Overview

Optional feature allowing Graphite to maintain a searchable index of files in synced repositories. By default, Graphite retrieves data directly from GitHub (which can cause rate limiting).

### Benefits

| Feature | Improvement |
|---------|-------------|
| Graphite Chat | Faster, more consistent tool results without rate limits |
| AI Reviews | Faster file analysis |
| Merge Queue | Faster file diffs |
| PR Review Pages | Reduced GitHub API dependency |

### Enable/Disable

Graphite admins toggle via settings dashboard:

**When Enabled:**
- Indexing begins on repositories and PRs as they update

**When Disabled:**
- Indexing stops
- All indexed code deleted within 30 days
- Features revert to GitHub API calls

## Automations

### Overview

Create rules that trigger actions when PRs match specified criteria.

### Setup

1. Go to Graphite web app → Automations
2. Click "Create rule"
3. Select repository
4. Configure conditions and actions
5. Preview matched PRs
6. Activate rule

### Filter Triggers

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
| Add assignees | Assign PR to users (including author) |
| Apply labels | Add labels to PR |
| Post comment | Add comment with context/reminders |
| Slack notification | Send message to channel |
| Post GIF | Celebrate with GIPHY |

### Rule Behavior

- Rules match once per PR
- Re-evaluated on each PR update until match
- After matching, won't trigger again on that PR
- Editing rules doesn't re-evaluate already-matched PRs
- GitHub comment confirms rule match with link to definition

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

**Flag PRs exceeding size limits:**
```
Condition: Lines changed > 250 OR Files changed > 25
Action: Post comment "Consider breaking into smaller PRs"
```

## Plans & Billing

### Available Plans

| Plan | Cost | Target |
|------|------|--------|
| Starter | $20/seat/month (annual) | Small teams |
| Team | $40/seat/month (annual) | Growing teams |
| Enterprise | Custom | Scale operations |

### Core Features (All Plans)

- GitHub sync across all repositories
- PR inbox and notifications
- CLI, VSCode, MCP support
- Stack merge functionality
- AI-generated PR titles/descriptions

### Plan Comparison

| Feature | Starter | Team | Enterprise |
|---------|---------|------|------------|
| Integrations | Basic (Slack) | Advanced | Advanced |
| Chat & PR reviews | Limited | Unlimited | Unlimited |
| Review customization | - | Yes | Yes |
| Suggested fixes | - | Yes | Yes |
| CI summaries | - | Yes | Yes |
| Insights dashboard | - | Yes | Yes |
| CI optimizer | - | Yes | Yes |
| Merge queue | - | Basic | Advanced |
| Custom analytics | - | - | Yes |
| ACLs | - | - | Yes |
| SAML/SSO | - | - | Yes |
| Audit logging | - | - | Yes |
| GHES support | - | - | Yes |
| Premium support | - | - | SLAs |

### Trial

- 30-day Team plan trial
- Unlimited contributors during trial

### Billing

- Monthly: Invoiced monthly
- Annual: Invoiced yearly + prorated monthly for new seats
- Seat changes reflected on following month's invoice
