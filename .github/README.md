# mumeyong's dotfiles

My Hyprland desktop on **Debian 13 (trixie)**. Hyprland is built with [Debian-Hyprland](https://github.com/LinuxBeginnings/Debian-Hyprland). The desktop shell is **mumeyong**, my rebranded build of [Ambxst](https://github.com/Axenide/Ambxst) by Axenide. It gives me the dynamic-island notch, the bar, launcher, dashboard, notifications, lock screen and wallpaper theming.

The repo is a **bare git repo**. Files are tracked where they live in `$HOME`, so there are no symlinks and nothing gets moved.

## What's inside

| Path | What |
|---|---|
| `.config/hypr/hyprland.lua` | Hyprland config: monitors, workspaces, input, look, keybinds. Loads the shell's generated config at the end. |
| `.config/ambxst/` | mumeyong shell settings: bar, notch, theme, dock, lock screen, keybinds (`binds.json`) |
| `.cache/ambxst/wallpapers.json` | Which wallpaper and wallpaper folder the shell uses |
| `Pictures/wallpapers/wallhaven-6olgox.jpg` | The current wallpaper. The color theme is generated from it. |
| `.github/ambxst/mumeyong-rebrand.patch` | My changes on top of Ambxst 1.3.14: the name, the logo, and a smaller pin button in the bar. It holds one commit per change. |
| `.github/ambxst/axctl.toml.seed` | Starting compositor config, so the first login already has keybinds and theme |
| `.config/kitty/`, `.config/ghostty/` | Terminals |
| `.config/cava/`, `.config/qt5ct/`, `.config/qt6ct/`, `.config/gtk-3.0/`, `.config/gtk-4.0/` | Other theming |
| `.zshrc` | Shell, including the `dotfiles` alias |
| `.dotfiles-ignore` | Files kept out of the repo on purpose |

### About the mumeyong shell
- It is **Ambxst 1.3.14** plus `mumeyong-rebrand.patch`. The patch only changes what's on screen: the name "mumeyong", my logo, and small tweaks like a smaller pin button in the bar. The About entry still says *Based on Ambxst by Axenide*. Ambxst is AGPL-3.0, so that credit and the license files stay.
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
   - clones Ambxst 1.3.14 into `~/.local/src/ambxst` and applies the rebrand patch on a `mumeyong` branch
   - installs the fonts the shell needs (Phosphor icons, Nerd Font symbols, League Gothic) and the adw-gtk3 GTK theme, which the shell recolors to match the wallpaper
6. Reloads Hyprland if it's running.

Then log out and log back in. The shell starts by itself.

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
dotfiles commit -m "tweak notch"
dotfiles push

dotfiles add ~/.config/fastfetch         # start tracking something new
dotfiles rm --cached ~/.config/foo -r    # stop tracking (keeps the file)
```

### Shell shortcuts

| Keys | Action |
|---|---|
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
git format-patch --binary --stdout <new-version>..mumeyong > ~/.github/ambxst/mumeyong-rebrand.patch
```
Then update the matching `ambxst` binary. Set `AMBXST_VERSION` in `install.sh`, download that release's `ambxst-linux-amd64`, and `sudo install` it to `/usr/local/bin/ambxst`. Finally run `ambxst reload` and commit.

## Troubleshooting
- **`dotfiles: command not found`:** open a new terminal or run `source ~/.zshrc`. Without the alias, use `git --git-dir=$HOME/.dotfiles --work-tree=$HOME …`.
- **No shell keybinds after the first login:** run `ambxst quit && ambxst &`. This restarts its helper `axctl`, which regenerates `~/.local/share/ambxst/hyprland.lua`. Then run `hyprctl reload`.
- **Shell won't start:** run `ambxst` in a terminal to see the error. The log is in `/run/user/$(id -u)/quickshell/by-id/*/log.qslog`. You can read it with `qs log -p ~/.local/src/ambxst/shell.qml`.
- **Something broke after restore:** your previous files are in `~/.dotfiles-backup-<date>/`.
