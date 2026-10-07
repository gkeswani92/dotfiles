# Example: Rewritten GitHub Issue (After)

This is the same issue from `before-raw-issue.md`, now rewritten following the rewriting patterns. Compare the clarity and actionability.

---

## Issue #482: N+1 Query Performance Issue in User Endpoints

## Description

The `/api/users` endpoint performance degraded from 500ms to 3.5s response time in production following the PostgreSQL upgrade on Jan 12. Affects all requests to user-related endpoints under load.

Root cause: N+1 query problem compounded by database query planner changes in PostgreSQL 14.

## Proposed Solution

**Fix: Implement eager loading to eliminate N+1 queries**

The current implementation makes 101 database queries per request:
- 1 query to fetch 50 users
- 50 queries to fetch posts for each user
- 50 queries to fetch profiles for each user

Replace with single optimized query using JOINs and JSON aggregation:

```javascript
async function getUsers() {
  const users = await db.query(`
    SELECT
      users.*,
      json_agg(posts.*) as posts,
      row_to_json(profiles.*) as profile
    FROM users
    LEFT JOIN posts ON posts.user_id = users.id
    LEFT JOIN profiles ON profiles.user_id = users.id
    WHERE users.active = true
    GROUP BY users.id, profiles.id
    LIMIT 50
  `);

  return users;
}
```

**Performance improvement:**
- Before: 3.5s response time, 101 queries
- After: 180ms response time, 1 query
- 19x faster

**Affected endpoints:**
- `/api/users` (primary issue)
- `/api/posts` (same N+1 pattern found)
- `/api/comments` (same N+1 pattern found)

**Why this surfaced now:**

The PostgreSQL 13 → 14 upgrade on Jan 12 changed query planner behavior. PostgreSQL 14's improved cost estimation now correctly identifies that with only 5% active users (after recent bulk imports), sequential scans are more efficient than index scans for this query. This exposed the existing N+1 query inefficiency that was previously masked by faster individual queries.

**Implementation:**
- Apply eager loading pattern to all three affected endpoints
- Test with production data volume (2M+ users, 5% active)
- Deploy with zero downtime (backward compatible change)

**Fix:** Implemented in PR #489, merged and deployed Jan 21.

## Original Thread

For complete investigation history including debugging attempts (cache investigation, statistics tuning, query planner analysis): [#482](https://github.com/example/repo/issues/482)

Key investigation points:
- Initially suspected caching issue (ruled out - 85% cache hit rate)
- Investigated PostgreSQL 14 query planner changes
- Attempted statistics tuning (did not resolve)
- Discovered data distribution shift (95% inactive users after imports)
- Identified N+1 query pattern as root cause
