# mumeyong's dotfiles

My Hyprland desktop on **Debian 13 (trixie)**. It's based on [KoolDots](https://github.com/LinuxBeginnings) and installed with [Debian-Hyprland](https://github.com/LinuxBeginnings/Debian-Hyprland). My own customizations are layered on top.

The repo is a **bare git repo**. Files are tracked where they live in `$HOME`, so there are no symlinks and nothing gets moved.

## What's inside

| Path | What |
|---|---|
| `.config/hypr/` | Hyprland Lua config, scripts, rofi themes, wallust templates |
| `.config/waybar/` | Waybar layouts, modules, styles |
| `.config/kitty/`, `.config/ghostty/` | Terminals |
| `.config/swaync/` | Notifications |
| `.config/quickshell/` | Overview / hyprview |
| `.config/cava/`, `.config/qt5ct/`, `.config/qt6ct/`, `.config/gtk-3.0/`, `.config/gtk-4.0/` | Theming |
| `.zshrc` | Shell, including the `dotfiles` alias |
| `.dotfiles-ignore` | Files kept out of the repo on purpose (installer binary, wallpaper cache, backups) |

### My customizations (vs. stock KoolDots)
- **Power menu:** left-click the waybar battery icon to switch power profile, set fans to full/auto, or set the CPU power limit to 45W/65W. Files: `hypr/scripts/PowerMenu.sh`, `PowerMenuHelper.sh`.
- **Faster login, with no reload storm:**
  - `LuaAutoReload.sh` starts 5s after login.
  - `PersistWorkspaceLayout.sh` skips writing when nothing changed.
  - `WallustSwww.sh` reloads only when the colors changed.
  - `DarkLight.sh --no-wallust` avoids generating the colors twice.
- **Lighter rendering:** blur uses 2 passes. The Qt module scan is cached per boot.

---

## Fresh install: one script

### 0. Give GitHub access to the new machine (the repo is private)
```bash
sudo apt install -y git openssh-client
ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)"
cat ~/.ssh/id_ed25519.pub     # paste at https://github.com/settings/keys
ssh -T git@github.com         # should say "Hi mumeyong!"
```
No SSH key? Use `--https` below, with a [personal access token](https://github.com/settings/tokens) as the password.

### 1. Fetch the script and run it
```bash
git clone git@github.com:mumeyong/dotfiles.git /tmp/dotfiles-bootstrap
bash /tmp/dotfiles-bootstrap/.github/install.sh --hyprland
```

| Situation | Command |
|---|---|
| Brand-new Debian, no Hyprland yet | `install.sh --hyprland` |
| Hyprland/KoolDots already installed | `install.sh` |
| No SSH key, use a token | add `--https` |
| Skip apt packages | add `--no-packages` |

What the script does:
1. Installs helper packages: `git curl rsync inotify-tools jq stress-ng power-profiles-daemon lm-sensors libnotify-bin pkexec python3`.
2. With `--hyprland`: clones Debian-Hyprland and runs its **interactive** installer. Say **yes** to installing the KoolDots dotfiles.
3. Clones this repo as a bare repo into `~/.dotfiles`.
4. **Backs up** every file it's about to overwrite to `~/.dotfiles-backup-<date>/`.
5. Checks out my dotfiles on top of the stock KoolDots files, so my changes win.
6. Reloads Hyprland if it's running.

Then log out and log back in.

### Optional: SDDM theme
The login screen uses [sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme). It's a system file, so it isn't in this repo:
```bash
git clone --depth=1 https://github.com/Keyitdev/sddm-astronaut-theme.git ~/sddm-astronaut-theme
cd ~/sddm-astronaut-theme && sudo ./setup.sh
```

---

## Daily use

`dotfiles` works exactly like `git`. It only shows files that are already tracked.

```bash
dotfiles status                          # what changed
dotfiles diff                            # see the changes
dotfiles add -u                          # stage all tracked changes
dotfiles commit -m "tweak waybar"
dotfiles push

dotfiles add ~/.config/fastfetch         # start tracking something new
dotfiles rm --cached ~/.config/foo -r    # stop tracking (keeps the file)
```

### After a KoolDots upgrade overwrites my stuff
```bash
dotfiles status                                   # which of my files changed
dotfiles diff ~/.config/waybar/Modules            # what the upgrade did
dotfiles checkout -- ~/.config/waybar/Modules     # put mine back
```

## Troubleshooting
- **`dotfiles: command not found`:** open a new terminal or run `source ~/.zshrc`. Without the alias, use `git --git-dir=$HOME/.dotfiles --work-tree=$HOME …`.
- **Battery-click menu does nothing:** check that `"on-click": "$HOME/.config/hypr/scripts/PowerMenu.sh"` is in the `battery` block of `~/.config/waybar/Modules`.
- **Something broke after restore:** your previous files are in `~/.dotfiles-backup-<date>/`.
