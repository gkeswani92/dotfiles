---
name: update-memory
description: Update CLAUDE.md with user preferences learned from conversation
context: fork
disable-model-invocation: true
agent: general-purpose
---

# Update Memory

Review feedback, preferences, or rules from the conversation and update CLAUDE.md.

## Guidelines

1. Read the current CLAUDE.md first
2. Identify preferences/rules that should persist across sessions
3. Add to the appropriate section, or create a new section
4. Keep CLAUDE.md concise - move detailed guidance to skills
5. Don't duplicate what's already captured in skills

## What to Capture

- Code style preferences the user has expressed
- Workflow preferences (e.g., "always run tests before committing")
- Things the user repeatedly corrects
- Project-specific conventions
- "Always do X" or "Never do Y" instructions
- Tool preferences (e.g., preferred test runner, linter settings)

## What NOT to Capture

- One-time instructions for a specific task
- Information already in project documentation
- Temporary preferences or experiments
- Sensitive information (API keys, passwords)

## Format

Add new preferences under a clear heading:

```markdown
## Code Style Preferences

- Prefer `let!` over `let` in RSpec when the object must exist
- Use descriptive variable names over abbreviations
```
