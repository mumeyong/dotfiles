# mumeyong's dotfiles

My Hyprland desktop on **Debian 13 (trixie)**. Hyprland is built with [Debian-Hyprland](https://github.com/LinuxBeginnings/Debian-Hyprland). The desktop shell is **mumeyong**, my rebranded build of [Ambxst](https://github.com/Axenide/Ambxst) by Axenide. It gives me the dynamic-island notch, the bar, launcher, dashboard, notifications, lock screen and wallpaper theming.

The repo is a **bare git repo**. Files are tracked where they live in `$HOME`, so there are no symlinks and nothing gets moved.

## What's inside

| Path | What |
|---|---|
| `.config/hypr/hyprland.lua` | Hyprland config: monitors, workspaces, input, look, keybinds. Loads the shell's generated config at the end. |
| `.config/hypr/scripts/keyhints` | Builds the keybind list for the SUPER+H cheatsheet sidebar (also works standalone as a fuzzel popup) |
| `.config/ambxst/` | mumeyong shell settings: bar, notch, theme, dock, lock screen, keybinds (`binds.json`) |
| `.cache/ambxst/wallpapers.json` | Which wallpaper and wallpaper folder the shell uses |
| `Pictures/wallpapers/wallhaven-6olgox.jpg` | The current wallpaper. The color theme is generated from it. |
| `.config/ambxst-patches/` | My changes on top of Ambxst 1.3.14, one patch per change: the name and logo, a smaller pin button, the SUPER+H keybind cheatsheet sidebar (replaces the AI assistant), GTK theming fixes, the notch equalizer and media card, the macOS-style volume/brightness OSD in the top-right corner, and small upstream fixes |
| `.github/ambxst/axctl.toml.seed` | Starting compositor config, so the first login already has keybinds and theme |
| `.local/share/sddm-themes/mumeyong/` | mumeyong SDDM login theme, styled after the lock screen (adapted from Ambxst's lock screen, AGPL-3.0). Bundles League Gothic, Inter (OFL) and Phosphor (MIT) fonts, because SDDM can't read `~/.local/share/fonts`. |
| `.local/bin/sddm-wallpaper-sync`, `.config/systemd/user/sddm-wallpaper-sync.*` | Copies the current wallpaper, a blurred copy and the palette to the login screen whenever the wallpaper changes |
| `.github/sddm/install.sh` | One-time sudo setup for the login theme |
| `.config/kitty/`, `.config/ghostty/` | Terminals |
| `.config/cava/`, `.config/qt5ct/`, `.config/qt6ct/`, `.config/gtk-3.0/`, `.config/gtk-4.0/` | Other theming |
| `.zshrc` | Shell, including the `dotfiles` alias |
| `.dotfiles-ignore` | Files kept out of the repo on purpose |

### About the mumeyong shell
- It is **Ambxst 1.3.14** plus the patches in `.config/ambxst-patches/`. They change what's on screen: the name "mumeyong", my logo, a smaller pin button, the keybind cheatsheet in place of the AI assistant sidebar, how GTK apps like Thunar are themed, the notch's equalizer and media card, and the top-right volume/brightness OSD. The About entry still says *Based on Ambxst by Axenide*. Ambxst is AGPL-3.0, so that credit and the license files stay.
- Source: `~/.local/src/ambxst`, branch `mumeyong`.
- Programs: `/usr/local/bin/ambxst`, `axctl` and `matugen`. They are downloaded from GitHub releases and the versions are pinned in `install.sh`.
- Hyprland reads the shell's generated file `~/.local/share/ambxst/hyprland.lua` last. **My own keybinds in `hyprland.lua` always win.** Any key I've already bound is skipped from the shell's list.

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
| Hyprland 0.56+ already installed | `install.sh` |
| No SSH key, use a token | add `--https` |
| Skip apt packages | add `--no-packages` |
| Dotfiles only, no shell | add `--no-shell` |

What the script does:
1. Installs helper packages with apt.
2. With `--hyprland`: clones Debian-Hyprland and runs its **interactive** installer. Hyprland must be **0.56 or newer** for the Lua config. You don't need the KoolDots dotfiles it offers.
3. Clones this repo as a bare repo into `~/.dotfiles`.
4. **Backs up** every file it's about to overwrite to `~/.dotfiles-backup-<date>/`, then checks out my dotfiles.
5. Sets up the mumeyong shell:
   - enables `trixie-backports` and installs `quickshell` and the other shell packages
   - downloads `ambxst` (checksum-verified), `axctl` and `matugen` into `/usr/local/bin`
   - clones Ambxst 1.3.14 into `~/.local/src/ambxst` and applies the patches from `.config/ambxst-patches/` on a `mumeyong` branch
   - installs the fonts the shell needs (Phosphor icons, Nerd Font symbols, League Gothic) and the adw-gtk3 GTK theme, which the shell recolors to match the wallpaper
6. Reloads Hyprland if it's running.

Then log out and log back in. The shell starts by itself.

### Optional: SDDM theme
The login screen is **mumeyong**, my own SDDM theme. It looks like the shell's lock screen: blurred wallpaper, the big two-tone clock and the avatar + password pill, plus a small session/power pill. It follows the wallpaper automatically: whenever the shell's wallpaper or colors change, a user systemd unit copies the wallpaper, a blurred copy and the palette into the theme.
```bash
bash ~/.github/sddm/install.sh
```
The script needs sudo once. It installs the theme to `/usr/share/sddm/themes/mumeyong`, owned by you so later syncs need no sudo, and makes it the active theme in `/etc/sddm.conf`, keeping a `.bak` copy. It also enables `sddm-wallpaper-sync.path`. The theme has no on-screen keyboard, so the script also disables `/etc/sddm.conf.d/virtualkbd.conf` if it exists.

- Run a sync by hand: `sddm-wallpaper-sync`. Log: `journalctl --user -u sddm-wallpaper-sync`
- Preview without logging out: `sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/mumeyong` (it opens fullscreen; close it with `pkill sddm-greeter`)
- After editing the theme in `~/.local/share/sddm-themes/mumeyong`, copy it over: `cp -r ~/.local/share/sddm-themes/mumeyong/. /usr/share/sddm/themes/mumeyong/`
- Undo: `sudo mv /etc/sddm.conf.bak /etc/sddm.conf`

---

## Daily use

`dotfiles` works exactly like `git`. It only shows files that are already tracked.

```bash
dotfiles status                          # what changed
dotfiles diff                            # see the changes
dotfiles add -u                          # stage all tracked changes
dotfiles commit -m "tweak notch"
dotfiles push

dotfiles add ~/.config/fastfetch         # start tracking something new
dotfiles rm --cached ~/.config/foo -r    # stop tracking (keeps the file)
```

### Shell shortcuts

| Keys | Action |
|---|---|
| SUPER+H | Keybind cheatsheet sidebar (press again to close). Replaces the AI assistant sidebar. |
| SUPER+D | Launcher |
| SUPER+SHIFT+N | Dashboard |
| SUPER+SHIFT+E | Quick controls |
| SUPER+W | Wallpapers. Picking one also re-themes everything. |
| SUPER+ALT+V | Clipboard |
| SUPER+ALT+E | Emoji |
| ALT+Tab | Overview |
| SUPER+SHIFT+C | Shell settings |
| CTRL+ALT+P | Power menu |
| CTRL+ALT+L | Lock |

### Changing the shell's settings
Change things in the settings window (SUPER+SHIFT+C). It writes to `~/.config/ambxst/`. Then commit as usual:
```bash
dotfiles add -u && dotfiles commit -m "shell: new bar layout" && dotfiles push
```
If you change the wallpaper, also track the new image:
```bash
dotfiles add ~/Pictures/wallpapers/<new-wallpaper> ~/.cache/ambxst/wallpapers.json
```

### Updating the shell to a newer Ambxst
**Never run `ambxst update`.** It runs `git reset --hard` and would wipe the rebrand. Instead:
```bash
cd ~/.local/src/ambxst
git fetch --tags origin
git rebase --onto <new-version> 1.3.14 mumeyong     # fix conflicts if any
rm ~/.config/ambxst-patches/*.patch
git format-patch -o ~/.config/ambxst-patches <new-version>..mumeyong
```
Then update the matching `ambxst` binary. Set `AMBXST_VERSION` in `install.sh`, download that release's `ambxst-linux-amd64`, and `sudo install` it to `/usr/local/bin/ambxst`. Finally run `ambxst reload` and commit.

## Troubleshooting
- **`dotfiles: command not found`:** open a new terminal or run `source ~/.zshrc`. Without the alias, use `git --git-dir=$HOME/.dotfiles --work-tree=$HOME …`.
- **No shell keybinds after the first login:** run `ambxst quit && ambxst &`. This restarts its helper `axctl`, which regenerates `~/.local/share/ambxst/hyprland.lua`. Then run `hyprctl reload`.
- **Shell won't start:** run `ambxst` in a terminal to see the error. The log is in `/run/user/$(id -u)/quickshell/by-id/*/log.qslog`. You can read it with `qs log -p ~/.local/src/ambxst/shell.qml`.
- **Something broke after restore:** your previous files are in `~/.dotfiles-backup-<date>/`.
