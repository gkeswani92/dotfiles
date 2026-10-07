# Reference: GitHub + Graphite (legacy)

> Load this only when [SKILL.md](../SKILL.md) has established that the stack lives on
> **GitHub/Graphite**. This surface is being deprecated in favour of Gitstream, but it remains
> the source of truth for existing branches and PRs. Do not migrate a stack between surfaces
> without the user asking.

PR data lives on GitHub; stack topology lives in Graphite (`gt`); PR edits go through `gh`.

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

2. **Never default to raw git commands that modify state.** No `git commit`, `git push`, `git fetch`, `git rebase`, `git reset`, etc. Use `gt` commands instead.

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

6. **Never trigger CI before Gitstream mirroring is complete.** After any push/submit, CI runs against the Gitstream-mirrored commit. If you trigger CI (`devx ci run`, `devx ci merge-when-ready`, etc.) before the mirror has settled, CI may run against a stale commit or fail to find the commit at all. Before *any* CI command, verify the branch is mirrored (see [Verify mirroring before triggering CI](#verify-mirroring-before-triggering-ci)). If it is not mirrored, **stop**—do not run CI. Wait and re-check, or surface the problem to the user.

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

For full options (`--all`, `--patch`, `--insert`, `--no-verify`), run `gt create --help` / `gt modify --help`.

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

### Check gitstream syncing

Shopify uses github as a mirror to an internal "gitstream" service. It is mandatory to run **both** of these commands for live context:

```bash
dev gitstream info
dev gitstream --help
```

### Worktrees

New worktrees often have an untracked branch. When starting work in a fresh worktree:

```bash
gt track --parent main   # Track the current branch with main as parent
```

### Gather context from existing PRs

When working with existing PRs (fixing issues, reorganising stacks, follow-ups, etc.), load the PR description before making changes:

```bash
gh pr view <PR> --repo <owner/repo> --json body,title,url
```

If the description references a GitHub issue (e.g. "Closes #123", "Fixes #456"), follow the link and load the issue too. Issues are often in a different repo from the PR:

```bash
gh issue view <number> --repo <owner/repo> --json body,title,url
```

PR descriptions and linked issues often carry essential context about intent, requirements, and constraints that isn't visible in the code alone. Don't skip this step—it prevents misunderstanding the purpose of the work.

### Error Recovery

| Error | Cause | Fix |
|-------|-------|-----|
| "stale" on submit | Downstack out of sync | `gt get` then retry |
| `gt modify` fails "not tracked" | Branch not in Graphite | `gt track --parent <parent>` |
| Merge conflicts during restack | Upstack conflicts with changes | Resolve files, `git add`, `gt continue` |
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
gt submit --stack --draft --cli
```

- `--stack` — submits the entire stack (current branch and all upstack). **Required when you have multiple PRs in your stack.**
- `--draft` — new PRs start as draft; **existing PRs are untouched**
- `--cli` — non-interactive mode

Then, for each newly created PR you want published (the usual case), run:

```bash
gh pr ready <number>
```

**If submit fails with "stale" error:** Run `gt get` first to sync downstack branches, then retry submit. `gt get` is always safe to run but may be unnecessary overhead.

### Draft vs published: preserve existing state

The two flags behave very differently — this is easy to get wrong:

| Flag | Scope | Effect |
|------|-------|--------|
| `--draft` | New PRs only | New PRs created as draft; existing PRs untouched |
| `--publish` | **All PRs being submitted** | Republishes every PR in the stack, including existing drafts |

**Never default to `--publish`.** It silently republishes existing drafts, which is destructive — the wrong move almost every time. Default policy:

- **New PRs**: publish (via `gh pr ready <n>` after submit)
- **Existing PRs**: preserve their current state

Use `--publish` only when the explicit intent is "publish every PR in this stack, including any existing drafts".

To change the status of individual existing PRs, use `gh` directly:

```bash
gh pr ready --undo <PR>   # Convert to draft
gh pr ready <PR>          # Mark as ready for review
```

### Verify mirroring before triggering CI

Shopify mirrors pushes from Gitstream (the source of truth) to GitHub. CI runs against the **mirrored** commit, so you must confirm the mirror has settled *before* running any CI command (`devx ci run`, `devx ci merge-when-ready`, etc.). Triggering CI early can run against a stale commit or fail with "commit not found".

For each branch you're about to trigger CI on:

```bash
dev gitstream mirror-status <branch>
```

Proceed **only** when it reports the remotes in sync — `local`, `gitstream`, and `github` all at the same SHA. You can also confirm the push settled with `dev gitstream push-status <branch>` (look for `"outcome": "mirrored"`).

**This is a hard gate (Golden Rule 6):** if the branch is not yet mirrored, do not run CI. Mirroring is usually near-instant; if it hasn't settled, wait briefly and re-check. If it stays unmirrored or shows divergence (GitHub-only ref), stop and surface it to the user — load the `gitstream` skill to diagnose.

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
gt submit --stack --draft --cli
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
gt submit --stack --draft --cli
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
gt submit --stack --draft --cli
```

**Approach 2: Absorb (when code is present upstack)**

```bash
# Stay on current branch
git add <files>
gt absorb --dry-run        # Preview distribution
gt absorb --force          # Apply if correct
gt submit --stack --draft --cli
```

If `gt absorb --dry-run` shows unexpected distribution, use Approach 1 instead.

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

Aliases: `gt co`, `gt u`, `gt d`, `gt t`, `gt b`. Run `gt --help` for stepping multiple branches.

### Common cross-stack patterns

For advanced stack reorganisation, see `gt split --help`, `gt fold --help`, `gt reorder --help`, `gt move --help`.

**Introducing something downstack, cleaning up upstack:**

This is the feature flag pattern (see below). Introduce the flag-protected code in lower PRs, then add a cleanup PR at the top that removes the flag.

**Updating PR metadata across the stack:**

Use `gh` CLI for bulk updates:

```bash
gh pr edit ...
```

### After `gt get`

When you sync downstack, changes to base PRs may require:

- `dev up` — update dependencies, run migrations. **Always** prefer `dev up` over Rails' default migrate command (e.g. `bin/rails db:migrate`); `dev up` converges the full environment (dependencies, datastores, migrations across all databases) whereas the Rails command only runs migrations against the default database.
- You'll discover this through errors when running tests

For collaboration patterns (working on someone else's stack, multiple developers), see `gt get --help` and `gt freeze --help`.

---

## PR Quality Standards

Useful ways to split a stack: by layer (migration -> API -> UI), by component, by dependency
order, by risk (riskiest at the bottom, so it is cheap to revert), or by review speed (quick
reviews at the bottom so they merge and unblock the rest). Keep each PR small enough to review
in one sitting, and independently understandable -- if a reviewer needs an upstack PR to make
sense of this one, the split is wrong.

**Consult the `pr-authoring` skill (or similar skills) for comprehensive guidance on writing PR titles and descriptions.**

When drafting descriptions for your PRs, prioritize the following stack-specific elements:

**Blockers first.** Always highlight warnings/blockers at the very top:

```markdown
> [!WARNING]
> - [ ] PR was generated by AI—<@github username> has reviewed it
> - Do not merge until `f_user_auth` flag is at 100%
> - Do not merge until PR below is deployed
```

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
| Submit stack | `gt submit --stack --draft --cli` |
| Update and submit | `gt get && gt submit --stack --draft --cli` |
| View stack | `gt log short --stack --no-interactive` |
| Navigate | `gt checkout`, `gt up`, `gt down`, `gt top`, `gt bottom` |

