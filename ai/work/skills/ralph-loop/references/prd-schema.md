# PRD YAML Schema Reference

This document provides the complete schema definition for Ralph Loop PRD files.

## File Location

Store PRD files wherever convenient:
- Project root (e.g., `./prd/feature.yaml`)
- Home directory (e.g., `~/.claude/prd/feature.yaml`)
- Any accessible path

## Complete Schema

```yaml
# Required: Project identifier
name: string

# Optional: Human-readable description
description: string

# Optional: Base branch for the stack (default: "main")
base_branch: string

# Optional: Git workflow (default: "vanilla")
# "vanilla" - Use standard git commands
# "graphite" - Use Graphite CLI for stacked PRs
git_workflow: string

# Optional: Branch strategy (default: "independent")
# "independent" - Each task branches from base_branch
# "stacked" - Each task branches from its dependency's branch
branch_strategy: string

# Optional: Global hooks (apply to all tasks unless overridden)
hooks:
  pre_task: string    # Shell command to run before each task
  post_task: string   # Shell command to run after each successful task
  on_complete: string # Shell command when ALL tasks complete successfully
  on_failure: string  # Shell command when a task fails after all retries

# Required: Array of tasks to execute
tasks:
  - # Required: Unique identifier for this task
    id: string

    # Required: Human-readable task name
    name: string

    # Required: Current status
    # Values: "pending" | "in_progress" | "done" | "failed"
    status: string

    # Required: Number of execution attempts (start at 0)
    attempts: integer

    # Required: Maximum retry attempts before marking failed
    max_retries: integer

    # Optional: Working directory for this task
    cwd: string

    # Required: Detailed instructions for Claude
    prompt: string

    # Optional: Conditions to verify task completion
    # Empty array means no validation (trust Claude)
    exit_conditions: array[ExitCondition]

    # Optional: Array of task IDs this task depends on
    depends_on: array[string]

    # Optional: Task-specific hooks (override global hooks)
    hooks:
      pre_task: string
      post_task: string

    # Result object (populated by ralph-loop after completion)
    result:
      branch_name: string | null
      pr_url: string | null

    # Last error message (populated on failure)
    last_error: string | null
```

## Exit Condition Types

Exit conditions define how to verify a task completed successfully.

### Command Condition

Run a shell command and check its exit code:

```yaml
exit_conditions:
  - type: command
    run: "dev test test/models/user_test.rb"
    expect: success  # or "failure" to expect non-zero exit
```

### File Exists Condition

Check if file(s) matching a pattern exist:

```yaml
exit_conditions:
  - type: file_exists
    path: "db/migrate/*_add_preferences.rb"
```

### Branch Pushed Condition

Verify the current branch has been pushed to remote:

```yaml
exit_conditions:
  - type: branch_pushed
```

### Branch Created Condition

Verify a new branch exists locally (different from base):

```yaml
exit_conditions:
  - type: branch_created
```

### Tests Pass Condition

Shorthand for running tests (uses project's test runner):

```yaml
exit_conditions:
  - type: tests_pass
    path: "test/models/"  # Optional: specific path
```

### No Validation

Trust Claude completed the task:

```yaml
exit_conditions: []
```

### Multiple Conditions

All conditions must pass:

```yaml
exit_conditions:
  - type: command
    run: "dev test test/models/feature_test.rb"
    expect: success
  - type: branch_pushed
  - type: file_exists
    path: "app/models/feature.rb"
```

## Hooks

Hooks are shell commands that run at specific lifecycle points.

### Global Hooks

Defined at the top level, apply to all tasks:

```yaml
hooks:
  pre_task: |
    git fetch origin
    echo "Starting task..."

  post_task: |
    echo "Task $TASK_ID completed"

  on_complete: |
    gt submit --stack
    echo "All done!"

  on_failure: |
    echo "Task $TASK_ID failed" | slack-notify
```

### Task-Specific Hooks

Override global hooks for a specific task:

```yaml
tasks:
  - id: special-task
    hooks:
      pre_task: |
        # Custom setup for this task only
        docker-compose up -d
      post_task: |
        docker-compose down
```

### Hook Environment Variables

Hooks have access to:

| Variable | Description |
|----------|-------------|
| `$TASK_ID` | Current task ID |
| `$TASK_NAME` | Current task name |
| `$TASK_STATUS` | Task status after completion |
| `$BRANCH_NAME` | Branch created by task |
| `$PRD_FILE` | Path to the PRD file |
| `$PRD_NAME` | Name from PRD file |
| `$GIT_WORKFLOW` | "vanilla" or "graphite" |
| `$BRANCH_STRATEGY` | "independent" or "stacked" |

### Hook Behavior

- **pre_task**: Runs before Claude starts. If it fails, task is skipped.
- **post_task**: Runs after successful exit conditions. Failure is logged but doesn't fail the task.
- **on_complete**: Runs once when all tasks are done.
- **on_failure**: Runs when a task exhausts all retries.

## Field Reference

### Top-Level Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `name` | string | Yes | - | Project identifier |
| `description` | string | No | - | Human-readable description |
| `base_branch` | string | No | `"main"` | Trunk branch |
| `git_workflow` | string | No | `"vanilla"` | "vanilla" or "graphite" |
| `branch_strategy` | string | No | `"independent"` | "independent" or "stacked" |
| `hooks` | object | No | - | Global hooks |
| `tasks` | array | Yes | - | Task definitions |

### Task Fields

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | string | Yes | - | Unique identifier (kebab-case) |
| `name` | string | Yes | - | Human-readable name |
| `status` | string | Yes | `"pending"` | Execution status |
| `attempts` | integer | Yes | `0` | Attempt counter |
| `max_retries` | integer | Yes | `3` | Max attempts |
| `cwd` | string | No | current dir | Working directory |
| `prompt` | string | Yes | - | Instructions for Claude |
| `exit_conditions` | array | No | `[]` | Completion validation |
| `depends_on` | array | No | `[]` | Dependency task IDs |
| `hooks` | object | No | - | Task-specific hooks |
| `result.branch_name` | string | No | `null` | Created branch |
| `result.pr_url` | string | No | `null` | Created PR URL |
| `last_error` | string | No | `null` | Last error message |

### Status Values

| Status | Description |
|--------|-------------|
| `pending` | Not started or waiting for retry |
| `in_progress` | Currently executing |
| `done` | Completed successfully |
| `failed` | Exceeded max_retries |

## Example: Complete PRD

```yaml
name: add-user-preferences
description: |
  Add user preference storage and API for notification settings.

base_branch: main
git_workflow: vanilla
branch_strategy: stacked

hooks:
  pre_task: |
    git fetch origin
  on_complete: |
    echo "Feature complete! Creating PRs..."
    # User will create PRs manually

tasks:
  - id: db-migration
    name: Add preferences column to users
    status: pending
    attempts: 0
    max_retries: 3
    prompt: |
      Create a migration to add a `preferences` JSONB column to the `users` table.

      Requirements:
      - Default value of `{}`
      - Not nullable
      - Add index for JSON queries
    exit_conditions:
      - type: command
        run: "bin/rails db:migrate:status | grep -q 'up.*add_preferences'"
        expect: success
      - type: file_exists
        path: "db/migrate/*_add_preferences_to_users.rb"
    depends_on: []
    result:
      branch_name: null
      pr_url: null

  - id: model-methods
    name: Add preference methods to User model
    status: pending
    attempts: 0
    max_retries: 3
    prompt: |
      Add methods to the User model:
      - `preference(key)` - get a preference value
      - `set_preference(key, value)` - set a preference
      - `preferences_with_defaults` - all prefs with defaults

      Include unit tests.
    exit_conditions:
      - type: command
        run: "dev test test/models/user_test.rb"
        expect: success
    depends_on:
      - db-migration
    result:
      branch_name: null
      pr_url: null

  - id: api-endpoints
    name: Create preferences REST API
    status: pending
    attempts: 0
    max_retries: 3
    prompt: |
      Create REST endpoints:
      - GET /api/v1/users/:id/preferences
      - PATCH /api/v1/users/:id/preferences

      Include authorization, validation, and integration tests.
    exit_conditions:
      - type: command
        run: "dev test test/controllers/api/v1/preferences_controller_test.rb"
        expect: success
    depends_on:
      - model-methods
    result:
      branch_name: null
      pr_url: null
```

## Modifying a PRD Manually

You can edit the PRD file to:

1. **Skip a task**: Set `status: done`
2. **Retry a failed task**: Set `status: pending`, optionally reset `attempts: 0`
3. **Change exit conditions**: Edit while status is `pending`
4. **Add/modify hooks**: Edit anytime
5. **Increase retries**: Update `max_retries`
