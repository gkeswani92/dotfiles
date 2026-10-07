# Machine-scoped AI setup

## Resource ownership

- `shared/skills`: Mermaid and Git Context, installed into Pi on both machines.
- `personal/pi`: personal Pi defaults and any future personal-only resources.
- `work/skills`, `work/CLAUDE.md`, `work/commands`, `work/hooks`, and `work/statusline.sh`: work Claude-compatible resources.
- `work/pi`: work Pi defaults, model overrides, prompts, agents, and Pi-specific skills. These skills take precedence over work Claude-compatible definitions with the same name.

Generic-looking work resources are not automatically shared. Personal currently installs no global instructions, prompts, agents, extensions, or Shopify packages. Work preserves the existing shop-pi-fy filter and extra direct extension links.

## Installation

Run from a local checkout with Python 3 available:

```bash
cd ~/dotfiles
./install.sh --ai-only --dry-run
./install.sh --ai-only
```

On the first run, select Personal or Work. There is no default. The installer reads the choice from the terminal (not piped script input); cancellation or an invalid saved role makes no changes. Dry-run never saves the answer.

The role is stored outside Git in `~/.config/dotfiles/profile`. Future installer runs read it without asking. After successful setup, start a new shell or run `source ~/.zshrc`.

| Role | Active Pi directory | Installed Pi resources |
|------|---------------------|------------------------|
| personal | `~/.pi/agent` | shared + personal; default `openai-codex/gpt-6.1-sol`, 1,050,000-token context |
| work | `~/.pi/agent-shopify` | shared + work; default `anthropic/claude-opus-5-5`, 1,000,000-token context |

Plain `pi` uses `~/.local/bin/pi`, which pins the role's directory, discards an inherited session-directory override, and delegates to the actual Pi CLI on PATH. Child Pi processes also see the launcher on PATH. The launcher fails if the saved role is missing/invalid; it does not guess from an inherited environment variable or an existing directory.

To intentionally change the role:

```bash
./install.sh --ai-only --reconfigure-profile
```

Changing roles requires confirmation. The other Pi directory, authentication, history, memory, and team artifacts are preserved. The role is saved only after AI setup succeeds.

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

## Verification

```bash
python3 -m unittest discover -s tests -v
python3 scripts/setup-ai.py --profile personal --verify
./doctor.sh
```

Tests use temporary home directories and mock Pi binaries; no providers, packages, credentials, or services are contacted. `--verify` is read-only and validates installer-managed resources. It does not reject deliberate extra user-installed personal capabilities.

The full installer gates work Claude setup, Quick Demo installation, and Business Platform Zellij links. Shell startup no longer relinks work Claude resources and loads dev/tec initialization only for work. Existing non-AI work tools/layouts are not silently uninstalled when switching roles.

This is capability-loading separation, not a filesystem or credential sandbox. Explicit project-local Pi resources, ancestor context files, `~/.agents/skills`, and CLI resource flags can still contribute resources. Avoid opening work repositories for personal sessions if you don't want their project instructions loaded.
