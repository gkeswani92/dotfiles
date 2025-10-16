---
description: Search Obsidian vault for ATC issue solutions and debugging steps. Optionally accepts a Slack URL to automatically fetch issue details.
---

## Your Task

### If a Slack URL is provided:

1. **Extract thread details** from the URL:

   - Parse channel ID and timestamp from the URL (format: `https://shopify.slack.com/archives/{CHANNEL_ID}/p{TIMESTAMP}`)
   - Use `mcp__slack-mcp__slack_get_thread_replies` to fetch the full thread

2. **Analyze the Slack thread** to understand:

   - What is the problem/issue being discussed?
   - What symptoms were observed?
   - What solutions or debugging steps were mentioned?
   - Extract key terms and concepts

3. **Search the Obsidian vault** using `mcp__obsidian__advanced_search` with relevant terms from the thread:

   - Look for matching symptoms
   - Search for related issue types
   - Find relevant runbooks in the "Shopify/Business Platform/Common ATC Issues" area

4. **Present findings** with:
   - Summary of the Slack thread issue
   - Matching runbook(s) from Obsidian
   - Additional context or related issues
   - Link to the original Slack thread

### If NO Slack URL is provided:

Search the Obsidian vault for information about the following ATC (Around the Clock) issue:

{{ISSUE_DESCRIPTION}}

Use the mcp**obsidian**advanced_search tool to find relevant notes about:

- Symptoms and diagnosis steps
- Resolution procedures
- Related issues and workarounds
- Quick reference information

Present the findings in a clear, actionable format with:

1. Diagnosis steps
2. Resolution steps
3. When to escalate and to whom
4. Any relevant links or references

If multiple relevant notes are found, synthesize the information into a coherent guide.
