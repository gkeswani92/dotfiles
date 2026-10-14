# Machine-scoped AI setup

## Resource ownership

- `shared/skills`: Mermaid and Git Context, installed into Pi on both machines.
- `shared/lib`: reusable Herdr team runner and terminal-gated lesson persistence helper.
- `personal/pi`: personal Pi defaults, Herdr skills, `/feature-team`, and tracked personal preference packs.
- `work/skills`, `work/AGENTS.md`, `work/commands`, `work/hooks`, and `work/statusline.sh`: work Claude-compatible resources.
- `work/pi`: work Pi defaults, model overrides, prompts, agents, and Pi-specific skills. These skills take precedence over work Claude-compatible definitions with the same name.

Generic-looking work resources are not automatically shared. Personal installs Herdr and its personal feature-delivery skill/prompt, but no global instructions, agent definitions, installer-managed extensions, or Shopify packages. Herdr's Pi integration is installed separately with `herdr integration install pi`. Work preserves the existing shop-pi-fy filter and extra direct extension links.

## Installation

Run from a local checkout with Python 3 available:

```bash
cd ~/dotfiles
./install.sh --ai-only --dry-run
./install.sh --ai-only
```

On the first run, select Personal or Work. There is no default. The installer reads the choice from the terminal (not piped script input); cancellation or an invalid saved role makes no changes. Dry-run never saves the answer.

The role is stored outside Git in `~/.config/dotfiles/profile`. It is the machine-wide role for Git, shell/work integrations, and AI—not an AI-specific selection. Future installer runs read it without asking. `--ai-only` limits a particular run to AI configuration; `--config-only` configures Git, layouts, and AI without installing software. After successful setup, start a new shell or run `source ~/.zshrc`.

| Role | Active Pi directory | Installed Pi resources |
|------|---------------------|------------------------|
| personal | `~/.pi/agent` | shared + personal; default `openai-codex/gpt-6.1-sol`, 1,050,000-token context |
| work | `~/.pi/agent-shopify` | shared + work; default `anthropic/claude-opus-5-5`, 1,000,000-token context |

Plain `pi` uses `~/.local/bin/pi`, which pins the role's directory, discards an inherited session-directory override, and delegates to the actual Pi CLI on PATH. Child Pi processes also see the launcher on PATH. The launcher fails if the saved role is missing/invalid; it does not guess from an inherited environment variable or an existing directory.

To intentionally change the role:

```bash
./install.sh --config-only --reconfigure-profile
```

Changing roles requires confirmation. Once Git is managed, `--ai-only` cannot change the role: use `--config-only` or the full installer so Git and AI remain consistent. The other Pi directory, authentication, history, memory, and team artifacts are preserved. The role is saved only after configuration succeeds.

## Conflicts, backups, and reruns

The installer updates links it owns, and archives obsolete owned links. It also recognizes old work links into `ai/skills`, `ai/pi-skills`, etc. so personal installation does not retain these legacy links. Arbitrary manually installed resources are not deleted.

Independent files/directories or unrelated links at a desired destination cause a preflight failure, before the full installer can make other changes. Inspect the dry-run, then explicitly approve backing up and replacing conflicts:

```bash
./install.sh --ai-only --dry-run
./install.sh --ai-only --replace-conflicts
```

Backups are stored under `~/.dotfiles-backup/ai-*/` using original home-relative paths. Existing independent personal Mermaid/Git Context copies are backed up during this migration. Backed-up symlinks remain symlinks, not frozen snapshots of their contents.

Live Pi `settings.json` and `models.json` are local files, never repository symlinks. Settings defaults seed missing preferences only. On work reruns, the installer refreshes its shop-pi-fy package entry. Both roles apply their explicit model overrides; unrelated settings/models are retained. Personal reruns remove recognized work package/resource references, but preserve unrelated user packages and resources. `auth.json`, sessions, trust decisions, caches, and memory are never installed or edited.

If the work machine previously stored work authentication/history in `~/.pi/agent` instead of `~/.pi/agent-shopify`, review that migration separately before installing. The installer will not infer whether credentials belong to work or copy them automatically.

## Model defaults and context limits

Personal uses the existing ChatGPT/Codex connection (`openai-codex`), not an API-key-only provider. Its Sol 6.1 context override opts into the 1,050,000-token window advertised on [OpenAI's model page](https://developers.openai.com/api/docs/models/gpt-6.1-sol), instead of Pi's conservative 272K default. Work uses Opus 5.5's catalogued 1,000,000-token window. Overrides do not unlock provider entitlements; upstream request limits and pricing still apply. Large OpenAI contexts enter the more expensive long-context tier.

Defaults seed new profiles; existing local model preferences are intentionally preserved. To change an existing profile's startup model, select it in `/model` and press Ctrl+S, or explicitly edit its local `settings.json`. Resuming an old session can restore the old model; use `/new` to test startup defaults.

## Work package bootstrap

On a fresh work profile, settings register shop-pi-fy, but the installer does not fetch packages or authenticate. Start `pi` to let Pi install the configured package, then rerun:

```bash
./install.sh --ai-only
```

This adds the extra direct extension/skill links used by the work setup. Missing expected resources in an existing package checkout fail preflight rather than creating broken links.

Herdr's work preference packs still reference work-machine-local `~/.pi/memory/knowledge/` files. Those files are not synced or moved by this installer.

## Personal visible feature team

Install/verify Herdr's Pi integration separately:

```bash
herdr integration install pi
herdr integration status
./install.sh --ai-only
```

In a Herdr tab containing only the planner, start Pi in the repository:

```bash
pi --model openai-codex/gpt-6.1-sol --thinking xhigh
```

Then `/feature-team <feature>`. Planner/reviewer use Sol 6.1 xhigh; implementer/tophatter use Sol 6.1 high. The existing visible layout, nonblocking DONE/BLOCKED coordination, frozen candidates, human gates, local status board, and saved sessions remain. No cross-reviewer, PR/comment/CI watcher, work memory injection, or browser automation is enabled. Browser interaction remains human-owned until explicitly configured.

Personal team artifacts live under `~/.pi/feature-teams/personal/<slug>/`, separate from work teams. Preference packs live in `personal/pi/skills/herdr-feature-delivery/preferences/`; base rules are tracked and contain no work knowledge references.

### Approved lessons

The planner proposes exact wording, rationale, evidence, and scope. Proposals live in the team's `lessons/` directory and do not modify standing preferences. In the reserved shell:

```bash
$TEAM_SH lesson list
$TEAM_SH lesson show <id>
$TEAM_SH lesson approve <id>  # prints the rule and requires typed terminal confirmation
```

There is no `--yes` flag or automatic approval. The narrowest scope wins:

- **team:** `<team>/preferences.md`;
- **project:** `<repo>/.pi/preferences/feature-team.md`;
- **personal:** tracked `personal/pi/skills/herdr-feature-delivery/preferences/learned.md`.

Approval checks that the proposal and target still match what was reviewed. The planner reads the approved file and sends its path to live members; new/resumed members load it in their standing context. Preference changes are never committed automatically. This is an explicit human approval workflow, not a sandbox against arbitrary shell execution. Team plans/reports/ledger/session files provide continuity without a memory extension.

## Verification

```bash
python3 -m unittest discover -s tests -v
python3 scripts/setup-ai.py --profile personal --verify
./doctor.sh
```

Tests use temporary home directories and mock Pi binaries; no providers, packages, credentials, or services are contacted. `--verify` is read-only and validates installer-managed resources. It does not reject deliberate extra user-installed personal capabilities.

The full installer gates work Claude setup, Quick Demo installation, and Business Platform Zellij links. Shell startup no longer relinks work Claude resources and loads dev/tec initialization only for work. Installer-owned work layout links are archived in personal mode; custom layouts and already-installed non-AI tools are not silently uninstalled when switching roles.

This is capability-loading separation, not a filesystem or credential sandbox. Explicit project-local Pi resources, ancestor context files, `~/.agents/skills`, and CLI resource flags can still contribute resources. Avoid opening work repositories for personal sessions if you don't want their project instructions loaded.
