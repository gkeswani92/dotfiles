#!/usr/bin/env python3
"""Offline tests: all writes go into temporary HOME directories."""
import json
import os
from pathlib import Path
import pty
import select
import subprocess
import tempfile
import time
import unittest

REPO = Path(__file__).resolve().parents[1]
SETUP = REPO / "scripts/setup-ai.py"


class AISetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles test ")
        self.home = Path(self.temp.name)
        (self.home / "dotfiles").symlink_to(REPO)
        self.env = dict(os.environ, HOME=str(self.home), DOTFILES_PATH=str(REPO), PI_CODING_AGENT_DIR="/wrong/work/profile")

    def tearDown(self):
        self.temp.cleanup()

    def run_setup(self, profile="personal", *args, ok=True):
        result = subprocess.run(["python3", str(SETUP), "--profile", profile, *args], env=self.env, capture_output=True, text=True)
        if ok:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        else:
            self.assertNotEqual(result.returncode, 0)
        return result

    def write(self, relative, content):
        path = self.home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def write_json(self, relative, value):
        return self.write(relative, json.dumps(value) + "\n")

    def profile(self, value):
        return self.write(".config/dotfiles/profile", value + "\n")

    def snapshot(self):
        return {str(p.relative_to(self.home)): ("link", os.readlink(p)) if p.is_symlink() else ("file", p.read_bytes())
                for p in self.home.rglob("*") if p.is_symlink() or p.is_file()}

    def installer(self, *args, ok=True):
        result = subprocess.run(["bash", str(REPO / "install.sh"), "--ai-only", *args], env=self.env, capture_output=True, text=True, start_new_session=True)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def interactive_install(self, answers, *args):
        pid, fd = pty.fork()
        if pid == 0:
            os.execvpe("bash", ["bash", str(REPO / "install.sh"), "--ai-only", *args], self.env)
        output = b""
        remaining = list(answers)
        deadline = time.monotonic() + 10
        try:
            while time.monotonic() < deadline:
                ready, _, _ = select.select([fd], [], [], 0.1)
                if ready:
                    try:
                        data = os.read(fd, 65536)
                    except OSError:
                        break
                    if not data:
                        break
                    output += data
                    if remaining and (b"Choice: " in output or b"Type yes: " in output):
                        os.write(fd, remaining.pop(0).encode() + b"\n")
                        output = output.replace(b"Choice: ", b"Choice answered: ").replace(b"Type yes: ", b"Confirmation answered: ")
            else:
                os.kill(pid, 9)
                self.fail("Interactive installer timed out")
        finally:
            os.close(fd)
            _, status = os.waitpid(pid, 0)
        return os.waitstatus_to_exitcode(status), output.decode(errors="replace")

    def test_personal_only_shared(self):
        self.run_setup()
        pi = self.home / ".pi/agent"
        self.assertEqual(sorted(p.name for p in (pi / "skills").iterdir()), ["git-context", "mermaid"])
        for name in ("AGENTS.md", "agents", "prompts", "extensions", "git"):
            self.assertFalse((pi / name).exists(), name)
        self.assertFalse((self.home / ".claude").exists())
        settings = json.loads((pi / "settings.json").read_text())
        self.assertEqual(settings["defaultProvider"], "openai-codex")
        self.assertEqual(settings["defaultModel"], "gpt-6.1-sol")
        self.assertFalse((pi / "models.json").is_symlink())
        models = json.loads((pi / "models.json").read_text())
        self.assertEqual(models["providers"]["openai-codex"]["modelOverrides"]["gpt-6.1-sol"]["contextWindow"], 1050000)
        self.assertEqual((self.home / ".config/dotfiles/profile").read_text(), "personal\n")
        self.run_setup("personal", "--verify")

    def test_work_skills_overrides_and_settings(self):
        self.run_setup("work")
        pi = self.home / ".pi/agent-shopify"
        self.assertEqual((pi / "skills/deep-dive").resolve(), REPO / "ai/work/pi/skills/deep-dive")
        self.assertTrue((pi / "skills/herdr-feature-delivery/scripts/team.sh").exists())
        self.assertTrue((pi / "skills/deploy-organizations/references/rollback.md").exists())
        self.assertTrue((pi / "prompts/feature-team.md").exists())
        self.assertTrue((pi / "agents/explorer.md").exists())
        self.assertEqual((pi / "skills/mermaid").resolve(), REPO / "ai/shared/skills/mermaid")
        settings = json.loads((pi / "settings.json").read_text())
        self.assertIn("shop-pi-fy", settings["packages"][0]["source"])
        self.assertEqual(settings["defaultProvider"], "anthropic")
        self.assertEqual(settings["defaultModel"], "claude-opus-5-5")
        self.assertEqual(json.loads((pi / "models.json").read_text())["providers"]["anthropic"]["modelOverrides"]["claude-opus-5-5"]["contextWindow"], 1000000)
        self.assertFalse((pi / "settings.json").is_symlink())
        self.assertFalse((pi / "models.json").is_symlink())
        self.assertEqual(json.loads((pi / "models.json").read_text())["providers"]["openai"]["modelOverrides"]["gpt-6.1-sol"]["contextWindow"], 1000000)
        self.run_setup("work", "--verify")

    def test_work_extra_package_links(self):
        from importlib.util import module_from_spec, spec_from_file_location
        spec = spec_from_file_location("setup_ai", SETUP)
        module = module_from_spec(spec)
        spec.loader.exec_module(module)
        shop = self.home / ".pi/agent-shopify/git/github.com/shopify-playground/shop-pi-fy"
        for kind, names in (("extensions", module.SHOP_EXTENSIONS), ("skills", module.SHOP_SKILLS)):
            for name in names:
                (shop / kind / name).mkdir(parents=True)
        self.run_setup("work")
        self.assertEqual(len(list((self.home / ".pi/agent-shopify/extensions").iterdir())), len(module.SHOP_EXTENSIONS))
        self.run_setup("work", "--verify")

    def test_rerun_idempotent(self):
        self.run_setup()
        before = self.snapshot()
        self.run_setup()
        self.assertEqual(before, self.snapshot())

    def test_local_settings_auth_and_sessions_preserved(self):
        settings = {"defaultProvider": "openai-codex", "defaultModel": "personal-model", "theme": "light", "custom": True}
        path = self.write_json(".pi/agent/settings.json", settings)
        auth = self.write(".pi/agent/auth.json", "PRIVATE AUTH SENTINEL")
        session = self.write(".pi/agent/sessions/local/session.jsonl", "PRIVATE SESSION SENTINEL")
        self.run_setup()
        self.assertEqual(json.loads(path.read_text()), settings)
        self.assertEqual(auth.read_text(), "PRIVATE AUTH SENTINEL")
        self.assertEqual(session.read_text(), "PRIVATE SESSION SENTINEL")

    def test_model_overrides_preserve_unrelated_fields(self):
        path = self.write_json(".pi/agent/models.json", {
            "providers": {
                "openai-codex": {
                    "modelOverrides": {
                        "gpt-6.1-sol": {"contextWindow": 272000, "maxTokens": 64000},
                        "gpt-5.5": {"contextWindow": 500000},
                    }
                },
                "local": {"baseUrl": "http://localhost:1234"},
            }
        })
        self.run_setup()
        models = json.loads(path.read_text())
        overrides = models["providers"]["openai-codex"]["modelOverrides"]
        self.assertEqual(overrides["gpt-6.1-sol"], {"contextWindow": 1050000, "maxTokens": 64000})
        self.assertEqual(overrides["gpt-5.5"]["contextWindow"], 500000)
        self.assertEqual(models["providers"]["local"]["baseUrl"], "http://localhost:1234")

    def test_conflict_requires_explicit_backup(self):
        original = self.write(".pi/agent/skills/mermaid/SKILL.md", "custom original")
        before = self.snapshot()
        self.run_setup(ok=False)
        self.assertEqual(before, self.snapshot())
        self.run_setup("personal", "--replace-conflicts")
        self.assertEqual(original.read_text(), (REPO / "ai/shared/skills/mermaid/SKILL.md").read_text())
        backups = list((self.home / ".dotfiles-backup").glob("*/.pi/agent/skills/mermaid/SKILL.md"))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_text(), "custom original")

    def test_legacy_work_links_and_resource_settings_removed(self):
        target = self.home / ".pi/agent/skills/stack"
        target.parent.mkdir(parents=True)
        target.symlink_to(REPO / "ai/skills/stack")  # old, now dangling
        claude = self.home / ".config/claude/CLAUDE.md"
        claude.parent.mkdir(parents=True)
        claude.symlink_to(REPO / "ai/CLAUDE.md")
        self.write_json(".pi/agent/settings.json", {"packages": ["https://github.com/shopify-playground/shop-pi-fy", "npm:my-personal-package"], "extensions": [str(REPO / "ai/work/custom.ts"), "/personal/custom.ts"]})
        self.run_setup()
        self.assertFalse(target.is_symlink())
        self.assertFalse(claude.is_symlink())
        settings = json.loads((self.home / ".pi/agent/settings.json").read_text())
        self.assertEqual(settings["packages"], ["npm:my-personal-package"])
        self.assertEqual(settings["extensions"], ["/personal/custom.ts"])

    def test_settings_symlink_materialized_without_editing_repo(self):
        pi = self.home / ".pi/agent"
        pi.mkdir(parents=True)
        source = self.write_json("settings-template.json", {"theme": "light"})
        before = source.read_bytes()
        (pi / "settings.json").symlink_to(source)
        self.run_setup()
        self.assertFalse((pi / "settings.json").is_symlink())
        self.assertEqual(source.read_bytes(), before)
        self.assertEqual(json.loads((pi / "settings.json").read_text())["theme"], "light")

    def test_dry_run_no_changes_even_with_conflict(self):
        self.write(".pi/agent/skills/mermaid/SKILL.md", "keep")
        before = self.snapshot()
        self.run_setup("personal", "--dry-run")
        self.assertEqual(before, self.snapshot())

    def test_manual_resources_and_other_profile_untouched(self):
        custom = self.write(".pi/agent/skills/custom/SKILL.md", "personal resource")
        other = self.write(".pi/agent-shopify/auth.json", "work auth")
        self.run_setup()
        self.assertEqual(custom.read_text(), "personal resource")
        self.assertEqual(other.read_text(), "work auth")

    def test_stale_managed_links_archived(self):
        target = self.home / ".pi/agent/prompts/old.md"
        target.parent.mkdir(parents=True)
        target.symlink_to(REPO / "README.md")
        self.write_json(".config/dotfiles/ai-links-personal.json", {str(target): str(REPO / "README.md")})
        self.run_setup()
        self.assertFalse(target.is_symlink())

    def test_invalid_settings_preflight_no_changes(self):
        self.write(".pi/agent/settings.json", "{broken")
        before = self.snapshot()
        self.run_setup(ok=False)
        self.assertEqual(before, self.snapshot())

    def test_saved_role_installer_does_not_prompt(self):
        self.profile("personal")
        result = self.installer()
        self.assertNotIn("Choice:", result.stdout)
        self.assertEqual(result.stdout.count("Machine: personal; Pi directory:"), 1)
        self.assertFalse((self.home / ".pi/agent-shopify").exists())

    def test_installer_dry_run_prints_once_without_changes(self):
        self.profile("personal")
        self.write(".pi/agent/skills/mermaid/SKILL.md", "independent copy")
        before = self.snapshot()
        result = self.installer("--dry-run")
        self.assertEqual(result.stdout.count("Machine: personal; Pi directory:"), 1)
        self.assertEqual(result.stdout.count("Conflict (backup required):"), 1)
        self.assertEqual(before, self.snapshot())

    def test_missing_role_noninteractive_refuses(self):
        before = self.snapshot()
        self.installer(ok=False)
        self.assertEqual(before, self.snapshot())

    def test_invalid_role_refuses(self):
        self.profile("wrong")
        before = self.snapshot()
        self.installer(ok=False)
        self.assertEqual(before, self.snapshot())

    def test_first_prompt_validation_and_save(self):
        code, output = self.interactive_install(["", "invalid", "personal"])
        self.assertEqual(code, 0, output)
        self.assertIn("there is no default", output)
        self.assertEqual((self.home / ".config/dotfiles/profile").read_text(), "personal\n")
        self.installer()

    def test_prompt_cancel_no_changes(self):
        before = self.snapshot()
        code, _ = self.interactive_install(["q"])
        self.assertNotEqual(code, 0)
        self.assertEqual(before, self.snapshot())

    def test_reconfigure_confirmation(self):
        self.run_setup()
        before = self.snapshot()
        code, _ = self.interactive_install(["work", "no"], "--reconfigure-profile")
        self.assertNotEqual(code, 0)
        self.assertEqual(before, self.snapshot())
        code, output = self.interactive_install(["work", "yes"], "--reconfigure-profile")
        self.assertEqual(code, 0, output)
        self.assertEqual((self.home / ".config/dotfiles/profile").read_text(), "work\n")
        self.assertTrue((self.home / ".pi/agent/skills/mermaid").exists())

    def test_launcher_pins_profile_and_preserves_args_for_children(self):
        binary = self.write("bin/pi", '#!/bin/bash\nif [ "$1" = nested ]; then exec pi child; fi\nprintf "%s|%s|%s\\n" "$PI_CODING_AGENT_DIR" "${PI_CODING_AGENT_SESSION_DIR-unset}" "$*"\n')
        binary.chmod(0o755)
        self.env["PATH"] = f"{self.home}/.local/bin:{REPO}/shell:{self.home}/bin:/usr/bin:/bin"
        self.env["PI_CODING_AGENT_SESSION_DIR"] = "/wrong/sessions"
        for profile, directory in (("personal", "agent"), ("work", "agent-shopify")):
            self.run_setup(profile)
            result = subprocess.run([str(self.home / ".local/bin/pi"), "argument with spaces", "--offline"], env=self.env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout.strip(), f"{self.home}/.pi/{directory}|unset|argument with spaces --offline")
            child = subprocess.run([str(self.home / ".local/bin/pi"), "nested"], env=self.env, capture_output=True, text=True)
            self.assertEqual(child.stdout.strip(), f"{self.home}/.pi/{directory}|unset|child")

    def test_verify_rejects_missing_model_override(self):
        self.run_setup()
        self.write_json(".pi/agent/models.json", {})
        self.run_setup("personal", "--verify", ok=False)

    def test_verify_rejects_work_leak(self):
        self.run_setup()
        self.write_json(".pi/agent/settings.json", {"packages": ["https://github.com/shopify-playground/shop-pi-fy"]})
        self.run_setup("personal", "--verify", ok=False)


if __name__ == "__main__":
    unittest.main()
