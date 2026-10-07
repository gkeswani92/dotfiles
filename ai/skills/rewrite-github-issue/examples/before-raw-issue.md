# Example: Raw GitHub Issue Thread (Before Rewriting)

This is an example of a real GitHub issue thread that has accumulated 35+ comments with lots of back-and-forth discussion, debugging attempts, and noise.

---

## Original Issue #482: API Performance Problem

**@user123** opened this issue on Jan 15, 2024

Hi, the API seems really slow lately. Anyone else seeing this?

---

**@developer1** commented on Jan 15, 2024

Can you provide more details? Which endpoint? What's the response time?

---

**@user123** commented on Jan 15, 2024

The `/api/users` endpoint. It used to be fast but now takes forever.

---

**@user456** commented on Jan 15, 2024

+1, I'm seeing this too!

---

**@developer1** commented on Jan 15, 2024

How long is "forever"? Can you measure the actual response time?

---

**@user123** commented on Jan 16, 2024

Sorry, checked just now - it's taking about 3-4 seconds. It used to be under 500ms.

---

**@developer2** commented on Jan 16, 2024

Is this in production or development?

---

**@user123** commented on Jan 16, 2024

Production. Dev seems fine.

---

**@developer1** commented on Jan 16, 2024

Let me investigate. Could be a caching issue.

---

**@developer1** commented on Jan 16, 2024

Checked Redis, cache hit rate is normal (85%). Not a caching issue.

---

**@user789** commented on Jan 17, 2024

Same here. Very slow since last week.

---

**@developer3** commented on Jan 17, 2024

I think this might be related to the database upgrade we did on Jan 12?

---

**@developer1** commented on Jan 17, 2024

Good point. We upgraded from PostgreSQL 13 to 14 on Jan 12. Let me check the query performance.

---

**@developer1** commented on Jan 17, 2024

Found something interesting. Running EXPLAIN on the query:

```sql
EXPLAIN ANALYZE SELECT * FROM users WHERE active = true ORDER BY created_at DESC LIMIT 50;
```

The query plan changed. It's using sequential scan instead of the index now.

---

**@developer3** commented on Jan 17, 2024

Why would the planner change behavior? We have an index on `active` and `created_at`.

---

**@developer1** commented on Jan 17, 2024

PostgreSQL 14 has a new query planner. Might be making different decisions.

---

**@database_admin** commented on Jan 18, 2024

Did you run ANALYZE after the upgrade?

---

**@developer1** commented on Jan 18, 2024

We ran VACUUM but not ANALYZE. Let me do that now.

---

**@developer1** commented on Jan 18, 2024

Ran ANALYZE on all tables. Still seeing the same slow query plan.

---

**@developer3** commented on Jan 18, 2024

Maybe we need to update the statistics target?

---

**@developer1** commented on Jan 18, 2024

Tried increasing stats target to 1000. No change in query plan.

---

**@database_admin** commented on Jan 18, 2024

Looking at the EXPLAIN output, I notice the cost estimates are way off. The planner thinks the sequential scan will be cheaper.

Actually, I just realized - when was the last time statistics were updated? The data distribution might have changed significantly.

---

**@developer1** commented on Jan 18, 2024

We've been adding a lot of inactive users lately (imports from old system). Active users are now only about 5% of total.

---

**@database_admin** commented on Jan 18, 2024

That's the issue! The index selectivity changed. With only 5% active users, PostgreSQL 14's planner correctly chooses sequential scan because reading 5% of rows means reading most data pages anyway.

The fix isn't to force index usage - it's to optimize the query itself. We're fetching too much data.

---

**@developer2** commented on Jan 19, 2024

So what's the fix?

---

**@database_admin** commented on Jan 19, 2024

We have an N+1 query problem. Let me check the actual application code.

Looking at the endpoint handler:

```javascript
async function getUsers() {
  const users = await db.query('SELECT * FROM users WHERE active = true LIMIT 50');

  for (const user of users) {
    user.posts = await db.query('SELECT * FROM posts WHERE user_id = $1', [user.id]);
    user.profile = await db.query('SELECT * FROM profiles WHERE user_id = $1', [user.id]);
  }

  return users;
}
```

This is making 1 query for users, then 50 queries for posts, then 50 queries for profiles = 101 total queries!

---

**@developer1** commented on Jan 19, 2024

Oh wow, I didn't realize we had that N+1 issue. That's definitely a problem.

---

**@developer3** commented on Jan 19, 2024

But this code hasn't changed. Why is it slow now?

---

**@database_admin** commented on Jan 19, 2024

Because before Jan 12, we had fewer total users so the queries were faster. Now with millions of inactive users, the query planner behavior changed AND we're hitting the database more times per request.

---

**@developer2** commented on Jan 19, 2024

How do we fix the N+1 issue?

---

**@database_admin** commented on Jan 19, 2024

Use eager loading. Here's the fixed version:

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

This reduces 101 queries to 1 query.

---

**@developer1** commented on Jan 19, 2024

That's a big query. Will it be faster?

---

**@database_admin** commented on Jan 19, 2024

Yes, I tested it. Goes from 3.5s to 180ms.

---

**@developer3** commented on Jan 19, 2024

Nice! Should we apply this pattern to other endpoints too?

---

**@database_admin** commented on Jan 19, 2024

Yes, I found the same N+1 issue in `/api/posts` and `/api/comments` endpoints.

---

**@developer2** commented on Jan 20, 2024

Should I create a PR for this?

---

**@database_admin** commented on Jan 20, 2024

Yes please. I can review it.

---

**@developer2** commented on Jan 20, 2024

PR created: #489

---

**@user123** commented on Jan 20, 2024

Thanks for investigating this!

---

**@developer1** commented on Jan 21, 2024

PR merged. Deployed to production.

---

**@user123** commented on Jan 21, 2024

Confirmed fixed! API is fast again. 🎉

---

**@developer3** commented on Jan 21, 2024

Great work team!

---

## Summary of Issues With This Thread

This thread demonstrates common problems:

1. **Lengthy back-and-forth**: 35+ comments to reach a solution
2. **Social noise**: Multiple "+1", "thanks", "great work" comments
3. **Debugging tangents**: Cache investigation, statistics tuning attempts that didn't help
4. **Buried key information**: The actual root cause (N+1 queries) appears in comment #23
5. **Scattered technical details**: Query examples, response times, and fix spread across many comments
6. **Missing structure**: No clear problem statement or solution summary
7. **Hard to parse**: A new engineer would need to read all 35+ comments to understand

**Next**: See `after-rewritten.md` for how this should be structured.
