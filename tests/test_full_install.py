"""Run full macOS installer control flow offline; package/network commands are mocks."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

REPO = Path(__file__).resolve().parents[1]
REAL_GIT = shutil.which("git")


class FullInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="dotfiles full test ")
        self.home = Path(self.temp.name)
        (self.home / "dotfiles").symlink_to(REPO)
        self.bin = self.home / "mock-bin"
        self.bin.mkdir()
        self.log = self.home / "commands.log"
        self.env = {k: v for k, v in os.environ.items() if not k.startswith("GIT_")}
        for key in ("ZSH_CUSTOM", "BASH_ENV"):
            self.env.pop(key, None)
        self.env.update(HOME=str(self.home), GIT_CONFIG_NOSYSTEM="1", SHELL="/bin/zsh",
                        PATH=str(self.bin) + os.pathsep + os.environ["PATH"], NVM_DIR=str(self.home / "nvm"))
        self.executable("brew", '''#!/bin/sh
printf 'brew %s\n' "$*" >> "$HOME/commands.log"
if [ "$FAIL_FONT_INSTALL" = 1 ]; then
  if [ "$1" = list ] && [ "$2" = --cask ]; then exit 1; fi
  if [ "$1" = install ]; then exit 27; fi
fi
exit 0
''')
        self.executable("git", f'''#!/bin/sh
if [ "$1" = clone ]; then
  printf 'git %s\\n' "$*" >> "$HOME/commands.log"
  [ "$FAIL_CLONE" != 1 ] || exit 23
  for dest; do :; done
  mkdir -p "$dest"
  case "$*" in
    *ohmyzsh/ohmyzsh.git*) mkdir -p "$dest/custom"; printf '# framework mock\\n' > "$dest/oh-my-zsh.sh" ;;
  esac
  exit 0
fi
exec "{REAL_GIT}" "$@"
''')
        self.executable("sudo", '#!/bin/sh\necho "Unexpected sudo" >&2\nexit 99\n')
        for command in ("starship", "zoxide", "fzf", "eza", "bat", "fd", "atuin", "lazygit", "btop", "gum", "quick"):
            self.executable(command, "#!/bin/sh\nexit 0\n")

    def tearDown(self):
        self.temp.cleanup()

    def executable(self, name, content):
        path = self.bin / name
        path.write_text(content)
        path.chmod(0o755)

    def run_script(self, path, *args, ok=True, env=None):
        # Force the macOS branch even when tests run on Linux.
        command = ["bash", "-c", 'script=$1; shift; OSTYPE=darwin; source "$script" "$@"', "test", str(path), *args]
        result = subprocess.run(command, env=env or self.env, cwd=self.home,
                                text=True, capture_output=True, start_new_session=True)
        self.assertEqual(result.returncode == 0, ok, result.stdout + result.stderr)
        return result

    def role(self, value):
        path = self.home / ".config/dotfiles/profile"
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(value + "\n")

    def test_full_install_both_roles_and_reruns(self):
        sources = [REPO / "shell/.zshrc", REPO / "terminal/zoxide/config.zsh"]
        original = {p: p.read_bytes() for p in sources}
        for role in ("personal", "work"):
            with self.subTest(role=role):
                self.role(role)
                result = self.run_script(REPO / "install.sh")
                self.assertIn("Installation Complete!", result.stdout)
                self.assertIn("0 failed", result.stdout)
                self.assertEqual("Setting up Quick Demo CLI" in result.stdout, role == "work")
                self.assertEqual((self.home / ".config/zellij/layouts/bp-full.kdl").exists(), role == "work")
                self.assertTrue((self.home / ".local/bin/git-credit").is_symlink())
                self.assertIn("brew list bat", self.log.read_text())
                if role == "work":
                    self.assertEqual((self.home / ".local/bin/demo").resolve(), REPO / "quick-demo/demo")
                before = self.log.read_text()
                self.run_script(REPO / "install.sh")
                added = self.log.read_text()[len(before):]
                self.assertNotIn("git clone", added)
                self.assertNotIn("brew install", added)
        self.assertEqual(original, {p: p.read_bytes() for p in sources})

    def test_shared_config_conflict_prevents_installs(self):
        self.role("personal")
        custom = self.home / ".vimrc"
        custom.write_text('" preserve my settings\n')
        result = self.run_script(REPO / "install.sh", ok=False)
        self.assertIn("Conflict:", result.stdout)
        self.assertEqual(custom.read_text(), '" preserve my settings\n')
        self.assertFalse(self.log.exists())
        self.assertFalse((self.home / ".gitconfig").exists())

    def test_shared_config_conflict_is_archived_with_consent(self):
        self.role("personal")
        custom = self.home / ".vimrc"
        custom.write_text('" preserve my settings\n')
        self.run_script(REPO / "install.sh", "--replace-conflicts")
        backup = next((self.home / ".dotfiles-backup").glob("machine-*/.vimrc"))
        self.assertEqual(backup.read_text(), '" preserve my settings\n')
        self.assertTrue(custom.is_symlink())

    def test_neovim_partial_links_do_not_hide_custom_directory_conflicts(self):
        self.role("personal")
        nvim = self.home / ".config/nvim"
        nvim.mkdir(parents=True)
        (nvim / "init.lua").symlink_to(REPO / "nvim/init.lua")
        custom = nvim / "lua/my-settings.lua"
        custom.parent.mkdir()
        custom.write_text("return { preserve = true }\n")
        self.run_script(REPO / "install.sh", ok=False)
        self.assertEqual(custom.read_text(), "return { preserve = true }\n")
        self.assertFalse(self.log.exists())
        self.run_script(REPO / "install.sh", "--replace-conflicts")
        backup = next((self.home / ".dotfiles-backup").glob("machine-*/.config/nvim/lua/my-settings.lua"))
        self.assertEqual(backup.read_text(), "return { preserve = true }\n")
        self.assertTrue((nvim / "lua").is_symlink())

    def test_identical_legacy_vim_color_copy_migrates_safely(self):
        self.role("personal")
        source = next((REPO / "vim/colors").glob("*.vim"))
        dest = self.home / ".vim/colors" / source.name
        dest.parent.mkdir(parents=True)
        shutil.copy2(source, dest)
        self.run_script(REPO / "install.sh")
        self.assertTrue(dest.is_symlink())
        backup = next((self.home / ".dotfiles-backup").glob(f"machine-*/.vim/colors/{source.name}"))
        self.assertEqual(backup.read_bytes(), source.read_bytes())

    def test_partial_oh_my_zsh_repairs_without_rewriting_zshrc(self):
        self.role("personal")
        custom = self.home / ".oh-my-zsh/custom/plugins/mine/settings"
        custom.parent.mkdir(parents=True)
        custom.write_text("my plugin settings")
        zshrc = self.home / ".zshrc"
        zshrc.write_text("my shell settings\n")
        self.run_script(REPO / "scripts/setup-oh-my-zsh.sh")
        self.assertTrue((self.home / ".oh-my-zsh/oh-my-zsh.sh").is_file())
        self.assertEqual(custom.read_text(), "my plugin settings")
        self.assertEqual(zshrc.read_text(), "my shell settings\n")
        self.assertTrue(list((self.home / ".dotfiles-backup").glob("oh-my-zsh.*/.oh-my-zsh/custom/plugins/mine/settings")))
        before = self.log.read_text()
        self.run_script(REPO / "scripts/setup-oh-my-zsh.sh")
        self.assertEqual(before, self.log.read_text())

    def test_failed_framework_clone_preserves_partial_install(self):
        custom = self.home / ".oh-my-zsh/custom/mine"
        custom.parent.mkdir(parents=True)
        custom.write_text("keep")
        self.run_script(REPO / "scripts/setup-oh-my-zsh.sh", env=dict(self.env, FAIL_CLONE="1"), ok=False)
        self.assertEqual(custom.read_text(), "keep")
        self.assertFalse((self.home / ".dotfiles-backup").exists())

    def test_failed_font_install_propagates(self):
        result = self.run_script(REPO / "terminal/fonts/install-fonts.sh", env=dict(self.env, FAIL_FONT_INSTALL="1"), ok=False)
        self.assertNotIn("Font installation complete!", result.stdout)

    def test_failed_verification_does_not_claim_success(self):
        self.role("personal")
        bash_env = self.home / "bash-env"
        bash_env.write_text('command() { if [ "$*" = "-v lazygit" ]; then return 1; fi; builtin command "$@"; }\n')
        result = self.run_script(REPO / "install.sh", env=dict(self.env, BASH_ENV=str(bash_env)), ok=False)
        self.assertIn("lazygit not found", result.stdout)
        self.assertNotIn("Installation Complete!", result.stdout)


if __name__ == "__main__":
    unittest.main()
