# Searching Slack for Shopify Problems

When solving Shopify-related problems where you don't immediately know the answer:

1. **Search Slack first** - Shopify uses Slack for all communications and problem-solving
2. **Use:** `shopify-dw.people.slack_messages` via data-portal-mcp tool
3. **Search for:**
   - Error messages or keywords from the problem
   - Related feature/component names
   - Recent discussions (last 6 months)
   - Team decisions or context
   - Links to PRs, docs, or solutions

**Example query:**

```sql
SELECT user_name, message, message_at, channel_name
FROM `shopify-dw.people.slack_messages`
WHERE TIMESTAMP_TRUNC(message_at, DAY) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND (message LIKE '%keyword1%' OR message LIKE '%keyword2%')
ORDER BY message_at DESC
LIMIT 20
```

**When to search:**

- Before saying "I don't know"
- When codebase search doesn't reveal context
- For recent changes, decisions, or discussions
- When error messages or issues seem familiar to the team
