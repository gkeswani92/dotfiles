#!/usr/bin/env python3
"""Propose standing preferences; human-only terminal confirmation applies them.

This is an approval workflow, not a sandbox against an agent with arbitrary bash.
No credential access, remote writes, commits, or model calls.
"""
import argparse
from datetime import datetime, timezone
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import tempfile


def digest(data):
    return hashlib.sha256(data).hexdigest()


def current(path):
    if path.is_symlink():
        raise ValueError(f"Refusing symlink preference file: {path}")
    return path.read_bytes() if path.exists() else b""


def atomic_write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temporary = tempfile.mkstemp(prefix=f".{path.name}-", dir=path.parent)
    try:
        with os.fdopen(fd, "wb") as out:
            out.write(data)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


def save(path, proposal):
    atomic_write(path, (json.dumps(proposal, indent=2) + "\n").encode())


def target_for(scope, team, skill, root):
    return {"personal": skill / "preferences/learned.md",
            "project": root / ".pi/preferences/feature-team.md",
            "team": team / "preferences.md"}[scope]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--team-dir", required=True, type=Path)
    parser.add_argument("--skill-dir", required=True, type=Path)
    sub = parser.add_subparsers(dest="command", required=True)
    propose = sub.add_parser("propose")
    propose.add_argument("id")
    propose.add_argument("--scope", required=True, choices=("team", "personal", "project"))
    propose.add_argument("--rule-file", required=True, type=Path)
    propose.add_argument("--reason", required=True)
    propose.add_argument("--evidence", required=True)
    sub.add_parser("list")
    for command in ("show", "approve", "reject"):
        sub.add_parser(command).add_argument("id")
    args = parser.parse_args()
    team, skill = args.team_dir.resolve(), args.skill_dir.resolve()
    info = json.loads((team / "team.json").read_text())
    root = Path(info["root"]).resolve()
    lessons = team / "lessons"
    if args.command == "list":
        for path in sorted(lessons.glob("*.json")):
            entry = json.loads(path.read_text())
            print(f"{entry['id']}: {entry['status']} ({entry['scope']})")
        return
    if not re.fullmatch(r"[a-z][a-z0-9-]{0,47}", args.id):
        raise ValueError("Lesson id must match [a-z][a-z0-9-]{0,47}")
    path = lessons / f"{args.id}.json"
    if args.command == "propose":
        if path.exists():
            raise ValueError("Lesson already exists; use a new id for revised wording")
        rule = args.rule_file.read_text().strip()
        if not rule or not args.reason.strip() or not args.evidence.strip():
            raise ValueError("Rule, reason, and evidence must all be nonempty")
        target = target_for(args.scope, team, skill, root)
        proposal = {"id": args.id, "scope": args.scope, "rule": rule,
                    "reason": args.reason, "evidence": args.evidence,
                    "target": str(target), "target_hash": digest(current(target)),
                    "status": "proposed"}
        save(path, proposal)
        print(f"Proposed {args.id}; no preferences changed.\nTarget: {target}")
        print(f"Human approval: $TEAM_SH lesson approve {args.id} --team {info['slug']}")
        return
    proposal_bytes = path.read_bytes()
    proposal = json.loads(proposal_bytes)
    if args.command == "show":
        print(json.dumps(proposal, indent=2))
        return
    if proposal["status"] != "proposed":
        raise ValueError(f"Lesson is already {proposal['status']}")
    if args.command == "reject":
        proposal["status"] = "rejected"
        save(path, proposal)
        print(f"Rejected {args.id}; no preferences changed")
        return
    target = target_for(proposal["scope"], team, skill, root)
    if str(target) != proposal["target"]:
        raise ValueError("Proposal target changed; propose again")
    token = digest(proposal_bytes)[:12]
    phrase = f"approve {args.id} {token}"
    try:
        with open("/dev/tty", "w") as output, open("/dev/tty", "r") as input_stream:
            output.write(f"\nScope: {proposal['scope']}\nTarget: {target}\n\n{proposal['rule']}\n\n"
                         f"Why: {proposal['reason']}\nEvidence: {proposal['evidence']}\n\n"
                         f"Type exactly '{phrase}' to persist this lesson (anything else cancels): ")
            output.flush()
            answer = input_stream.readline().strip()
    except OSError as exc:
        raise ValueError("Approval requires your interactive shell's controlling terminal") from exc
    if answer != phrase:
        raise ValueError("Approval cancelled; no preferences changed")
    # Serialize approvals across teams that share a preference target. Check both
    # the reviewed proposal and target again after taking the lock.
    lock_dir = team.parent / ".lesson-locks"
    lock_dir.mkdir(parents=True, exist_ok=True)
    with (lock_dir / digest(str(target).encode())).open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if digest(path.read_bytes())[:12] != token:
            raise ValueError("Proposal changed during approval; inspect and retry")
        original = current(target)
        if digest(original) != proposal["target_hash"]:
            raise ValueError("Preference file changed since proposal; propose again against current content")
        section = (f"\n\n## Approved lesson: {info['slug']}/{args.id}\n\n{proposal['rule']}\n").encode()
        atomic_write(target, original.rstrip() + section)
        proposal.update(status="approved", approved_at=datetime.now(timezone.utc).isoformat(),
                        applied_hash=digest(current(target)))
        save(path, proposal)
    with (team / "ledger.md").open("a") as ledger:
        ledger.write(f"| {datetime.now():%Y-%m-%d %H:%M} | Approved lesson {args.id} ({proposal['scope']}): {target} |\n")
    print(f"Approved {args.id}: {target}\nNo commit or external write performed.")
    print("Planner: read the approved file; send its path to every live member for their next assignment.")
    print("New/resumed members load it in their standing context. Project lessons must be committed separately to travel with the project.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, KeyError) as error:
        raise SystemExit(f"lesson: {error}")
