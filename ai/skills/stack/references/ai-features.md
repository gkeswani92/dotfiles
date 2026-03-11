# AI Features

This document covers Graphite's AI-powered features: AI Reviews, Graphite Chat, and Background Agents.

## AI Reviews (Graphite Agent)

### Overview

Graphite Agent automatically analyzes pull requests to identify potential bugs and issues before they reach production. It provides instant, actionable feedback without manual configuration.

### Issue Categories

**Logic Bugs**
- Functions that don't accomplish what they're named to do
- Implementation mismatches with documentation
- Off-by-one errors
- Inconsistent behavior across code paths

**Edge Cases**
- Missing null checks or error handling
- Race conditions in asynchronous code
- Memory leaks
- Unhandled failure modes

**Security Vulnerabilities**
- SQL injection vulnerabilities
- Cross-site scripting (XSS) opportunities
- Authorization bypass possibilities
- Weak cryptography
- Credential exposure

**Performance Issues**
- Inefficient algorithms or data structures
- Unnecessary API calls or database queries
- N+1 query patterns
- Unnecessary operations

**Accidentally Committed Code**
- Debug statements and console logs
- Test data and development configurations
- Temporary workarounds
- Commented-out code

### Comment Structure

Each AI review comment includes:
1. Problem description
2. Explanation of significance
3. Concrete fix suggestion

### Setup

1. Navigate to AI code review settings page
2. Select repositories for AI review
3. Click Save
4. Graphite Agent immediately reviews new PRs

### PR Status Indicators

| Status | Description |
|--------|-------------|
| Running | Analysis in progress |
| Completed | Review finished, comments added if applicable |
| Not running | PR exceeds 100,000 characters |

## AI Review Customization

### Exclusions

Prevent AI comments in specific situations:

- **Generated code**: Skip build artifacts and schemas
- **Specific comment types**: Disable irrelevant feedback categories
- **Repositories/directories**: Focus reviews where they matter
- **Pattern matching**: Exclude team-specific conventions

**Best Practice**: Make exclusion language as targeted as possible. Overly broad exclusions like "Don't suggest performance improvements" are ineffective.

### File Exclusion via .gitattributes

Mark generated files to exclude from analysis:

```gitattributes
docs/data.txt linguist-generated=true
*.csv linguist-generated=true
data/** linguist-generated=true
```

Files collapse in GitHub PRs and skip AI review.

### Custom Rules

Two approaches:

**Custom Prompts (Recommended)**
- Rules written in Graphite UI
- Support templates for language-specific guides
- Fast iteration with performance feedback
- Centralized management across repositories

**File-Based Rules**
- Reference repository documentation via glob patterns
- Example: `docs/coding-standards.md`
- Best for frequently-updated team resources
- Limitation: Large files are truncated

**Effective Rule Structure:**
```
Rule → Bad example → Good example → Reasoning
```

**Avoid in Rules:**
- Vague language ("write good code")
- Non-prescriptive verbs ("comment on," "flag")
- Unnecessary context or praise
- Mixing rules with exclusions

**Focus Rules On:**
- Language-specific conventions
- Security guidelines
- Framework patterns

### PR-Level Filtering

Control which PRs receive AI reviews based on:

| Filter | Description |
|--------|-------------|
| PR author | Specific users or teams |
| File paths | Modified file patterns |
| GitHub labels | Specific labels |
| PR title/description | Text content matching |
| Target branch | Branch naming patterns |

### Dashboard & Metrics

**Overview Tab:**
- Issues identified (by category)
- Acceptance rates
- Pull requests reviewed
- Downvote feedback tracking
- Filter by time period and repository

**Comment Feed Tab:**
- View all comments
- Issue categorization
- Code snippets and inline explanations
- Potential impact assessment

**Rules & Exclusions Tab:**
- Issues found per rule
- PRs analyzed
- Acceptance rates
- Upvote/downvote feedback

### Privacy & Security

- Opt-in features; data excluded by default
- User approval required before sending data to AI
- Zero model training on user data
- Subprocessors: Anthropic and OpenAI (explicit non-training agreements)
- Data sent: PR metadata, changed code, related codebase sections

## Graphite Chat

### Overview

AI-powered conversational assistant integrated into Graphite's PR review interface. Interact with "Graphite Agent" via a panel on the right side of PR review pages.

### Capabilities

**Code Understanding & Context**
- Request PR summaries
- Identify potential issues
- Get explanations of specific code sections
- Highlight lines in diffs for targeted questions

**Direct Code Editing**
- Propose specific fixes applied with one click
- Type error corrections
- Error handling additions
- Query optimizations
- Test generation

**Codebase Search & Discovery**
- Locate related files
- Identify where APIs are used elsewhere
- Show similar implementations
- Provide context from other PRs

**Feedback Implementation**
- Understand and implement reviewer comments
- Explore tradeoffs in suggested approaches
- Work through requested changes

**CI Debugging**
- Diagnose failing checks
- Resolve issues directly from PR page
- Full CI context awareness

### Technical Advantages

Unlike generic AI tools, Graphite Agent maintains awareness of:
- Entire codebase
- PR stack history
- CI failures
- Reviewer comments
- Team coding patterns

All edits tracked in version control as standard commits.

## Background Agents

### Overview

Describe what you want built or fixed in plain language. Graphite spins up a remote sandbox to write code, run tests, and open a PR for review.

### Use Cases

- **Quick fixes on the go**: Push changes from phone/browser without cloning repos
- **Generate boilerplate**: Scaffold features, add API endpoints, write SQL queries
- **Add tests**: Expand coverage without context-switching
- **Delegate repetitive tasks**: Review output in Graphite's PR interface

### Setup

1. Navigate to Preferences → Background Agents
2. Enable the feature
3. Open Background Agents page (🪄 icon) in sidebar
4. Select repository and enter task description
5. Click Submit
6. Graphite runs agent and opens draft PR when complete

### Pricing

- **Free tier**: $10 usage credit
- **Unlimited**: Bring your own Claude API key

### Privacy & Security

| Aspect | Details |
|--------|---------|
| Data Retention | Zero retention agreements with model providers |
| Model Training | Never trains on user code |
| Execution | Isolated, ephemeral sandboxes |
| Access | Only specified repositories |
| Cleanup | Sandboxes destroyed after completion |

**Two Usage Models:**

1. **Graphite-managed credits**: Covered under Graphite's privacy terms
2. **Bring-your-own API key**: Governed by direct agreements with provider (e.g., Anthropic)

## GT MCP Integration

### Overview

Enable AI agents to automatically create stacked PRs by breaking large AI-generated changes into smaller, reviewable PRs.

### Benefits

- **Better code review**: Large AI diffs become manageable stacked PRs
- **Chronological reasoning**: Agents validate each step sequentially
- **Improved clarity**: Changes presented in logical order

### Requirements

CLI version 1.6.7 or later:

```bash
# Update via Homebrew
brew update && brew upgrade withgraphite/tap/graphite

# Update via npm
npm install -g @withgraphite/graphite-cli@stable
```

### Claude Code Setup

```bash
claude mcp add graphite gt mcp
```

### Cursor Setup

Add to Cursor settings (Tools & Integrations):

```json
{
  "mcpServers": {
    "graphite": {
      "command": "gt",
      "args": ["mcp"]
    }
  }
}
```

### Usage

Once configured, AI agents can:
- Create stacked PRs from large changes
- Break work into logical increments
- Submit stacks for review automatically

### Status

GT MCP is currently in beta. Some workflows may lack full support.

## Experimental Comments

### Feedback Mechanism

Use thumbs up/down reactions on AI comments:
- Upvote: Helpful, accurate feedback
- Downvote: Provides detailed feedback popup

Team reviews feedback to improve Graphite Agent accuracy.

### Iteration Loop

1. AI makes comment
2. Developer votes
3. Downvotes provide specific feedback
4. Graphite improves Agent based on patterns
5. Better comments in future reviews
