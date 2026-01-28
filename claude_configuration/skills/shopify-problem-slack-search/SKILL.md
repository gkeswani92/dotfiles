---
name: shopify-problem-slack-search
description: Searching Slack for Shopify Problems
---

# Searching Slack for Shopify Problems

Use this skill when debugging Shopify issues or seeking context that isn't found in the codebase.

## When to Use

- When codebase search doesn't reveal context
- For recent changes, decisions, or discussions
- When error messages or issues seem familiar to the team
- Before giving up on finding an answer

## How to Search

Use `shopify-dw.people.slack_messages` via data-portal-mcp tool.

**Search for:**
- Error messages or keywords from the problem
- Related feature/component names
- Recent discussions (last 6 months)
- Team decisions or context
- Links to PRs, docs, or solutions

## Example Query

```sql
SELECT user_name, message, message_at, channel_name
FROM `shopify-dw.people.slack_messages`
WHERE TIMESTAMP_TRUNC(message_at, DAY) >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND (message LIKE '%keyword1%' OR message LIKE '%keyword2%')
ORDER BY message_at DESC
LIMIT 20
```

## Query Tips

- Adjust the time interval based on how recent the issue might be
- Use multiple keywords with OR for broader searches
- Filter by channel_name if you know which team owns the area
- Look for links to PRs, docs, or Jira tickets in the messages
