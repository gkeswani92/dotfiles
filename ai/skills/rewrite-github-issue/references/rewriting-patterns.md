# Rewriting Patterns - Advanced Techniques for Issue Condensation

This reference provides comprehensive patterns and techniques for transforming complex GitHub issue threads into clear, actionable documentation.

## Table of Contents

1. [Condensing Long Threads (50+ Comments)](#condensing-long-threads-50-comments)
2. [Identifying Signal vs. Noise](#identifying-signal-vs-noise)
3. [Preserving Technical Details](#preserving-technical-details)
4. [Handling Multiple Proposals](#handling-multiple-proposals)
5. [Edge Cases and Special Situations](#edge-cases-and-special-situations)

## Condensing Long Threads (50+ Comments)

Long threads require systematic analysis to extract value without losing critical information.

### Pattern: Chronological Mapping

Read through the entire thread chronologically and create a mental map of how the discussion evolved:

**Phase 1: Problem Discovery** (Comments 1-15)
- Initial report
- Clarifying questions
- Additional symptoms reported
- Reproduction attempts

**Phase 2: Investigation** (Comments 16-35)
- Root cause theories
- Debugging efforts
- Data gathering
- Dead ends and false starts

**Phase 3: Solution Convergence** (Comments 36-50)
- Proposed approaches
- Design debates
- Consensus building
- Implementation details

**Phase 4: Finalization** (Comments 51+)
- Refinements
- Edge case handling
- Final decisions

### Pattern: Last State Wins

When multiple comments discuss the same topic with evolving understanding:

**Example thread progression:**
- Comment 5: "This might be a caching issue"
- Comment 12: "Actually it's not caching, database queries are slow"
- Comment 18: "Found it - N+1 query problem in the user resolver"

**Rewrite approach:**
Capture the final, correct understanding: "Root cause: N+1 query problem in the user resolver"

Optionally note the investigation path if valuable: "Initial investigation explored caching and general database performance before identifying N+1 queries as the root cause."

### Pattern: Thematic Grouping

Bundle related technical points together even if they appeared scattered across many comments:

**Scattered in thread:**
- Comment 7: "Error occurs with PostgreSQL 14+"
- Comment 23: "Also happens on PostgreSQL 15"
- Comment 41: "Works fine on PostgreSQL 13.x"

**Grouped in rewrite:**
```markdown
## Proposed Solution

Environment specifics:
- Issue affects PostgreSQL 14 and 15
- PostgreSQL 13.x works correctly
- Likely related to query planner changes in v14
```

### Pattern: Noise Identification

Common noise patterns in long threads:

**Social exchanges:**
- "+1", "Me too", "Same here"
- "Thanks!", "Appreciate it!", "LGTM"
- "Any updates?", "Bumping this"

**Resolved tangents:**
- Questions that were answered inline
- Misunderstandings that were corrected
- Off-topic discussions that returned to focus

**Superseded information:**
- Early incorrect theories
- Debugging approaches that failed
- Solutions that were tried and didn't work

**Action:** Remove these entirely from the rewrite unless they provide important historical context about why certain approaches were rejected.

### Pattern: Volume Reduction Targets

Aim for these compression ratios:

- 10-20 comments → 3-5 key points
- 20-50 comments → 5-8 key points
- 50-100 comments → 8-12 key points
- 100+ comments → 12-15 key points

More comments don't necessarily mean more information. Beyond 100 comments, the incremental value per comment drops dramatically.

## Identifying Signal vs. Noise

### Signal Patterns

**Actionable information:**
- Error messages and stack traces
- Reproduction steps that work
- Root cause explanations
- Proposed solutions with rationale
- Design decisions with trade-offs
- Code snippets demonstrating the issue or fix
- Data points (metrics, timings, logs)
- Links to related issues, PRs, or documentation

**Context providers:**
- "This affects users on mobile"
- "Breaks backward compatibility with v1.x"
- "Performance impact: 200ms → 2s latency"
- "Happens only with Firefox 115+"

### Noise Patterns

**Social lubricant:**
- Expressions of agreement without new information
- Thank you messages (unless acknowledging specific contribution)
- Apologies for delays
- Meta-comments about the issue process

**Resolved confusion:**
```
User A: "Is this only in production?"
User B: "No, also in staging"
User A: "Got it, thanks"
```

Rewrite: "Affects both production and staging environments"

**Dead-end investigations:**
```
User A: "Maybe the problem is in the cache layer?"
[Several comments investigating caching]
User B: "Actually it's not the cache, it's the database"
```

Rewrite: Include only the correct finding (database), optionally note that caching was investigated and ruled out.

**Duplicate information:**

Multiple people reporting the same symptom or solution. Consolidate into a single statement.

### Gray Areas

**Important context that looks like noise:**

Some "noise" contains valuable context:

```
User: "Thanks for the fix! This was blocking our launch."
```

This reveals **impact severity**. Include this information, but rephrase: "Issue was blocking production launches."

**Rejected approaches with good rationale:**

If a solution was seriously considered but rejected for specific reasons, include this to prevent future reconsideration:

```markdown
## Proposed Solution

Approach: Use Redis caching

Note: Direct database optimization was considered but rejected because [reason].
```

## Preserving Technical Details

### Code Snippets

**Preserve when the code:**

1. **Demonstrates the problem:**
```javascript
// Shows the N+1 query issue
users.forEach(user => {
  user.posts = database.query('SELECT * FROM posts WHERE user_id = ?', user.id)
})
```

2. **Shows the solution:**
```javascript
// Proposed fix using eager loading
const users = database.query('SELECT * FROM users')
const posts = database.query('SELECT * FROM posts WHERE user_id IN (?)', userIds)
```

3. **Illustrates configuration:**
```yaml
# Required database.yml setting
pool_size: 25
timeout: 5000
```

**Condense when:**

Multiple people share similar snippets. Keep the clearest one, or combine them:

```javascript
// Combining insights from comments #12, #18, and #25
async function fixedImplementation() {
  const cachedResult = await cache.get(key)
  if (cachedResult) return cachedResult

  const result = await database.query(optimizedQuery)
  await cache.set(key, result, { ttl: 3600 })
  return result
}
```

### Error Messages

**Always preserve exactly:**
- Error codes: `ERR_CONNECTION_REFUSED`
- HTTP status codes: `500 Internal Server Error`
- Database errors: `ERROR: duplicate key value violates unique constraint "users_pkey"`
- Exception names: `NullPointerException`, `TypeError`

**Format consistently:**
```markdown
Error message:
```
ERROR: syntax error at or near "SELECT"
LINE 1: SELECT * FROM users WHERE id = $1 SELECT * FROM posts
```
```

### Environment Details

**Critical to preserve:**
- Version numbers: "Node 18.x", "PostgreSQL 14.2"
- Operating systems: "Ubuntu 22.04", "macOS Ventura"
- Browser/client: "Chrome 115+", "iOS Safari 16"
- Configuration values: "Max connections: 100", "Timeout: 30s"

**Format as structured data:**
```markdown
Environment:
- Node.js: 18.x
- PostgreSQL: 14.2
- Redis: 7.0.5
- OS: Ubuntu 22.04
- Deployment: Kubernetes 1.26
```

### Performance Metrics

**Preserve with context:**
- Before: "Query takes 200ms"
- After: "Query takes 2.5s"
- Impact: "P95 latency exceeds SLA threshold of 1s"

### Links and References

**Preserve all links to:**
- Related issues: `Related: #456`
- Pull requests: `Fixed by #789`
- Documentation: `[API docs](url)`
- Slack threads: `[Design discussion](slack-url)`
- RFCs or proposals: `[RFC-123](url)`
- External resources: Technical articles, bug reports in dependencies

## Handling Multiple Proposals

When a thread discusses multiple competing solutions:

### Pattern: Explicit Comparison

Present all viable options with trade-offs:

```markdown
## Proposed Solution

Three approaches were discussed:

### Option A: Redis Caching (Recommended)
- Pros: Fast, battle-tested, scales horizontally
- Cons: Adds infrastructure dependency, cache invalidation complexity
- Estimated effort: 3 days

### Option B: Application-level Memoization
- Pros: No new dependencies, simpler deployment
- Cons: Doesn't scale across instances, higher memory usage
- Estimated effort: 1 day

### Option C: Database Query Optimization
- Pros: Addresses root cause, no caching complexity
- Cons: Requires schema changes, longer development time
- Estimated effort: 5 days

Consensus: Proceed with Option A based on scalability requirements.
```

### Pattern: Decision Documentation

If the discussion reached consensus, document it clearly:

```markdown
## Proposed Solution

**Chosen approach:** Use WebSockets for real-time updates

**Decision rationale:**
- SSE considered but rejected due to lack of bidirectional communication
- Polling considered but rejected due to latency requirements (sub-100ms)
- WebSockets provide required latency and bidirectional capability

**Implementation:** [details]
```

### Pattern: Open Decision

If no consensus was reached, frame it as an open question:

```markdown
## Proposed Solution

**Open decision:** Choose between GraphQL and REST for new API

Options discussed:
1. GraphQL: Better client flexibility, requires new infrastructure
2. REST: Consistent with existing APIs, simpler to implement

**Decision needed:** Team lead to decide based on client requirements.

**Implementation:** [common details regardless of choice]
```

## Edge Cases and Special Situations

### Closed/Resolved Issues

When rewriting closed issues:

**If the fix is merged:**
```markdown
## Description
[Original problem description]

## Solution Implemented
Fixed in PR #789 by implementing [approach].

## Original Thread
[Historical context if valuable]
```

**If closed as won't-fix:**
```markdown
## Description
[Original request]

## Resolution
Closed as won't-fix because [reason].

Alternative: [Suggested workaround if any]
```

### Stale Issues Requiring Revival

Issues inactive for months but still relevant:

```markdown
## Description
[Original problem - still valid]

## Current Status
Last discussed [date]. Still relevant as of [current date] because [reason].

## Proposed Solution
[Updated approach based on current context]

## Historical Context
[Summary of original discussion, link to old thread]
```

### Security-Sensitive Issues

For security vulnerabilities:

**Before public disclosure:**
```markdown
## Description
[Vague description that doesn't reveal exploit details]

Security issue affecting [general area]. Details available to maintainers.

For details: See private security advisory [link]
```

**After fix is deployed:**
```markdown
## Description
[Now safe to include detailed technical explanation]

## Fix Implemented
[Detailed fix approach]
```

### Issues Spanning Multiple Components

Complex issues affecting multiple systems:

```markdown
## Description
[High-level problem statement]

Affects multiple components:
- Frontend: [specific issue]
- Backend API: [specific issue]
- Database: [specific issue]

## Proposed Solution

Coordinated fix across components:

### Frontend Changes
[Details]

### Backend Changes
[Details]

### Database Changes
[Details]

**Implementation order:**
1. Database migrations (enables new functionality)
2. Backend API updates (consumes new DB features)
3. Frontend updates (consumes new API)
```

### Issues With Significant Historical Context

When the original thread contains valuable historical context:

```markdown
## Description
[Current, clear problem statement]

## Proposed Solution
[Implementation approach]

## Original Thread

This issue has evolved significantly. Key historical points:

- **Initial report (Month YYYY):** [Original problem that turned out to be different]
- **Investigation findings (Month YYYY):** [What was learned]
- **Scope expansion (Month YYYY):** [How the issue grew]
- **Current state:** [Where we are now]

For full discussion: [#123](url)
```

## Practical Application Workflow

### Step 1: First Pass (Skim)

Read through quickly to understand:
- General topic and problem
- Approximate thread length and complexity
- Whether consensus was reached
- Key participants and their contributions

### Step 2: Deep Read (Analyze)

Read carefully, taking notes on:
- Technical details worth preserving
- Evolution of understanding
- Decision points and rationale
- Open questions or unresolved items

### Step 3: Structure (Organize)

Group notes into:
- Problem/impact (Description section)
- Solution/approach (Proposed Solution section)
- Historical/context (Original Thread section)

### Step 4: Draft (Write)

Write each section following the patterns above:
- Lead with impact
- Use active voice
- Preserve technical accuracy
- Be concise but complete

### Step 5: Validate (Check)

Ask:
- Could an engineer without context understand and act on this?
- Are all critical technical details preserved?
- Is anything important missing?
- Is any noise remaining?

### Step 6: Finalize (Polish)

- Fix formatting
- Add proper markdown syntax
- Ensure links work
- Verify code blocks have language tags

## Common Mistakes to Avoid

### Over-Condensing Technical Details

**Wrong:**
"Fixed the query performance issue"

**Right:**
"Fixed N+1 query issue in user resolver by implementing eager loading with `includes(:posts)`. Reduced query count from 500+ to 2 per request."

### Losing Important Context

**Wrong:**
"Implement feature X"

**Right:**
"Implement feature X. This unblocks the mobile team's Q3 launch and addresses the #1 customer complaint (50+ support tickets)."

### Preserving Too Much Noise

**Wrong:**
Including 10 comments of "+1" and "same here"

**Right:**
"Multiple users confirmed (see comments #3, #5, #8-14)"

### Vague Problem Statements

**Wrong:**
"The system is slow"

**Right:**
"API response time increased from 200ms to 3.5s for the `/users` endpoint under load (1000+ req/min), causing timeouts and failed requests."

### Missing Open Questions

**Wrong:**
"Implement solution X" (when approach wasn't finalized)

**Right:**
"Proposed approach: Solution X. Open questions: [Q1], [Q2]. Needs team decision before implementation."

## Examples of Excellent Rewrites

### Example 1: Bug Report (from 40 comments to clear description)

**Original thread:** 40 comments of back-and-forth debugging, multiple reproduction attempts, theory testing, eventual root cause discovery

**Rewritten:**
```markdown
## Description

User authentication fails intermittently (5-10% of requests) with `401 Unauthorized` errors. Affects production since deploy on Jan 15. Users must retry login 2-3 times to succeed.

Error from logs:
```
ERROR: JWT signature verification failed: token expired
Token issued_at: 1705334400, current_time: 1705334401, clock_skew: 2s
```

## Proposed Solution

Root cause: Clock skew between auth service and API gateway exceeds JWT validation tolerance (1 second).

Fix: Increase JWT clock skew tolerance to 5 seconds in auth validation:

```javascript
jwt.verify(token, secret, { clockTolerance: 5 })
```

Deployment: Low-risk config change, no downtime required.

Alternative considered: Synchronize server clocks with NTP. Rejected as overkill for this tolerance issue.
```

### Example 2: Feature Request (from 60 comments to clear specification)

**Original thread:** 60 comments discussing use cases, design approaches, technical feasibility, scope debates, refinement

**Rewritten:**
```markdown
## Description

Users need ability to export dashboard data in multiple formats (CSV, Excel, PDF). Current system only supports viewing data in browser. Blocking enterprise customers who require regular exports for compliance reporting.

Impact: 15 enterprise deals pending this feature (potential $1.2M ARR).

## Proposed Solution

Implement server-side export generation with format selection:

**Supported formats:**
- CSV: For data analysis and spreadsheet import
- Excel (.xlsx): For formatted reports with charts
- PDF: For archival and printed reports

**Implementation approach:**

1. Add export button to dashboard UI with format selector
2. Backend generates export asynchronously (job queue)
3. User receives email with download link when ready
4. Links expire after 7 days

**Technical details:**
- CSV: Use `fast-csv` library
- Excel: Use `exceljs` library
- PDF: Use `puppeteer` for HTML → PDF rendering
- Storage: S3 with 7-day lifecycle policy

**Out of scope:**
- Scheduled/recurring exports (future enhancement)
- Custom formatting options (use templates instead)
- Real-time exports (async only for large datasets)

**Open questions:**
- Maximum export size limit? (Proposal: 100k rows)
- Rate limiting per user? (Proposal: 10 exports/day)
```

## Summary

Effective issue rewriting requires:
- **Systematic analysis** of long threads using chronological mapping
- **Ruthless noise elimination** while preserving all signal
- **Precise technical detail** preservation
- **Clear structure** with progressive disclosure
- **Decision documentation** when multiple approaches were discussed
- **Validation** that the rewrite is actionable without context

The goal is always clarity: an engineer should read the rewrite and immediately understand what to do.
