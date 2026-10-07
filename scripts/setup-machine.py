#!/usr/bin/env python3
"""Reconcile machine-scoped Git and Zellij configuration, without installing tools."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

MARKER = "# Managed by dotfiles/scripts/setup-machine.py\n"


def git_config(path, *args, includes=False):
    command = ["git", "config", "--file", str(path)]
    if includes:
        command.append("--includes")
    return subprocess.run(command + list(args), text=True, capture_output=True)


def value(path, key):
    result = git_config(path, "--get", key, includes=True)
    return result.stdout.strip() if result.returncode == 0 else None


def quote(path):
    return '"' + str(path).replace("\\", "\\\\").replace('"', '\\"') + '"'


def wrapper(repo, home, profile):
    paths = [repo / "git/.gitconfig", repo / f"git/{profile}.gitconfig",
             home / f".config/dotfiles/git/{profile}.local.gitconfig"]
    return (MARKER + "[include]\n" + "".join(f"  path = {quote(p)}\n" for p in paths)
            + f"[dotfiles]\n  profile = {profile}\n[user]\n  useConfigOnly = true\n")


def atomic_write(path, content):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, "w") as f:
            f.write(content)
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--profile", required=True, choices=("personal", "work"))
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--check", action="store_true")
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--replace-conflicts", action="store_true")
    parser.add_argument("--layouts-only", action="store_true")
    args = parser.parse_args()
    home = Path.home()
    repo = Path(__file__).resolve().parents[1]
    root = home / ".gitconfig"
    local = home / f".config/dotfiles/git/{args.profile}.local.gitconfig"
    content = wrapper(repo, home, args.profile)
    conflicts = []
    failures = []
    signing = {}

    if not args.layouts_only:
        for path in (repo / "git/.gitconfig", repo / f"git/{args.profile}.gitconfig", root, local):
            if path.exists() and git_config(path, "--list", includes=True).returncode != 0:
                raise ValueError(f"Invalid Git configuration: {path}; no changes made")
        previous = value(root, "dotfiles.profile") if root.exists() and not root.is_symlink() else None
        owned = (root.is_symlink() and root.resolve() == repo / "git/.gitconfig") or (
            previous in ("personal", "work") and root.read_text() == wrapper(repo, home, previous))
        if (root.exists() or root.is_symlink()) and not owned:
            conflicts.append(root)
        if local.is_symlink():
            raise ValueError(f"Signing overrides must be local files, not symlinks: {local}")
        # Migrate only this role's signer, never infer that a different role's key applies.
        expected_email = value(repo / f"git/{args.profile}.gitconfig", "user.email")
        if root.exists() and not local.exists() and value(root, "user.email") == expected_email:
            result = git_config(root, "--null", "--get-regexp",
                                r"^(user\.signingkey|commit\.gpgsign|tag\.gpgsign|gpg\..*)$", includes=True)
            if result.returncode not in (0, 1):
                raise ValueError("Unable to inspect existing Git signing settings; no changes made")
            for entry in result.stdout.split("\0"):
                if entry:
                    key, val = entry.split("\n", 1)
                    signing[key] = val
        if root.is_symlink() or not root.exists() or root.read_text() != content:
            failures.append("Git includes do not match the selected machine profile")

    zellij = home / ".config/zellij"
    source = repo / "terminal/zellij"
    links = {zellij / "config.kdl": source / "config.kdl"}
    for name in ("default", "dev") + (("bp-full", "bp-orgs-only") if args.profile == "work" else ()):
        links[zellij / f"layouts/{name}.kdl"] = source / f"layouts/{name}.kdl"
    if args.profile == "work":
        for name in ("bp-full", "bp-orgs-only"):
            links[zellij / f"{name}.kdl"] = source / f"layouts/{name}.kdl"
    obsolete = []
    for name in ("bp-full", "bp-orgs-only"):
        for path in (zellij / f"{name}.kdl", zellij / f"layouts/{name}.kdl"):
            if path in links:
                continue
            known = {source / f"layouts/{name}.kdl", repo / f"local-development/zellij/{name}.kdl"}
            if path.is_symlink() and path.resolve() in known:
                obsolete.append(path)
                failures.append(f"Obsolete managed work layout: {path}")
    for path, target in links.items():
        if not path.is_symlink() or path.resolve() != target:
            failures.append(f"Missing or incorrect layout/config link: {path}")
            if path.exists() or path.is_symlink():
                legacy = repo / f"local-development/zellij/{path.name}"
                if not (path.is_symlink() and path.name in ("bp-full.kdl", "bp-orgs-only.kdl") and path.resolve() == legacy):
                    conflicts.append(path)

    if args.verify:
        if failures:
            raise ValueError("\n".join(failures))
        print(f"Verified {args.profile} machine configuration")
        return
    print(f"Machine configuration: {args.profile}")
    if not args.layouts_only:
        print(f"  Git: shared settings + {args.profile} identity + local signing overrides")
        if signing:
            print(f"  Preserve existing signing settings in {local}")
    for path, target in links.items():
        print(f"  Link {path} -> {target}")
    for path in obsolete:
        print(f"  Archive obsolete work link: {path}")
    for path in conflicts:
        print(f"  Conflict: {path}")
    if conflicts and not args.replace_conflicts and not args.dry_run:
        raise ValueError("No changes made. Review --config-only --dry-run, then use --replace-conflicts to archive and replace conflicts.")
    if args.dry_run or args.check:
        return

    backup_dir = None

    def backup(path, materialize=False):
        nonlocal backup_dir
        if backup_dir is None:
            parent = home / ".dotfiles-backup"
            parent.mkdir(parents=True, exist_ok=True)
            backup_dir = Path(tempfile.mkdtemp(prefix="machine-", dir=parent))
        dest = backup_dir / path.relative_to(home)
        dest.parent.mkdir(parents=True, exist_ok=True)
        # Freeze old Git config contents rather than retaining a link into a changing checkout.
        if materialize and path.exists():
            shutil.copy2(path, dest)
            dest.chmod(0o600)
            path.unlink()
        else:
            shutil.move(str(path), str(dest))
        print(f"  Backed up {path} to {dest}")

    if not args.layouts_only:
        if signing:
            local.parent.mkdir(parents=True, exist_ok=True)
            fd, name = tempfile.mkstemp(dir=local.parent)
            os.close(fd)
            try:
                for key, val in signing.items():
                    result = git_config(Path(name), key, val)
                    if result.returncode != 0:
                        raise ValueError("Unable to preserve signing settings")
                os.replace(name, local)
            finally:
                if os.path.exists(name):
                    os.unlink(name)
        elif not local.exists():
            atomic_write(local, "# Machine-local Git overrides; never tracked in dotfiles.\n")
        if root.is_symlink() or not root.exists() or root.read_text() != content:
            if root.exists() or root.is_symlink():
                backup(root, materialize=True)
            atomic_write(root, content)
    for path in obsolete:
        backup(path)
    for path, target in links.items():
        if path.is_symlink() and path.resolve() == target:
            continue
        if path.exists() or path.is_symlink():
            backup(path)
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(target)
    print("Machine configuration complete; reload your shell for role-specific aliases.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as exc:
        raise SystemExit(str(exc))
