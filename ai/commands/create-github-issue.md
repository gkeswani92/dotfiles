# Create GitHub Issue

You are creating a GitHub issue based on the current conversation context.

## IMPORTANT: Command execution rules

- **Use simple, single-purpose commands.** Each `gh` or `gh api` call should do ONE thing. Do NOT chain commands with `&&`, `|`, `$()` substitution, or compound expressions.
- **Extract values into variables in separate commands.** For example, first run `gh api ...` to get a node ID, then use it in the next command. Do NOT nest commands.
- **Run independent commands in parallel** using multiple Bash tool calls in the same message. Only sequence commands that depend on each other's output.
- This avoids triggering permission prompts for compound commands and makes debugging easier.

## Step 1: Generate title and description

The user's prompt about what the issue should cover: $ARGUMENTS

Using the conversation context and the user's prompt above, draft a clear issue title and a markdown description. Show the draft to the user for approval or edits before proceeding. The description should include relevant context from the conversation — what was investigated, what was found, what needs to happen next. Keep it concise and actionable.

## Step 2: Gather metadata — Round 1

Use AskUserQuestion to ask these 4 questions in a single call:

1. **Repo** (header: "Repo") — Options:
   - "shop/issues-organizations" (label, description: "Organizations issues repo (Recommended)")
   - "shop/world" (label, description: "World monorepo")

2. **Workstream** (header: "Workstream") — Options:
   - "Legal Entities" (label, description: "Legal entities work (Recommended)")
   - "Direct Access" (label, description: "Direct access work")
   - "Test Drive" (label, description: "Test Drive work")
   - "Maintenance" (label, description: "General maintenance")

3. **Status** (header: "Status") — Options:
   - "Ready for development" (label, description: "Ready to be picked up (Recommended)")
   - "Blocked" (label, description: "Blocked on something")
   - "In Progress" (label, description: "Already being worked on")

4. **Type** (header: "Type") — Options:
   - "Task" (label, description: "Standard task (Recommended)")
   - "Bug" (label, description: "Bug fix")
   - "Epic" (label, description: "Epic / larger initiative")

## Step 3: Gather metadata — Round 2

First, fetch milestones from the repo:
```bash
gh api repos/<repo>/milestones --jq '.[].title'
```

Then use AskUserQuestion to ask up to 3 questions:

1. **Milestone** (header: "Milestone") — Build options from fetched milestones plus a "None" option. Default to "None".

2. **Priority** (header: "Priority") — Options:
   - "None" (label, description: "No priority set (Recommended)")
   - "P0" (label, description: "Critical priority")
   - "P1" (label, description: "High priority")
   - "P2" (label, description: "Medium priority")

3. **Parent issue** (header: "Parent") — Options:
   - "None" (label, description: "No parent issue (Recommended)")
   - "Specify issue" (label, description: "Link as sub-issue to a parent")

If user selects "Specify issue" for parent, ask them for the issue number or URL.

## Step 4: Create the issue

Create the issue with `gh issue create`. Do NOT use `--label` for the type — issue types are set separately via GraphQL.
```bash
gh issue create --repo <repo> --title "<title>" --body "<body>" [--milestone "<milestone>"]
```

Then set the issue type via GraphQL (Bug, Task, Epic, etc.). The `--type` flag does NOT exist on `gh issue create/edit`.

**Issue Type IDs** (for shop/issues-organizations):

| Type | ID |
|------|----|
| Task | `IT_kwDOCq3Ses4BY4Wy` |
| Bug | `IT_kwDOCq3Ses4BY4Wz` |
| Feature | `IT_kwDOCq3Ses4BY4W0` |
| Epic | `IT_kwDOCq3Ses4BikDl` |

```bash
# First, get the issue node ID (run this as a separate command)
gh api repos/<repo>/issues/<number> --jq '.node_id'

# Then set the type (separate command, using the node ID from above)
gh api graphql -f query='
mutation {
  updateIssue(input: {
    id: "<issue_node_id>",
    issueTypeId: "<type_id>"
  }) {
    issue { id issueType { name } }
  }
}'
```

## Step 5: Add to "Organizations Overall" project and set fields

Use the following hardcoded reference data:

**Project**: Organizations Overall (number: 409, ID: `PVT_kwDOCq3Ses4A5-nV`)

**Field IDs and option IDs:**

| Field | Field ID | Options |
|-------|----------|---------|
| Status | `PVTSSF_lADOCq3Ses4A5-nVzgurwJY` | Blocked=`bc0ab4a5`, Ready for development=`16e13879`, In Progress=`47fc9ee4`, In Review=`34ff4041`, Done=`98236657` |
| Priority | `PVTSSF_lADOCq3Ses4A5-nVzgurwuQ` | P0=`18598473`, P1=`b0397fdf`, P2=`f5d442ee` |
| Workstream | `PVTSSF_lADOCq3Ses4A5-nVzgu8cXs` | Legal Entities=`815946b7`, Direct Access=`3265981f`, Test Drive=`694efedb`, Maintenance=`ed6779a7`, IDV=`c6cd1a95`, Destinations=`beaf043d`, BP to Core=`a0b6b6ba` |

Run each of these as **separate Bash tool calls**. The first must complete before the rest (to get the item ID). The field-setting commands are independent of each other and can run in parallel.

```bash
# Step 5a: Add to project (must run first — extract item_id from JSON output)
gh project item-add 409 --owner shop --url <issue_url> --format json
```

Then, using the `id` field from the JSON output above, run these in parallel:

```bash
# Step 5b: Set Status field
gh project item-edit --project-id PVT_kwDOCq3Ses4A5-nV --id <item_id> \
  --field-id PVTSSF_lADOCq3Ses4A5-nVzgurwJY --single-select-option-id <status_option_id>
```

```bash
# Step 5c: Set Workstream field
gh project item-edit --project-id PVT_kwDOCq3Ses4A5-nV --id <item_id> \
  --field-id PVTSSF_lADOCq3Ses4A5-nVzgu8cXs --single-select-option-id <workstream_option_id>
```

```bash
# Step 5d: Set Priority field (only if not "None")
gh project item-edit --project-id PVT_kwDOCq3Ses4A5-nV --id <item_id> \
  --field-id PVTSSF_lADOCq3Ses4A5-nVzgurwuQ --single-select-option-id <priority_option_id>
```

## Step 6: Link as sub-issue (if parent specified)

If the user specified a parent issue, link the new issue as a sub-issue:

Run these as separate commands. Get both node IDs first (can run in parallel), then link.

```bash
# Step 6a: Get parent issue node ID
gh api repos/<repo>/issues/<parent_number> --jq '.node_id'
```

```bash
# Step 6b: Get new issue node ID (can run in parallel with 6a)
gh api repos/<repo>/issues/<new_issue_number> --jq '.node_id'
```

```bash
# Step 6c: Link as sub-issue (after 6a and 6b complete)
gh api graphql -f query='
mutation {
  addSubIssue(input: {
    issueId: "<parent_issue_node_id>",
    subIssueId: "<new_issue_node_id>"
  }) {
    issue { id }
    subIssue { id }
  }
}'
```

## Step 7: Output

Print a summary:
- Issue URL
- Title
- Repo, Workstream, Status, Type, Priority, Milestone
- Parent issue (if linked)
- Project: Organizations Overall
