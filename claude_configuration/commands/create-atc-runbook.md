You are helping create an ATC (Application Triage and Care) runbook from Slack thread(s).

## Your Task

1. **Fetch the Slack thread(s)** provided by the user using the slack-mcp tools
2. **Analyze the conversation** to extract:
   - Symptoms/Problem description
   - Diagnosis/Root cause
   - Resolution steps
   - Any quick reference information (rules, patterns, etc.)
   - Key people to contact for escalation
3. **Ask the user** which subfolder under `/Users/gaurav/Documents/notes/Shopify/Business Platform/Common ATC Issues/` to save the runbook in
4. **Create a well-structured markdown runbook** with:
   - Frontmatter with appropriate tags (`business-platform/atc` and relevant topic tags)
   - Clear sections: Symptoms, Diagnosis, Resolution Steps, Quick Reference, Related
   - Link back to the original Slack thread(s)
   - Actionable, step-by-step instructions
   - Warning callouts for when NOT to proceed

## Template Structure

```markdown
---
service:
  - business_platform
tags:
  - business-platform/atc
  - [relevant-topic-tag]
---
## Symptoms
[What the user sees/experiences]

## Diagnosis
[How to identify the root cause]

## Resolution Steps
[Step-by-step instructions to resolve]

### When NOT to [action]
[Important caveats and escalation paths]

## Quick Reference
[Key rules, patterns, or shortcuts]

## Related
- [Slack thread link]
```

## Notes
- Use the mcp__slack-mcp__slack_get_thread_replies tool to fetch thread content
- Create clear, scannable documentation that ATC can use under pressure
- Include specific internal tool references (BP Internal, etc.)
- Highlight escalation contacts with their Slack IDs when mentioned
