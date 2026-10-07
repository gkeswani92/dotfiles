# Writing Descriptions for Empty Issues

When an issue has only a title with no body or comments, investigate the codebase to write a complete description.

## Workflow

### Step 1: Parse the Issue Title

Extract key information:
- What component/feature is mentioned?
- What action is needed? (fix, implement, review, refactor)
- What specific technical terms or IDs are referenced?

**Example:** "Review dev setup so it sets `shop_channel_publication_id`"
- Component: dev setup
- Action: review (investigate and improve)
- Technical term: `shop_channel_publication_id`

### Step 2: Search the Codebase

Use search tools to understand the context:

```bash
# Search for variable/field names
rg "shop_channel_publication_id" --type-add 'rb:*.rb' -t rb

# Search for related configuration files
rg "dev.*setup" --type yaml --type json

# Look for related test files
rg "shop_channel_publication" --type-add 'spec:*_spec.rb' -t spec
```

For complex issues, use the Task tool with `subagent_type=Explore` to:
- Find all files related to the technical terms
- Understand how the feature currently works
- Identify where dev setup configuration lives
- Discover related documentation or comments

**Gather information about:**
1. **Current state**: How does this feature/field currently work?
2. **Dev setup location**: Where is the dev setup configured?
3. **Related code**: What files interact with this feature?
4. **Existing issues**: Are there related issues or TODOs?
5. **Documentation**: Any comments or docs explaining this?

### Step 3: Understand the Problem

Based on investigation, determine:
- **What's missing?** Is `shop_channel_publication_id` not being set in dev?
- **What's the impact?** Does this cause bugs or make development harder?
- **Why does it matter?** What functionality depends on this?

### Step 4: Write the Description

Structure based on findings:

```markdown
## Description

[Explain what's currently happening in dev setup and why it's a problem]

**Current state:**
- [What the dev setup does now]
- [What's missing or broken]

**Impact:**
- [How this affects developers]
- [What workflows are broken or harder than they should be]

**Context:**
- [Technical details from codebase investigation]
- [Related files: `path/to/file.rb:123`]

## Proposed Solution

[Outline what needs to be investigated or changed]

**Investigation needed:**
1. [Question 1 to answer]
2. [Question 2 to answer]

**Potential approach:**
- [Possible solution based on code patterns found]
- [Configuration changes that might be needed]

**Files to review:**
- `path/to/dev_setup.rb` - [What it does]
- `path/to/publication_config.rb` - [How it's used]

## Additional Context

Code references:
- Current dev setup: `path/to/file.rb:line_number`
- Production setup: `path/to/other_file.rb:line_number`
- Related tests: `path/to/test_file.rb:line_number`
```

### Step 5: Include Code References

Always use `file_path:line_number` format for easy navigation:

> "The `shop_channel_publication_id` is set in production config at `config/publications.rb:45` but missing from dev setup at `lib/dev/setup.rb:120`"

### Step 6: Handle Gaps in Understanding

If critical information is missing:

```markdown
## Open Questions

- [Question 1]: Needs clarification from @author
- [Question 2]: Requires understanding of [system]
```

### Step 7: Update the Issue

Present description for review, then:

```bash
gh issue edit <issue-number> --body "<new-description>"
gh issue comment <issue-number> --body "Added issue description based on codebase investigation. Please review for accuracy."
```
