---
name: git-context
description: Research git history for context on code changes. Use when investigating why/when code was added.
context: fork
agent: Explore
---

# Git History Research

Use these commands to understand the history and context of code changes.

## Common Commands

```bash
# See who changed what in a file
git blame <file>

# Recent commits touching a file
git log --oneline -20 -- <file>

# Search for when a term was added/removed
git log --all -S "search term" --oneline

# Show details of a specific commit
git show <commit>

# Find commits by message content
git log --grep="search term" --oneline

# Show diff for a specific commit
git diff <commit>^ <commit>
```

## Investigation Patterns

1. **Why was this code added?** - Use `git blame` then `git show <commit>` to see the full context
2. **When did this break?** - Use `git log -S` to find when the problematic code was introduced
3. **What else changed together?** - Use `git show <commit>` to see all files in that commit
4. **Who should I ask?** - Use `git blame` to find the author
