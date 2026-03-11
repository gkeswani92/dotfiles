---
name: stack
description: Use when planning or implementing any code changes. Covers feature flag strategy, stack structure, PR breakdown, and all VCS operations via Graphite CLI (gt). Triggers on plan, implement, feature, task, commit, PR, pull request, branch, stack, flag, gt commands.
---

# Graphite Workflow Guide

This is the authoritative guide for using Graphite CLI (`gt`) to build and manage stacked PRs. **Follow this file for all standard workflows.** The `references/` files are for edge cases, advanced options, and going off the beaten path.

## Terminology

- **Stack:** A chain of dependent branches/PRs, each building on the previous
- **Downstack:** Branches closer to trunk (`main`)—these are the *parents*
- **Upstack:** Branches further from trunk—these are the *children*

```
main (trunk)
 └── auth-api       ← downstack (parent)
      └── auth-ui   ← current branch
           └── auth-tests  ← upstack (child)
```

---

## Golden Rules

**These rules are non-negotiable:**

1. **Assume no VCS permissions.** Do not commit, push, or create PRs unless the user explicitly asks. If your plan involves making PRs, confirm with the user before starting.

2. **Never use raw git commands that modify state.** No `git commit`, `git push`, `git fetch`, `git rebase`, `git reset`, etc. Use `gt` commands instead.

3. **Confirm for non-Graphite repos.** If a project doesn't use Graphite but the user wants commits/PRs, confirm: "This appears to be a plain GitHub repo without Graphite—shall I use standard git commands?"

4. **Announce VCS actions before executing.** When about to perform a sequence of VCS operations (staging, creating branches, submitting), explain the full sequence upfront in one brief sentence. For example:
   - "I'll stage the changes, create a new branch with a commit, then submit to Graphite."
   - "I'll stage these changes, use absorb to distribute them across the stack, then submit."

   Don't narrate each individual step—just give the overview, then execute.

5. **Decide branch strategy before making changes.** When fixing bugs or making changes to existing code, first determine which branch(es) need modification and how you'll get there. Before writing any code or running any commands:
   - Check your current position in the stack (`gt info`, `gt log short --stack --no-interactive`)
   - Identify which PR/branch the change belongs in
   - Decide: stay here and use `gt absorb`, or checkout the target branch first?

   State your approach, then proceed.

---

## When Planning Work

Before writing code, determine:

1. **Feature flag?** Most work should be behind a flag. If yes, confirm the flag name with the user (see [Feature Flag Pattern](#feature-flag-pattern)).

2. **Stack structure?** Will this be one PR or multiple? If multiple, what's in each PR? Propose the stack structure in your plan:
   ```
   PR 1: Add API endpoint (behind f_feature_name)
   PR 2: Add UI components (behind f_feature_name)
   PR 3: Remove feature flag (blocked until 100%)
   ```

3. **Review strategy?** Different PRs may need different reviewers. Note this in the plan if relevant.

---

## Key Command Distinction

**This is critical to get right:**

| Situation | Command | What it does |
|-----------|---------|--------------|
| On an **untracked** branch, need to start tracking | `gt create --message "<commit message>"` | Creates a new tracked branch with a commit |
| On a **tracked** branch, need to add changes | `gt modify --commit --message "<commit message>"` | Adds a commit to the current tracked branch |

- `gt create` = make a NEW tracked branch (with a commit)
- `gt modify` = change an EXISTING tracked branch

If you use `gt modify` on an untracked branch, it will fail. If you use `gt create` when you meant to add to the current branch, you'll create an unwanted new branch.

For full options (`--all`, `--patch`, `--insert`, `--no-verify`), see [references/commands.md](references/commands.md#branch-creation--modification).

---

## Commit Messages

1. **First line:** Short summary of what the commit does
2. **Blank line**
3. **Body:** Broader context—why the change was made, what it affects

```
Add validation for user email addresses

The signup form was accepting malformed emails which caused
downstream issues in the notification service. This adds
client-side validation matching the server-side rules.
```

**Full CI runs:** Prefix the first line with `[ci full]` to trigger a complete, non-selective CI run. This is rarely needed—the selective CI logic is reliable.

---

## Before You Start

### Check tracking status

Before doing any work, verify the branch state:

```bash
gt info              # Is this branch tracked by Graphite?
gt trunk             # Confirm trunk branch (usually main)
```

### Worktrees

New worktrees often have an untracked branch. When starting work in a fresh worktree:

```bash
gt track --parent main   # Track the current branch with main as parent
```

### Error Recovery

| Error | Cause | Fix |
|-------|-------|-----|
| "stale" on submit | Downstack out of sync | `gt get` then retry |
| `gt modify` fails "not tracked" | Branch not in Graphite | `gt track --parent <parent>` |
| Merge conflicts during restack | Upstack conflicts with changes | Resolve files, `git add`, `gt continue` ([details](references/stacking-workflows.md#resolving-restack-conflicts)) |
| Created wrong branch | Used `gt create` instead of `gt modify` | `gt undo`, then use correct command |
| Wrong parent branch | Stack structure incorrect | `gt move --onto <correct-parent>` |

---

## Modality 1: Building a Stack

Use this workflow when creating new PRs—whether a single PR or a multi-PR stack.

### Starting the first PR

```bash
# 1. Do your work (write code, make changes)

# 2. Stage changes via git
git add <files>

# 3. Create tracked branch with commit
gt create --message "<commit message>"
```

### Submitting

```bash
gt submit --stack --publish --cli
```

- `--stack` — submits the entire stack (current branch and all upstack). **Required when you have multiple PRs in your stack.**
- `--publish` — marks PR as ready for review (use `--draft` if preferred)
- `--cli` — non-interactive mode

**If submit fails with "stale" error:** Run `gt get` first to sync downstack branches, then retry submit. `gt get` is always safe to run but may be unnecessary overhead.

### Managing draft status

The `--draft` and `--publish` flags only apply when **creating** PRs. To change the status of **existing** PRs, use the `gh` CLI:

```bash
gh pr ready --undo <PR>   # Convert to draft
gh pr ready <PR>          # Mark as ready for review
```

### After submit: Polish the PR

Use `gh` CLI to refine the PR immediately after creation:

```bash
gh pr edit ...
```

### Stacking another PR on top

After the first PR is submitted:

```bash
# 1. Do the next piece of work

# 2. Stage changes
git add <files>

# 3. Create new branch stacked on current (which becomes parent)
gt create --message "<commit message>"

# 4. Submit
gt submit --stack --publish --cli
```

Repeat for each PR in the stack. **Submit incrementally** as each PR is completed—don't wait until all code is written.

---

## Modality 2: Modifying a Single PR

Use this when making changes to one specific PR in an existing stack.

### Simple case: You're already on the right branch

```bash
# 1. Make your changes

# 2. Stage
git add <files>

# 3. Add a new commit to this branch
gt modify --commit --message "<commit message>"

# 4. Submit
gt submit --stack --publish --cli
```

### Modifying a downstack PR

**Choose your approach:**

| Situation | Use | Why |
|-----------|-----|-----|
| Lines to change exist in current branch | `gt absorb` | Changes distribute to original commits |
| Lines were modified/deleted by upstack | Checkout + `gt modify` | Must edit where lines actually exist |
| Unsure | Try `gt absorb --dry-run` first | Shows where changes would go |

**Approach 1: Checkout and modify (safe fallback)**

```bash
gt checkout <branch-name>
git add <files>
gt modify --commit --message "<commit message>"
gt top
gt submit --stack --publish --cli
```

**Approach 2: Absorb (when code is present upstack)**

```bash
# Stay on current branch
git add <files>
gt absorb --dry-run        # Preview distribution
gt absorb --force          # Apply if correct
gt submit --stack --publish --cli
```

If `gt absorb --dry-run` shows unexpected distribution, use Approach 1 instead. See [references/stacking-workflows.md#absorb-workflow](references/stacking-workflows.md#absorb-workflow) for more on how absorb distributes changes.

---

## Modality 3: Working Across the Stack

Use this for tasks that span multiple PRs—navigating, understanding structure, or coordinating changes.

### Understanding your position

```bash
gt info                              # Current branch details
gt log short --stack --no-interactive  # Visual stack overview
```

### Navigation

```bash
gt checkout <branch>   # Jump to specific branch
gt up / gt down        # Move one branch up/down
gt top / gt bottom     # Jump to stack endpoints
```

For aliases (`gt co`, `gt u`, `gt d`, `gt t`, `gt b`) and stepping multiple branches, see [references/commands.md#branch-navigation](references/commands.md#branch-navigation).

### Common cross-stack patterns

For advanced stack reorganisation (`gt split`, `gt fold`, `gt reorder`, `gt move --insert`), see [references/stacking-workflows.md#advanced-patterns](references/stacking-workflows.md#advanced-patterns).

**Introducing something downstack, cleaning up upstack:**

This is the feature flag pattern (see below). Introduce the flag-protected code in lower PRs, then add a cleanup PR at the top that removes the flag.

**Updating PR metadata across the stack:**

Use `gh` CLI for bulk updates:

```bash
gh pr edit ...
```

### After `gt get`

When you sync downstack, changes to base PRs may require:

- `dev up` — update dependencies, run migrations
- You'll discover this through errors when running tests

For collaboration patterns (working on someone else's stack, `gt freeze`, multiple developers), see [references/stacking-workflows.md#collaboration-patterns](references/stacking-workflows.md#collaboration-patterns).

---

## PR Quality Standards

For guidance on structuring stacks (by layer, component, risk, review speed) and PR size targets, see [references/best-practices.md](references/best-practices.md#stack-structure-frameworks).

### Titles

For related PRs in a stack, prefix with a short theme identifier:

```
[#auth] Add authentication API
[#auth] Add login UI components
[#auth] Remove feature flag
```

Keep themes short and flexible—just enough to visually group related PRs.

### Descriptions

**Progressive disclosure.** Assume the reader loses interest quickly:

1. **First 1-2 sentences:** The essential "what and why"
2. **Next paragraph:** Important context
3. **Details section:** Use `<details><summary>` for extensive content

**Blockers first.** Always highlight warnings/blockers at the very top:

```markdown
> [!WARNING]
> - [ ] PR was generated by AI—<@github username> has reviewed it
> - Do not merge until `f_user_auth` flag is at 100%
> - Do not merge until PR below is deployed
```

**Rich formatting:**

- Use tables for comparisons, option lists
- Use GitHub warning/note boxes for callouts
- Use diagrams when they aid understanding (see below)

**Diagrams:**

| Type | Tool | Good for |
|------|------|----------|
| Simple | Inline Mermaid | Flow charts, decision trees, simple sequence diagrams |
| Complex | `/diagram` skill | Architecture, better aesthetics, formatting control |

Delegate diagram generation to a subagent—don't bloat the main conversation with rendering.

---

## Feature Flag Pattern

Most work should be protected by feature flags. This typically means **2+ PRs**:

1. **Feature PRs:** Introduce functionality behind the flag
2. **Cleanup PR (top of stack):** Remove flag references, blocked until 100% rollout

### Flag types

- **Shop-based:** Flag membership driven by shop
- **App-based:** Flag membership driven by app
- **Subject-less:** Global on/off

### Flag naming

If no flag is specified, suggest one in the plan:

```
f_<snake_case_feature_name>
```

Example: `f_user_auth_flow`, `f_checkout_v2`

The user confirms the flag name before work begins.

### Stack structure with flags

```
main
 └── [#auth] Add auth API (behind f_user_auth)
      └── [#auth] Add login UI (behind f_user_auth)
           └── [#auth] Remove f_user_auth flag
                ↑ Blocked: "Do not merge until f_user_auth is at 100%"
```

---

## Quick Command Reference

| Task | Command |
|------|---------|
| Check if tracked | `gt info` |
| Track new branch | `gt track --parent main` |
| Create stacked branch | `gt create --message "<commit message>"` |
| Add commit to branch | `gt modify --commit --message "<commit message>"` |
| Amend last commit | `gt modify --all` |
| Distribute changes | `gt absorb --dry-run` then `gt absorb --force` |
| Sync downstack | `gt get` |
| Submit stack | `gt submit --stack --publish --cli` |
| Update and submit | `gt get && gt submit --stack --publish --cli` |
| View stack | `gt log short --stack --no-interactive` |
| Navigate | `gt checkout`, `gt up`, `gt down`, `gt top`, `gt bottom` |

---

## Reference

**Consult these when going beyond standard workflows:**

| When you need... | Consult |
|------------------|---------|
| Full command options, aliases, flags | [references/commands.md](references/commands.md) |
| Split, fold, reorder, insert, collaboration | [references/stacking-workflows.md](references/stacking-workflows.md) |
| Stack structure frameworks, PR sizing, anti-patterns | [references/best-practices.md](references/best-practices.md) |
| Monorepo performance, merge queue, web features | [references/graphite-reference.md](references/graphite-reference.md) |
