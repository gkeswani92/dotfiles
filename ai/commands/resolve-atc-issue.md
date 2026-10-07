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

4. **If Obsidian search yields no helpful results**, fallback to GitHub documentation:
   - Search for relevant files in `/Users/gaurav/world/trees/root/src/areas/platforms/organizations/documentation/playbooks` using `Glob` tool
   - Look for playbooks, runbooks, and troubleshooting guides
   - Read and analyze matching documentation files
   - Extract relevant diagnosis and resolution steps

5. **If GitHub documentation yields no helpful results**, fallback to Slack search:
   - Use `mcp__slack-mcp__slack_search` to search `#help-accounts-and-access` channel
   - Search with relevant keywords from the original issue
   - Look for similar problems and their resolutions
   - Analyze threads that contain solutions or workarounds
   - Extract common resolution patterns

6. **Automatically resolve maintenance task inputs via Data Portal MCP**: If the runbook's resolution involves running a maintenance task that requires looking up an ID (e.g., `plus_store_addition_approval_id`), **do not** tell the user to run the query manually. Instead:
   - Extract the relevant identifiers from the Slack thread (e.g., internal shop ID, organization ID, shopify shop ID)
   - Use the `mcp__data_portal__query_bigquery` tool to run the lookup query against `sdp-ingest-snapshots-prod.business_platform.*` tables
   - Present the results in a clear table format with all relevant fields
   - Explicitly state which value to use as the maintenance task input and include the maintenance task URL
   - **Only if the Data Portal MCP query fails**, fall back to telling the user to run the KateSQL query manually

   Example queries by issue type:
   - **Re-approving rejected store addition requests**: Query `plus_store_addition_approvals` joined with `store_addition_requests` using the internal shop ID
     ```sql
     SELECT psaa.id AS plus_store_addition_approval_id,
            psaa.store_addition_request_id,
            psaa.status,
            psaa.created_at,
            sar.store_domain,
            sar.shopify_shop_id
     FROM `sdp-ingest-snapshots-prod.business_platform.plus_store_addition_approvals` psaa
     JOIN `sdp-ingest-snapshots-prod.business_platform.store_addition_requests` sar
       ON psaa.store_addition_request_id = sar.id
     WHERE sar.shop_id = {internal_shop_id}
       AND sar.created_at >= '{year}-01-01'
     ORDER BY psaa.created_at DESC
     LIMIT 5;
     ```

7. **Present findings** with:
   - Summary of the Slack thread issue
   - Source of information (Obsidian/GitHub/Slack)
   - Matching runbook(s) or solutions found
   - Maintenance task inputs (pre-resolved via Data Portal MCP where possible)
   - Additional context or related issues
   - Link to the original Slack thread

### If NO Slack URL is provided:

Search for information about the following ATC (Around the Clock) issue:

{{ISSUE_DESCRIPTION}}

1. **Search the Obsidian vault** using `mcp__obsidian__advanced_search` to find relevant notes about:
   - Symptoms and diagnosis steps
   - Resolution procedures
   - Related issues and workarounds
   - Quick reference information

2. **If Obsidian search yields no helpful results**, fallback to GitHub documentation:
   - Search for relevant files in `/Users/gaurav/world/trees/root/src/areas/platforms/organizations/documentation/playbooks` using `Glob` tool
   - Look for playbooks, runbooks, and troubleshooting guides
   - Read and analyze matching documentation files
   - Extract relevant diagnosis and resolution steps

3. **If GitHub documentation yields no helpful results**, fallback to Slack search:
   - Use `mcp__slack-mcp__slack_search` to search `#help-accounts-and-access` channel
   - Search with relevant keywords from the issue description
   - Look for similar problems and their resolutions
   - Analyze threads that contain solutions or workarounds
   - Extract common resolution patterns

4. **Automatically resolve maintenance task inputs via Data Portal MCP**: Same as step 6 in the Slack URL flow above — if the resolution involves a maintenance task, query the Data Portal MCP to pre-resolve the required IDs. Only fall back to manual KateSQL instructions if the query fails.

5. **Present the findings** in a clear, actionable format with:
   - Source of information (Obsidian/GitHub/Slack)
   - Diagnosis steps
   - Resolution steps with pre-resolved maintenance task inputs where possible
   - When to escalate and to whom
   - Any relevant links or references

If multiple relevant notes are found, synthesize the information into a coherent guide.
