"""Check non-AI work integrations against the same saved machine profile."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]


class WorkGateTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles gates test ")
        self.home = Path(self.temp.name)
        (self.home / "dotfiles").symlink_to(REPO)
        self.env = dict(os.environ, HOME=str(self.home), DOTFILES_MACHINE_PROFILE="work", SPIN="1")
        self.profile = self.home / ".config/dotfiles/profile"
        self.profile.parent.mkdir(parents=True)

    def tearDown(self):
        self.temp.cleanup()

    def role(self, profile):
        self.profile.write_text(profile + "\n")

    def run_shell(self, shell, code):
        result = subprocess.run([shell, "-e" if shell == "ruby" else "-c", code], env=self.env, cwd=self.home, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result.stdout.strip()

    @unittest.skipUnless(shutil.which("zsh"), "zsh is not installed")
    def test_bp_aliases_use_saved_role_and_clear_on_reload(self):
        self.role("work")
        code = f'''source "{REPO}/terminal/zellij/aliases.zsh"
(( $+aliases[bp-full-local-dev] )) || exit 1
print -r -- personal > "$HOME/.config/dotfiles/profile"
source "{REPO}/terminal/zellij/aliases.zsh"
(( $+aliases[bp-full-local-dev] || $+aliases[zjbpfull] )) && exit 2
(( $+aliases[zjdev] )) || exit 3
'''
        self.run_shell("zsh", code)

    @unittest.skipUnless(shutil.which("zsh"), "zsh is not installed")
    def test_spin_shell_path_is_work_only(self):
        # Run just the startup path/profile block, without Oh-My-Zsh or external tools.
        prefix = (REPO / "shell/.zshrc").read_text().split("# Set name of the theme", 1)[0]
        self.role("personal")
        self.assertEqual(self.run_shell("zsh", prefix + '\nprintf "%s" "$ZSH"'), str(self.home / ".oh-my-zsh"))
        self.role("work")
        self.assertEqual(self.run_shell("zsh", prefix + '\nprintf "%s" "$ZSH"'), "/home/spin/.oh-my-zsh")

    def test_personal_quick_demo_installer_does_not_install(self):
        self.role("personal")
        nvm = self.home / "nvm"
        nvm.mkdir()
        (nvm / "nvm.sh").write_text('touch "$HOME/nvm-was-loaded"\n')
        result = subprocess.run(["bash", str(REPO / "quick-demo/install.sh")], cwd=self.home,
                                env=dict(self.env, NVM_DIR=str(nvm)), text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("work-only", result.stdout)
        self.assertFalse((self.home / "nvm-was-loaded").exists())

    def test_standalone_zellij_installer_uses_saved_role(self):
        self.role("personal")
        binary = self.home / "bin/zellij"
        binary.parent.mkdir()
        binary.write_text("#!/bin/sh\nexit 0\n")
        binary.chmod(0o755)
        root = self.home / ".gitconfig"
        root.write_text("[user]\n  email = unchanged@example.com\n")
        result = subprocess.run(["bash", str(REPO / "terminal/zellij/install-zellij.sh")], cwd=self.home,
                                env=dict(self.env, PATH=str(binary.parent) + os.pathsep + self.env["PATH"]),
                                text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertFalse((self.home / ".config/zellij/layouts/bp-full.kdl").exists())
        self.assertEqual(root.read_text(), "[user]\n  email = unchanged@example.com\n")

    @unittest.skipUnless(shutil.which("ruby"), "ruby is not installed")
    def test_pry_spin_stack_filter_only_applies_on_work(self):
        text = (REPO / "ruby/.pryrc").read_text()
        block = text.split("# == CLEANER STACKTRACE", 1)[1].split("# === HISTORY ===", 1)[0]
        entries = ["/home/spin/src/github.com/Shopify/shopify/components/test.rb:1", "/personal/project/test.rb:1"]
        script = f"def caller; {entries!r}; end\n" + block + '\nputs bt.join("|")'
        self.role("personal")
        self.assertEqual(self.run_shell("ruby", script), "|".join(entries))
        self.role("work")
        self.assertEqual(self.run_shell("ruby", script), entries[0])


if __name__ == "__main__":
    unittest.main()
