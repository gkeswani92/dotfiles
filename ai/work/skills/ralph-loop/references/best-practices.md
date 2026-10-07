# Best Practices for Stacked PRs

This guide covers effective strategies for breaking down work into stacked pull requests using Ralph Loop.

## Ideal Stack Characteristics

### Size Guidelines

| Stack Size | Recommendation |
|------------|----------------|
| 1 PR | Don't use Ralph Loop; use regular workflow |
| 2-3 PRs | Ideal for most features |
| 4-5 PRs | Good for larger features |
| 6+ PRs | Consider splitting into multiple stacks |
| 10+ PRs | Avoid; conflicts become unmanageable |

### PR Size Within Stack

- **Small**: 50-200 lines changed per PR
- **Focused**: One logical change per PR
- **Reviewable**: Should take <30 minutes to review
- **Deployable**: Each PR could theoretically ship alone

## Breaking Down Work

### The Foundation-First Pattern

Always start with foundational changes:

```
1. Database migrations / schema changes
2. Core domain models and business logic
3. Service layer / use cases
4. API endpoints / controllers
5. UI / presentation layer
6. Integration / E2E tests
```

### Example Breakdown

**Feature**: Add user notification preferences

```yaml
# Good breakdown
tasks:
  - id: migration     # Foundation: schema
  - id: model         # Domain: business logic
  - id: api           # Interface: REST endpoints
  - id: ui            # Presentation: settings page
```

**Not recommended**:
```yaml
# Too fine-grained
tasks:
  - id: create-file
  - id: add-method-1
  - id: add-method-2
  - id: fix-typo
```

### Horizontal vs Vertical Slicing

**Horizontal (by layer)**: Good for infrastructure changes
```
PR 1: All migrations
PR 2: All models
PR 3: All APIs
```

**Vertical (by feature)**: Good for user-facing features
```
PR 1: Feature A (migration + model + API)
PR 2: Feature B (migration + model + API)
```

Ralph Loop typically works best with **horizontal slicing** because:
- Dependencies flow naturally (DB -> Model -> API)
- Each PR is cohesive within its layer
- Easier to review layer-specific changes together

## Writing Effective Prompts

### Structure

```yaml
prompt: |
  ## Context
  Brief background on what exists and why we're making this change.

  ## Objective
  Clear statement of what this PR should accomplish.

  ## Implementation Requirements
  - Specific requirement 1
  - Specific requirement 2

  ## Acceptance Criteria
  - [ ] Testable outcome 1
  - [ ] Testable outcome 2

  ## Reference
  See similar implementation in: app/models/existing_example.rb
```

### Do's and Don'ts

**Do:**
- Reference existing patterns in the codebase
- Include specific file paths when relevant
- Specify test requirements
- Include validation commands (`/validate`)
- Be explicit about edge cases to handle

**Don't:**
- Leave implementation details ambiguous
- Assume Claude knows your conventions
- Skip mentioning testing requirements
- Forget to mention related files

## Managing Dependencies

### Linear Dependencies

Most common pattern:
```yaml
task-a -> task-b -> task-c
```

Each task depends only on the previous one.

### Parallel Branches

For independent work:
```yaml
     task-a
    /      \
task-b    task-c
    \      /
     task-d
```

```yaml
tasks:
  - id: task-a
    depends_on: []
  - id: task-b
    depends_on: [task-a]
  - id: task-c
    depends_on: [task-a]
  - id: task-d
    depends_on: [task-b, task-c]
```

### When to Use Parallel Dependencies

Use parallel dependencies when:
- Tasks are truly independent
- You want to reduce total execution time
- Tasks modify different parts of the codebase

Avoid when:
- Tasks might conflict
- Order matters for testing
- Dependencies aren't clear

## Cross-Repository Work

### Using the `cwd` Field

```yaml
tasks:
  - id: backend-changes
    cwd: /Users/dev/backend-repo
    prompt: |
      Update the backend API...

  - id: frontend-changes
    cwd: /Users/dev/frontend-repo
    depends_on: [backend-changes]
    prompt: |
      Update the frontend to use new API...
```

### Considerations

1. **Each repo needs Graphite**: `gt init` in each
2. **Coordinate base branches**: Ensure compatibility
3. **Consider deployment order**: Backend before frontend
4. **Test integration points**: Include integration tests

## Handling Failures

### Transient Failures

For flaky tests or temporary issues:
- Increase `max_retries` (default: 3)
- Check `last_error` in PRD file
- Let Ralph Loop retry automatically

### Persistent Failures

When a task keeps failing:
1. Read `last_error` for clues
2. Fix the issue manually
3. Either:
   - Set `status: done` if fixed
   - Reset `status: pending` and `attempts: 0` to retry

### Partial Completion

If you need to stop mid-stack:
1. Interrupt Ralph Loop (Ctrl+C)
2. Completed tasks retain `status: done`
3. Current task resets to `pending`
4. Resume by running Ralph Loop again

## Review Strategy

### Per-PR Reviews

- Review each PR as it's created
- Address feedback before next PR runs
- Use `--status` to pause between tasks

### Stack Reviews

- Let entire stack complete
- Review from bottom to top
- Batch feedback for efficiency

## Common Pitfalls

### 1. Overly Granular Tasks

**Problem**: Too many small PRs
**Solution**: Combine related changes into logical units

### 2. Missing Dependencies

**Problem**: Task fails because prerequisite isn't done
**Solution**: Carefully map dependencies before starting

### 3. Vague Prompts

**Problem**: Claude implements something different than expected
**Solution**: Be specific, include examples, reference existing code

### 4. Ignoring Test Failures

**Problem**: Moving forward despite failing tests
**Solution**: Include test requirements in prompts, use `/validate`

### 5. Large PRs in Stack

**Problem**: 1000+ line PRs hard to review/rebase
**Solution**: Break into smaller, focused changes

## Checklist Before Running

Before executing a PRD:

- [ ] All task IDs are unique and descriptive
- [ ] Dependencies form a valid DAG (no cycles)
- [ ] Prompts are specific and include acceptance criteria
- [ ] Base branch is correct
- [ ] Working directories exist (if using `cwd`)
- [ ] Graphite is configured in target repos
- [ ] You have time to monitor initial execution
