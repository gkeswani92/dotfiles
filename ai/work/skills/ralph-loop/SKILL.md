---
name: ralph-loop
description: >
  Automates multi-step feature implementation by orchestrating sequential Claude tasks.
  Use when: implementing large features, breaking work into logical steps,
  creating PRD files for automated execution, running ralph-loop orchestrator,
  planning multi-step migrations, or automating sequential Claude tasks.
---

# Ralph Loop - Multi-Step Feature Orchestration

Ralph Loop orchestrates complex feature implementations by breaking them into sequential tasks executed by Claude. It focuses on **solving problems** - PR/branch creation is simply the natural output, not the goal.

## When to Use This Skill

- Implementing large features that need multiple logical steps
- Planning multi-step migrations or refactors
- Breaking complex work into manageable, testable increments
- Automating sequential Claude tasks with dependency management
- Any work too large for a single Claude session

## Interactive Workflow

When a user wants to implement a feature using Ralph Loop, walk them through these phases interactively.

### Phase 1: Problem Discovery

Start by understanding the problem. Ask these questions:

**Scope & Goal:**
- "What feature or problem are you solving?"
- "What will exist when this is complete? Describe the end state."
- "Which repositories or directories will be affected?"

**Complexity Assessment:**
- "Is this a single logical change or multiple related changes?"
- "Are there natural breakpoints (e.g., DB first, then model, then API)?"
- "Do any parts depend on others being completed first?"

### Phase 2: Task Breakdown

Help the user break down their work into logical units:

**Identify Tasks:**
- "Let's break this into 2-5 logical steps. What's the first thing that needs to happen?"
- "What comes next? Does it depend on the first step?"
- "Are there any steps that could theoretically be done in parallel (even though we'll run sequentially)?"

**For each task, capture:**
1. A clear name/description
2. What it produces (files, branches, etc.)
3. What it depends on (previous tasks)
4. Success criteria (how do we know it's done?)

### Phase 3: Git Strategy

Understand how the user wants to manage branches:

**Workflow Questions:**
- "Do you use Graphite CLI or vanilla git?"
- "Should each task create an independent branch from main, or should they stack on each other?"
- "What's your base branch?" (default: main)

**Capture:**
- `git_workflow`: "vanilla" or "graphite"
- `branch_strategy`: "independent" or "stacked"
- `base_branch`: The trunk branch

### Phase 4: Exit Conditions (Per Task)

Each task needs clear exit conditions. Ask:

- "How will we know this task is complete?"
- "Should tests pass? Which ones?"
- "Should a branch be created and pushed?"
- "Any other validation needed?"

**Common exit condition patterns:**
```yaml
# Tests must pass
exit_conditions:
  - type: command
    run: "dev test path/to/test_file.rb"
    expect: success

# File must exist
exit_conditions:
  - type: file_exists
    path: "db/migrate/*_add_feature.rb"

# Branch must be pushed
exit_conditions:
  - type: branch_pushed

# Custom command
exit_conditions:
  - type: command
    run: "grep -q 'class MyFeature' app/models/my_feature.rb"
    expect: success

# No validation (trust Claude)
exit_conditions: []
```

### Phase 5: Hooks Configuration

Hooks are shell commands that run at specific points. Walk through each:

**Pre-task Hook (optional):**
- "Is there anything that should run before each task starts?"
- Examples: `git fetch origin`, `dev up`, custom setup

**Post-task Hook (optional):**
- "After each task completes successfully, should anything run?"
- Examples: notification, logging, custom validation

**Completion Hook (optional):**
- "When ALL tasks complete successfully, what should happen?"
- Examples:
  - `gt submit --stack` (submit Graphite stack)
  - `echo "Done!" | slack-notify`
  - Custom script
  - Nothing (user will handle manually)

**Failure Hook (optional):**
- "If a task fails after all retries, should anything run?"
- Examples: notification, cleanup, alert

### Phase 6: Generate PRD

After gathering all information, generate the PRD YAML file:

```yaml
name: feature-name
description: |
  Brief description of what this PRD accomplishes.

base_branch: main
git_workflow: vanilla  # or "graphite"
branch_strategy: independent  # or "stacked"

# Global hooks (apply to all tasks)
hooks:
  pre_task: |
    # Runs before each task (optional)
    git fetch origin
  post_task: |
    # Runs after each successful task (optional)
    echo "Task completed: $TASK_ID"
  on_complete: |
    # Runs when ALL tasks complete successfully (optional)
    gt submit --stack
  on_failure: |
    # Runs if a task fails after all retries (optional)
    echo "Task $TASK_ID failed" | notify-team

tasks:
  - id: task-1
    name: First task description
    status: pending
    attempts: 0
    max_retries: 3
    cwd: /path/to/repo  # Optional

    prompt: |
      Detailed instructions for Claude...

    exit_conditions:
      - type: command
        run: "dev test test/models/feature_test.rb"
        expect: success
      - type: branch_pushed

    depends_on: []  # No dependencies

    # Task-specific hooks (override global)
    hooks:
      post_task: |
        echo "Custom post-task for task-1"

    result:
      branch_name: null
      pr_url: null

  - id: task-2
    name: Second task description
    status: pending
    attempts: 0
    max_retries: 3

    prompt: |
      Instructions that build on task-1...

    exit_conditions:
      - type: command
        run: "dev test test/integration/"
        expect: success

    depends_on:
      - task-1  # Must complete task-1 first

    result:
      branch_name: null
      pr_url: null
```

**PRD File Location:** Store PRD files wherever convenient (e.g., project root, `~/.claude/prd/`, etc.)

## Exit Condition Types

| Type | Description | Parameters |
|------|-------------|------------|
| `command` | Run a shell command | `run`: command, `expect`: "success" or "failure" |
| `file_exists` | Check if file(s) exist | `path`: glob pattern |
| `branch_pushed` | Verify branch is pushed to remote | (none) |
| `branch_created` | Verify a new branch exists locally | (none) |
| `tests_pass` | Shorthand for running test suite | `path`: test file/dir (optional) |

## Hook Variables

Hooks have access to these environment variables:

| Variable | Description |
|----------|-------------|
| `$TASK_ID` | Current task ID |
| `$TASK_NAME` | Current task name |
| `$TASK_STATUS` | Task status (done, failed) |
| `$BRANCH_NAME` | Branch created by task (if any) |
| `$PRD_FILE` | Path to the PRD file |
| `$PRD_NAME` | Name from PRD file |

## Phase 7: Execution

> **Warning**: The orchestrator runs Claude with full permissions to read/write files, execute commands, and modify git repositories. You will be prompted to confirm before execution begins. Review your PRD file carefully.

```bash
# Locate the script (portable across installations)
RALPH=$(find ~/.claude -name "ralph-loop.sh" -path "*/ralph-loop/*" | head -1)

# Run the orchestrator (will prompt for confirmation)
$RALPH path/to/my-feature.yaml

# Skip confirmation prompt (use with caution)
$RALPH --yes path/to/my-feature.yaml

# Check status only (no confirmation needed)
$RALPH --status path/to/my-feature.yaml

# View completed work
$RALPH --stack path/to/my-feature.yaml
```

## Example: Interactive Session

Here's how a conversation might flow:

**User:** I need to add a new notification preferences feature to our app.

**Assistant:** Let me help you break this down into tasks for Ralph Loop.

**1. What's the end goal?**
When complete, users should be able to set their notification preferences via an API, and the system should respect those preferences when sending notifications.

**2. What are the natural steps?**
- Database migration to add preferences column
- Model methods to manage preferences
- API endpoints to get/set preferences
- Update notification service to check preferences

**3. Git strategy?**
- Using vanilla git
- Independent branches (each PR targets main)
- Base branch: main

**4. Exit conditions for each task?**
- Task 1 (migration): Migration runs successfully
- Task 2 (model): Model tests pass
- Task 3 (API): Integration tests pass
- Task 4 (service): All tests pass

**5. Completion hook?**
- None - user will create PRs manually

*[Assistant generates PRD file]*

## Stacked Branch Requirements

When using `branch_strategy: stacked`:

- Each task's `depends_on` defines the parent branch
- The task MUST wait for the parent to have a `branch_name` in its result
- The orchestrator checks out the parent branch before starting
- For Graphite: uses `gt create` to maintain stack
- For vanilla git: uses `git checkout -b` from parent

## Best Practices

### Task Granularity
- **2-5 tasks** - Ideal for most features
- **1 task** - Don't use Ralph Loop; do it directly
- **10+ tasks** - Consider splitting into multiple PRDs

### Exit Conditions
- Be specific about what "done" means
- Include tests when they exist
- Trust Claude for exploratory/creative tasks (use `[]`)

### Hooks
- Keep hooks simple and fast
- Use for notifications, not complex logic
- Test hooks manually before relying on them

### Prompts
- Focus on **what to implement**, not git mechanics
- Include acceptance criteria
- Reference existing patterns in the codebase
- Let the orchestrator handle branching

## Troubleshooting

### Task Keeps Failing
- Check `last_error` in PRD file
- Review exit conditions - are they too strict?
- Increase `max_retries` if transient
- Manually fix and set status to `done`

### Exit Condition Fails But Task Looks Done
- The condition might be wrong - review it
- Run the condition command manually to debug
- Set `exit_conditions: []` to skip validation

### Hook Fails
- Hooks failing don't fail the task
- Check hook output in logs
- Test hook command manually

## References

For detailed documentation, see:
- `references/prd-schema.md` - Complete PRD schema with hooks
- `references/git-workflows.md` - Git workflow options
- `references/best-practices.md` - Tips for effective task breakdown
- `templates/prd-template.yaml` - Starter template
