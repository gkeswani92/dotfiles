---
description: Search Obsidian vault for ATC issue solutions and debugging steps. Optionally accepts a Slack URL to automatically fetch issue details.
---

Resolve ATC issue: $ARGUMENTS

## Your Task

### If a Slack URL is provided:

1. **Extract thread details** from the URL:
   - Use the `slack_thread` tool with the Slack URL to fetch the full thread

2. **Analyze the Slack thread** to understand:
   - What is the problem/issue being discussed?
   - What symptoms were observed?
   - What solutions or debugging steps were mentioned?
   - Extract key terms and concepts

3. **Search the Obsidian vault** using the obsidian CLI with relevant terms from the thread:
   ```bash
   obsidian search query="relevant search terms" path="Shopify/Business Platform/Common ATC Issues" format=json
   ```
   - For richer context around matches:
   ```bash
   obsidian search:context query="relevant search terms" path="Shopify/Business Platform/Common ATC Issues"
   ```
   - Search by tags for ATC-specific content:
   ```bash
   obsidian tags name="business-platform/atc" verbose
   ```
   - Read matched notes:
   ```bash
   obsidian read path="path/to/matched/note.md"
   ```
   - Find related notes via backlinks:
   ```bash
   obsidian backlinks file="matched note"
   ```

4. **If Obsidian search yields no helpful results**, fallback to GitHub documentation:
   - Search for relevant files in `/Users/gaurav/world/trees/root/src/areas/platforms/organizations/documentation/playbooks` using bash
   - Look for playbooks, runbooks, and troubleshooting guides
   - Read and analyze matching documentation files
   - Extract relevant diagnosis and resolution steps

5. **If GitHub documentation yields no helpful results**, fallback to Slack search:
   - Use the `slack_search` tool to search `#help-accounts-and-access` channel
   - Search with relevant keywords from the original issue
   - Look for similar problems and their resolutions
   - Analyze threads that contain solutions or workarounds
   - Extract common resolution patterns

6. **Present findings** with:
   - Summary of the Slack thread issue
   - Source of information (Obsidian/GitHub/Slack)
   - Matching runbook(s) or solutions found
   - Additional context or related issues
   - Link to the original Slack thread

### If NO Slack URL is provided:

Search for information about the following ATC (Around the Clock) issue using the description provided above.

1. **Search the Obsidian vault** using the obsidian CLI to find relevant notes:
   ```bash
   obsidian search query="relevant search terms" path="Shopify/Business Platform/Common ATC Issues" format=json
   ```
   - Also search with context:
   ```bash
   obsidian search:context query="relevant search terms" path="Shopify/Business Platform/Common ATC Issues"
   ```
   - Search by tags:
   ```bash
   obsidian tags name="business-platform/atc" verbose
   ```
   - Read matched notes and explore backlinks for related content

2. **If Obsidian search yields no helpful results**, fallback to GitHub documentation:
   - Search for relevant files in `/Users/gaurav/world/trees/root/src/areas/platforms/organizations/documentation/playbooks` using bash
   - Look for playbooks, runbooks, and troubleshooting guides
   - Read and analyze matching documentation files
   - Extract relevant diagnosis and resolution steps

3. **If GitHub documentation yields no helpful results**, fallback to Slack search:
   - Use the `slack_search` tool to search `#help-accounts-and-access` channel
   - Search with relevant keywords from the issue description
   - Look for similar problems and their resolutions
   - Analyze threads that contain solutions or workarounds
   - Extract common resolution patterns

4. **Present the findings** in a clear, actionable format with:
   - Source of information (Obsidian/GitHub/Slack)
   - Diagnosis steps
   - Resolution steps
   - When to escalate and to whom
   - Any relevant links or references

If multiple relevant notes are found, synthesize the information into a coherent guide.
