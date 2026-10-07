#!/usr/bin/env python3
"""Install scoped AI resources without installing software or touching credentials."""
import argparse
import json
import os
from pathlib import Path
import tempfile


RESOURCE_KEYS = ("extensions", "skills", "prompts", "themes")
SHOP_SOURCE = "https://github.com/shopify-playground/shop-pi-fy"
SHOP_EXTENSIONS = "adversarial-review agent-teams ask dev-open memory no-sleep-while-working notify retitle session-dump tree voice web-search world".split()
SHOP_SKILLS = "chrome-devtools code-review data-portal".split()


def read_json(path, fallback):
    if not path.exists():
        return fallback
    return json.loads(path.read_text())


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", required=True, choices=("personal", "work"))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--check", action="store_true", help="Validate a setup without changing files")
    parser.add_argument("--verify", action="store_true", help="Check installed resources without changing files")
    parser.add_argument("--replace-conflicts", action="store_true", help="Back up conflicting files and links before replacement")
    args = parser.parse_args()
    home = Path.home()
    repo = Path(os.environ.get("DOTFILES_PATH", home / "dotfiles")).resolve()
    state = home / ".config/dotfiles"
    pi = home / ".pi" / ("agent" if args.profile == "personal" else "agent-shopify")
    shared = repo / "ai/shared/skills"
    work = repo / "ai/work"
    defaults = read_json(repo / f"ai/{args.profile}/pi/settings.defaults.json", {})
    links = {}

    def add(source, target):
        if not source.exists():
            raise RuntimeError(f"Missing resource: {source}")
        links[str(target)] = str(source)

    def directory(source, target, suffix=None):
        if not source.exists():
            return
        for item in sorted(source.iterdir()):
            if (suffix and item.suffix == suffix) or (not suffix and (item / "SKILL.md").exists()):
                add(item, target / item.name)

    directory(shared, pi / "skills")
    directory(repo / f"ai/{args.profile}/pi/skills", pi / "skills")
    directory(repo / f"ai/{args.profile}/pi/prompts", pi / "prompts", ".md")
    if args.profile == "work":
        # Pi-specific definitions override the Claude-compatible work skills.
        directory(work / "skills", pi / "skills")
        directory(work / "pi/skills", pi / "skills")
        directory(work / "pi/agents", pi / "agents", ".md")
        add(work / "CLAUDE.md", pi / "AGENTS.md")
        directory(shared, home / ".claude/skills")
        directory(work / "skills", home / ".claude/skills")
        directory(work / "commands", home / ".claude/commands", ".md")
        add(work / "CLAUDE.md", home / ".claude/CLAUDE.md")
        add(work / "statusline.sh", home / ".claude/statusline.sh")
        shop = pi / "git/github.com/shopify-playground/shop-pi-fy"
        if shop.exists():
            for name in SHOP_EXTENSIONS:
                add(shop / "extensions" / name, pi / "extensions" / name)
            for name in SHOP_SKILLS:
                add(shop / "skills" / name, pi / "skills" / name)
        else:
            print("Work package not installed yet. Launch pi once, then rerun install.sh --ai-only to link its extra resources.")
    add(repo / "shell/pi", home / ".local/bin/pi")

    def work_source(source):
        return any(marker in str(source) for marker in (
            "shopify-playground/shop-pi-fy", str(work), str(home / ".pi/agent-shopify"),
            str(repo / "ai/skills"), str(repo / "ai/pi-skills"), str(repo / "ai/prompts"),
            str(repo / "ai/agents"), str(repo / "ai/CLAUDE.md"), str(repo / "ai/commands"),
            str(repo / "ai/statusline.sh"), str(repo / "ai/pi/"),
        ))

    # Keep live settings local. Defaults seed absent preferences; resource package
    # ownership is reconciled separately so personal preferences survive reruns.
    settings_path = pi / "settings.json"
    settings = read_json(settings_path, {})
    for key, value in defaults.items():
        if key != "packages":
            settings.setdefault(key, value)
    packages = settings.get("packages", [])
    packages = [p for p in packages if "shopify-playground/shop-pi-fy" not in str(p)]
    if args.profile == "work":
        packages.extend(defaults.get("packages", []))
    if packages or "packages" in settings:
        settings["packages"] = packages
    if args.profile == "personal":
        for key in RESOURCE_KEYS:
            if key in settings:
                settings[key] = [p for p in settings[key] if not work_source(p)]

    models_path = pi / "models.json"
    models = None
    model_defaults = repo / f"ai/{args.profile}/pi/models.json"
    if model_defaults.exists():
        models = read_json(models_path, {})
        desired = read_json(model_defaults, {})
        for provider, config in desired.get("providers", {}).items():
            dest = models.setdefault("providers", {}).setdefault(provider, {})
            overrides = dest.setdefault("modelOverrides", {})
            for model_id, override in config.get("modelOverrides", {}).items():
                overrides.setdefault(model_id, {}).update(override)

    manifest_path = state / f"ai-links-{args.profile}.json"
    previous = read_json(manifest_path, {})
    obsolete = {}
    for target, source in previous.items():
        path = Path(target)
        if target not in links and path.is_symlink() and os.readlink(path) == source:
            obsolete[target] = source
    # Migrate only recognizable legacy links, never arbitrary files/directories.
    roots = [pi / name for name in ("skills", "prompts", "agents", "extensions")]
    roots += [home / ".claude/skills", home / ".claude/commands"]
    candidates = [p for root in roots if root.is_dir() for p in root.iterdir()]
    candidates += [pi / "AGENTS.md", home / ".claude/CLAUDE.md", home / ".claude/statusline.sh", home / ".config/claude/CLAUDE.md"]
    for path in candidates:
        if path.is_symlink() and work_source(os.readlink(path)) and str(path) not in links:
            # Work keeps manually linked work package capabilities; personal removes them.
            if args.profile == "personal" or str(path).startswith(str(home / ".config/claude")):
                obsolete[str(path)] = os.readlink(path)

    conflicts = []
    for target, source in links.items():
        path = Path(target)
        if path.is_symlink() and os.readlink(path) == source:
            continue
        if path.exists() or path.is_symlink():
            # Updating an installer-owned link doesn't need renewed permission.
            if not (path.is_symlink() and (previous.get(target) == os.readlink(path) or work_source(os.readlink(path)))):
                conflicts.append(target)
    if args.verify:
        failures = []
        for target, source in links.items():
            path = Path(target)
            if not path.is_symlink() or os.readlink(path) != source or not path.exists():
                failures.append(f"Missing or incorrect link: {target}")
        failures.extend(f"Obsolete work link: {target}" for target in obsolete)
        actual = read_json(settings_path, {})
        if settings_path.is_symlink() or not settings_path.exists():
            failures.append("Pi settings must be a local file, not a repository symlink")
        if args.profile == "personal":
            if work_source(json.dumps({k: actual.get(k, []) for k in (*RESOURCE_KEYS, "packages")})):
                failures.append("Work resources still referenced by personal settings")
        elif any(p not in actual.get("packages", []) for p in defaults.get("packages", [])):
            failures.append("Work package configuration is missing or outdated")
        if models is not None:
            actual_models = read_json(models_path, {})
            if models_path.is_symlink() or not models_path.exists():
                failures.append("Pi model overrides must be a local file")
            for provider, config in desired.get("providers", {}).items():
                installed = actual_models.get("providers", {}).get(provider, {}).get("modelOverrides", {})
                for model_id, override in config.get("modelOverrides", {}).items():
                    if any(installed.get(model_id, {}).get(k) != v for k, v in override.items()):
                        failures.append(f"Missing or incorrect model override: {provider}/{model_id}")
        if failures:
            raise RuntimeError("\\n".join(failures))
        print(f"Verified {args.profile} AI resources in {pi}")
        return

    print(f"Machine: {args.profile}; Pi directory: {pi}")
    for target, source in links.items():
        print(f"  Link {target} -> {source}")
    for target in obsolete:
        print(f"  Archive obsolete link: {target}")
    for target in conflicts:
        print(f"  Conflict (backup required): {target}")
    if args.dry_run:
        return
    if conflicts and not args.replace_conflicts:
        raise RuntimeError("No changes made. Review --ai-only --dry-run, then rerun with --replace-conflicts to archive and replace these resources.")

    if args.check:
        return

    backup_dir = None

    def backup(path):
        nonlocal backup_dir
        if not (path.exists() or path.is_symlink()):
            return
        if backup_dir is None:
            root = home / ".dotfiles-backup"
            root.mkdir(parents=True, exist_ok=True)
            backup_dir = Path(tempfile.mkdtemp(prefix="ai-", dir=root))
        dest = backup_dir / path.relative_to(home)
        dest.parent.mkdir(parents=True, exist_ok=True)
        path.rename(dest)
        print(f"  Backed up {path} to {dest}")

    def write_json(path, value):
        content = json.dumps(value, indent=2) + "\n"
        if not path.is_symlink() and path.exists() and path.read_text() == content:
            return
        backup(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as f:
            f.write(content)
            temporary = Path(f.name)
        temporary.replace(path)

    for target in obsolete:
        backup(Path(target))
    for target, source in links.items():
        path = Path(target)
        if path.is_symlink() and os.readlink(path) == source:
            continue
        backup(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(source)
    write_json(settings_path, settings)
    if models is not None:
        write_json(models_path, models)
    write_json(manifest_path, links)
    state.mkdir(parents=True, exist_ok=True)
    # Save the role last: a failed setup must not switch the launcher.
    with tempfile.NamedTemporaryFile(mode="w", dir=state, delete=False) as f:
        f.write(args.profile + "\n")
        temporary = Path(f.name)
    temporary.replace(state / "profile")
    print("AI setup complete. Reload your shell; then type pi.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError, OSError) as error:
        raise SystemExit(str(error))
