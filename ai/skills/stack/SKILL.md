---
name: stack
description: Use when planning or implementing any code changes. Establishes which VCS surface owns the work — Gitstream (gs) or GitHub/Graphite (gt, gh) — then loads the matching reference covering feature flag strategy, stack structure, PR breakdown, and all VCS operations. Triggers on plan, implement, feature, task, commit, PR, pull request, branch, stack, flag, gs, gt commands.
---

# Stacked PR Workflow

Shopify is mid-migration between two VCS surfaces. They use different tools, different PR
stores, and **unrelated PR numbering**. Mixing them diverges branches and points tools at the
wrong objects.

| Surface | Stack tool | PR data | PR tool | Web |
|---------|-----------|---------|---------|-----|
| **Gitstream** | `gs` | Gitstream | `gs pr` | meteorite.shopify.io |
| **GitHub/Graphite** (legacy) | `gt` | GitHub | `gh pr` | github.com |

Your first job on any task is to establish which one owns the work. Everything else follows
from that, so do it before you touch anything.

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

## Golden rules

These hold on both surfaces:

1. **Assume no VCS permissions.** Do not commit, push, or create PRs unless the user explicitly
   asks. If your plan involves making PRs, confirm with the user before starting.

2. **Establish the surface before you touch anything,** and never drive one stack from both.

3. **Never default to raw git commands that modify remote or stack state.** No `git push`,
   `git rebase`, `git reset`, `git fetch`. Use the stack tool's verbs.

4. **Never use web write buttons** on Meteorite, GitHub, or Graphite. No web editor, commit
   suggestions, rebase/squash/update-branch, or merge button. Those bypass CI and merge
   automation.

5. **Announce VCS actions before executing.** Give the full sequence upfront in one brief
   sentence, then execute without narrating each step.

6. **Decide branch strategy before making changes.** When fixing bugs or changing existing code,
   work out which branch the change belongs in and how you'll get there. State your approach,
   then proceed.

7. **When in doubt, ask.** Which surface, which branch, whether to publish, whether to run CI —
   all cheap to resolve with a question and expensive to get wrong. Use your ask/question tool.

---

## Step 1 — Decipher the environment

If the user has already stated a preference — "use gitstream", "keep this one on graphite" —
that is binding. Skip to step 2.

Otherwise, from the branch you intend to work on:

```bash
gs pr stack                             # Gitstream: server-projected PR stack
gs log -s                               # Gitstream: local stack state
gt log short --stack --no-interactive   # Graphite: legacy stack state
```

Read them as three signals:

- `gs pr stack` prints a stack → there is a **live Gitstream PR** for this branch. Strongest
  signal. An ambiguous match (several PRs on one branch) means **ask** which is real.
- `gs log -s` shows the branch → Gitstream tracks it **locally**, even if no PR exists yet.
- `gt log short --stack` shows the branch → **Graphite** tracks it.

If neither tool is installed, this is a plain git repo — confirm with the user before using raw
git for commits or PRs.

## Step 2 — Choose, then load the reference

| Signals | Surface | Load |
|---------|---------|------|
| Gitstream only | Gitstream | `references/gitstream.md` |
| Graphite only | GitHub/Graphite | `references/github.md` |
| **Both** | **Ask the user** | — |
| Neither (new work) | **Ask the user**; recommend Gitstream | — |

**Both signals present: stop and ask.** A dual-tracked stack is how branches get diverged. Do
not guess, and do not migrate a stack between surfaces without being asked.

**Neither: this is new work, so ask.** Gitstream is where everything is heading, so recommend
it — but until the user has said so once, get confirmation rather than assuming. Their answer
holds for the rest of the session.

Once decided, state the surface you're using, load the matching reference into context, and
follow it.

| Reference | Covers |
|-----------|--------|
| [references/gitstream.md](references/gitstream.md) | `gs` workflow, `gs pr`, Meteorite, CI, planning, feature flags, PR quality |
| [references/github.md](references/github.md) | `gt` workflow, `gh` PR edits, Gitstream mirror gate, CI, planning, feature flags, PR quality |
