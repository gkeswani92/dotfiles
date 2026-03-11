---
name: writing-pr-descriptions
description: Guidelines for writing clear, comprehensive PR descriptions
---

# Writing PR Descriptions

## Structure

```markdown
## Summary
Brief description of what this PR does and why.

## Changes
- Bullet points of specific changes made
- Group related changes together

## Testing
How was this tested? Include:
- Manual testing steps
- New/updated tests
- Edge cases considered

## Screenshots (if applicable)
Before/after screenshots for UI changes.

## Notes for Reviewers
- Areas that need extra attention
- Questions or concerns
- Related PRs or dependencies
```

## Good Practices

1. **Start with "why"** - Context helps reviewers understand the motivation
2. **Link related issues** - Reference GitHub issues, Slack threads, or docs
3. **Keep it scannable** - Use bullet points and headers
4. **Highlight risks** - Call out areas that might need extra scrutiny
5. **Include test plan** - How can reviewers verify the change works?

## What to Avoid

- Vague summaries like "Fix bug" or "Update code"
- Missing context that forces reviewers to ask questions
- Huge PRs without clear breakdown of changes
- Screenshots without explanation of what changed
