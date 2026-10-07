"""Machine role regression tests; no package installation, keys, or network access."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class MachineSetupTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles machine test ")
        self.home = Path(self.temp.name)
        (self.home / "dotfiles").symlink_to(REPO)
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        self.env.update(HOME=str(self.home), GIT_CONFIG_NOSYSTEM="1")

    def tearDown(self):
        self.temp.cleanup()

    def write(self, relative, content):
        path = self.home / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content)
        return path

    def setup_machine(self, profile="personal", *args, ok=True, repo=REPO):
        result = subprocess.run(["python3", str(repo / "scripts/setup-machine.py"), "--profile", profile, *args],
                                env=self.env, cwd=self.home, text=True, capture_output=True)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def install(self, *args, ok=True):
        result = subprocess.run(["bash", str(REPO / "install.sh"), *args], env=self.env,
                                cwd=self.home, text=True, capture_output=True, start_new_session=True)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def get(self, key, path=None, path_value=False):
        command = ["git", "config"]
        if path:
            command += ["--file", str(path), "--includes"]
        if path_value:
            command.append("--path")
        result = subprocess.run(command + ["--get", key], env=self.env, cwd=self.home,
                                text=True, capture_output=True)
        return result.stdout.strip() if result.returncode == 0 else None

    def snapshot(self):
        return {str(p.relative_to(self.home)): ("link", os.readlink(p)) if p.is_symlink() else ("file", p.read_bytes())
                for p in self.home.rglob("*") if p.is_file() or p.is_symlink()}

    def test_personal_identity_no_work_settings_and_idempotence(self):
        self.setup_machine()
        self.assertFalse((self.home / ".gitconfig").is_symlink())
        self.assertEqual(self.get("user.email"), "gauravkeswani92@gmail.com")
        self.assertEqual(self.get("core.pager"), "delta")
        self.assertEqual(self.get("user.useConfigOnly"), "true")
        self.assertIsNone(self.get("maintenance.repo"))
        self.assertIsNone(self.get("url.https://github.com/Shopify/.insteadOf"))
        self.assertIsNone(self.get("user.signingkey"))
        self.assertEqual(sorted(p.name for p in (self.home / ".config/zellij/layouts").iterdir()), ["default.kdl", "dev.kdl"])
        before = self.snapshot()
        self.setup_machine()
        self.setup_machine("personal", "--verify")
        self.assertEqual(before, self.snapshot())

    def test_work_identity_dev_include_and_portable_maintenance(self):
        self.write(".config/dev/gitconfig", "[alias]\n  dev-test = status\n[user]\n  email = wrong@example.com\n")
        self.setup_machine("work")
        self.assertEqual(self.get("user.email"), "gaurav.keswani@shopify.com")
        self.assertEqual(self.get("alias.dev-test"), "status")
        self.assertEqual(self.get("maintenance.repo", path_value=True), str(self.home / "world/git"))
        self.assertIsNotNone(self.get("url.https://github.com/Shopify/.insteadOf"))
        self.assertTrue((self.home / ".config/zellij/layouts/bp-full.kdl").is_symlink())
        self.setup_machine("work", "--verify")
        self.setup_machine("personal")
        self.assertEqual(self.get("user.email"), "gauravkeswani92@gmail.com")
        self.assertIsNone(self.get("alias.dev-test"))
        self.assertIsNone(self.get("maintenance.repo"))
        self.assertIsNone(self.get("url.https://github.com/Shopify/.insteadOf"))

    def test_signer_migration_is_role_specific(self):
        self.write(".gitconfig", "[user]\n  email = gauravkeswani92@gmail.com\n  signingkey = PERSONAL-KEY\n[commit]\n  gpgsign = true\n[gpg]\n  format = ssh\n")
        self.setup_machine("personal", "--replace-conflicts")
        self.assertEqual(self.get("user.signingkey"), "PERSONAL-KEY")
        self.assertEqual(self.get("commit.gpgsign"), "true")
        local = self.home / ".config/dotfiles/git/personal.local.gitconfig"
        original = local.read_bytes()
        self.setup_machine("work")
        self.assertIsNone(self.get("user.signingkey"))
        self.assertIsNone(self.get("commit.gpgsign"))
        self.assertIsNone(self.get("gpg.format"))
        self.assertEqual(local.read_bytes(), original)
        self.setup_machine("personal")
        self.assertEqual(self.get("user.signingkey"), "PERSONAL-KEY")
        self.assertEqual(self.get("gpg.format"), "ssh")
        self.assertEqual(local.stat().st_mode & 0o777, 0o600)

    def test_local_overrides_preserved(self):
        path = self.write(".config/dotfiles/git/personal.local.gitconfig", "[alias]\n  mine = status\n[commit]\n  gpgsign = false\n")
        original = path.read_bytes()
        self.setup_machine()
        self.setup_machine()
        self.assertEqual(path.read_bytes(), original)
        self.assertEqual(self.get("alias.mine"), "status")
        self.assertEqual(self.get("commit.gpgsign"), "false")

    def test_old_symlink_backup_is_frozen(self):
        repo = self.home / "old checkout"
        for relative in ("scripts/setup-machine.py", "git/.gitconfig", "git/personal.gitconfig", "git/work.gitconfig",
                         "terminal/zellij/config.kdl", "terminal/zellij/layouts/default.kdl", "terminal/zellij/layouts/dev.kdl"):
            path = repo / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(REPO / relative, path)
        source = repo / "git/.gitconfig"
        original = "[user]\n  email = gauravkeswani92@gmail.com\n  signingkey = ORIGINAL-KEY\n"
        source.write_text(original)
        (self.home / ".gitconfig").symlink_to(source)
        self.setup_machine(repo=repo)
        backup = next((self.home / ".dotfiles-backup").glob("machine-*/.gitconfig"))
        self.assertFalse(backup.is_symlink())
        source.write_text("[core]\n  editor = vim\n")
        self.assertEqual(backup.read_text(), original)
        self.assertEqual(self.get("user.signingkey"), "ORIGINAL-KEY")

    def test_unknown_config_conflict_and_dry_run_never_modify_files(self):
        self.write(".gitconfig", "[user]\n  email = custom@example.com\n")
        before = self.snapshot()
        self.setup_machine(ok=False)
        self.assertEqual(before, self.snapshot())
        self.setup_machine("personal", "--dry-run")
        self.assertEqual(before, self.snapshot())

    def test_invalid_config_and_symlinked_local_overrides_fail_preflight(self):
        root = self.write(".gitconfig", "[invalid\n")
        before = self.snapshot()
        self.setup_machine("personal", "--replace-conflicts", ok=False)
        self.assertEqual(before, self.snapshot())
        root.unlink()
        local = self.home / ".config/dotfiles/git/personal.local.gitconfig"
        local.parent.mkdir(parents=True)
        local.symlink_to(REPO / "git/personal.gitconfig")
        before = self.snapshot()
        self.setup_machine(ok=False)
        self.assertEqual(before, self.snapshot())

    def test_custom_layouts_preserved_and_owned_work_links_archived(self):
        custom = self.write(".config/zellij/layouts/custom.kdl", "layout {}\n")
        self.setup_machine("work")
        self.setup_machine("personal")
        self.assertEqual(custom.read_text(), "layout {}\n")
        for name in ("bp-full", "bp-orgs-only"):
            self.assertFalse((self.home / f".config/zellij/layouts/{name}.kdl").exists())
            self.assertFalse((self.home / f".config/zellij/{name}.kdl").exists())
        self.assertTrue(list((self.home / ".dotfiles-backup").glob("machine-*/.config/zellij/layouts/bp-full.kdl")))

    def test_config_only_installs_both_using_saved_role(self):
        self.write(".config/dotfiles/profile", "personal\n")
        result = self.install("--config-only")
        self.assertNotIn("brew", result.stdout)
        self.assertEqual(self.get("user.email"), "gauravkeswani92@gmail.com")
        self.assertTrue((self.home / ".pi/agent/skills/mermaid").is_symlink())
        before = self.snapshot()
        self.install("--config-only")
        self.assertEqual(before, self.snapshot())

    def test_config_only_applies_work_role_consistently(self):
        self.write(".config/dotfiles/profile", "personal\n")
        self.install("--config-only")
        personal_settings = self.home / ".pi/agent/settings.json"
        original = personal_settings.read_bytes()
        self.write(".config/dotfiles/profile", "work\n")
        self.install("--config-only")
        self.assertEqual(self.get("dotfiles.profile"), "work")
        self.assertEqual(self.get("user.email"), "gaurav.keswani@shopify.com")
        settings = json.loads((self.home / ".pi/agent-shopify/settings.json").read_text())
        self.assertEqual(settings["defaultModel"], "claude-opus-5-5")
        self.assertEqual(personal_settings.read_bytes(), original)

    def test_plain_dry_run_previews_configuration_once_without_changes(self):
        self.write(".config/dotfiles/profile", "personal\n")
        before = self.snapshot()
        result = self.install("--dry-run")
        self.assertEqual(result.stdout.count("Machine configuration: personal"), 1)
        self.assertEqual(result.stdout.count("Machine: personal; Pi directory:"), 1)
        self.assertEqual(before, self.snapshot())

    def test_ai_only_cannot_desynchronize_existing_git_role(self):
        self.write(".config/dotfiles/profile", "personal\n")
        self.install("--config-only")
        self.write(".config/dotfiles/profile", "work\n")
        before = self.snapshot()
        result = self.install("--ai-only", ok=False)
        self.assertIn("--config-only --reconfigure-profile", result.stderr)
        self.assertEqual(before, self.snapshot())

    def test_all_preflights_run_before_git_or_ai_changes(self):
        self.write(".config/dotfiles/profile", "personal\n")
        self.write(".pi/agent/settings.json", "not json")
        before = self.snapshot()
        self.install("--config-only", ok=False)
        self.assertEqual(before, self.snapshot())
        self.assertFalse((self.home / ".gitconfig").exists())


if __name__ == "__main__":
    unittest.main()
