#!/usr/bin/env bash
# Restore mumeyong's Hyprland dotfiles on a fresh Debian install.
#
#   bash install.sh              # packages + dotfiles (Hyprland already installed)
#   bash install.sh --hyprland   # also build/install Hyprland + KoolDots first (fresh system)
#
# Options:
#   --hyprland      Run the Debian-Hyprland (KoolDots) installer before restoring dotfiles
#   --no-packages   Skip apt packages
#   --https         Clone over HTTPS instead of SSH (asks for GitHub username + token)
#   -h, --help      Show this help
set -euo pipefail

REPO_SSH="git@github.com:mumeyong/dotfiles.git"
REPO_HTTPS="https://github.com/mumeyong/dotfiles.git"
UPSTREAM_INSTALLER="https://github.com/LinuxBeginnings/Debian-Hyprland.git"
DOTDIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
PACKAGES=(git curl rsync inotify-tools jq stress-ng power-profiles-daemon lm-sensors libnotify-bin pkexec python3)

with_hyprland=0
with_packages=1
repo="${DOTFILES_REPO:-$REPO_SSH}"   # DOTFILES_REPO overrides (e.g. for testing)

for arg in "$@"; do
  case "$arg" in
    --hyprland) with_hyprland=1 ;;
    --no-packages) with_packages=0 ;;
    --https) repo="$REPO_HTTPS" ;;
    -h|--help) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
dot() { git --git-dir="$DOTDIR" --work-tree="$HOME" "$@"; }

[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root (sudo is used when needed)." >&2; exit 1; }

if [ -r /etc/os-release ]; then
  . /etc/os-release
  [ "${ID:-}" = "debian" ] || warn "Made for Debian; detected '${ID:-unknown}'. Package step may fail."
fi

# 1. Packages ---------------------------------------------------------------
if [ "$with_packages" -eq 1 ]; then
  step "Installing packages: ${PACKAGES[*]}"
  sudo apt-get update
  sudo apt-get install -y "${PACKAGES[@]}"
  sudo systemctl enable --now power-profiles-daemon.service || warn "Could not enable power-profiles-daemon"
else
  command -v git >/dev/null || { echo "git is required (drop --no-packages)." >&2; exit 1; }
fi

# 2. Hyprland + KoolDots base (optional) --------------------------------------
if [ "$with_hyprland" -eq 1 ]; then
  step "Installing Hyprland + KoolDots via Debian-Hyprland (interactive)"
  echo "Answer the installer's questions. Say YES when it offers to install the KoolDots dotfiles;"
  echo "your personal dotfiles are restored on top afterwards."
  if [ ! -d "$HOME/Debian-Hyprland/.git" ]; then
    git clone --depth=1 "$UPSTREAM_INSTALLER" "$HOME/Debian-Hyprland"
  fi
  (cd "$HOME/Debian-Hyprland" && chmod +x install.sh && ./install.sh)
fi

# 3. Clone the bare dotfiles repo ---------------------------------------------
step "Fetching dotfiles from $repo"
if [ -d "$DOTDIR" ]; then
  echo "$DOTDIR already exists; fetching latest instead of cloning."
else
  if [ "$repo" = "$REPO_SSH" ] && ! ssh -T -o BatchMode=yes -o StrictHostKeyChecking=accept-new git@github.com 2>&1 | grep -q "successfully authenticated"; then
    warn "SSH to GitHub is not set up on this machine."
    echo "  Either add an SSH key:  ssh-keygen -t ed25519 && cat ~/.ssh/id_ed25519.pub   (paste at github.com/settings/keys)"
    echo "  or re-run with --https and a personal access token as the password."
    exit 1
  fi
  git clone --bare "$repo" "$DOTDIR"
fi
# Bare clones have no remote-tracking refs; add them so origin/main exists.
dot config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
dot fetch -q origin
dot config status.showUntrackedFiles no
dot config core.excludesFile "$HOME/.dotfiles-ignore"

# 4. Back up files that would be overwritten, then check out ------------------
step "Backing up existing files to $BACKUP_DIR"
backed_up=0
while IFS= read -r path; do
  if [ -e "$HOME/$path" ] || [ -L "$HOME/$path" ]; then
    mkdir -p "$BACKUP_DIR/$(dirname "$path")"
    cp -a "$HOME/$path" "$BACKUP_DIR/$path"
    backed_up=$((backed_up + 1))
  fi
done < <(dot ls-tree -r --name-only origin/main)
echo "Backed up $backed_up file(s)."
[ "$backed_up" -gt 0 ] || rmdir "$BACKUP_DIR" 2>/dev/null || true

step "Restoring dotfiles into $HOME"
dot checkout -f -B main origin/main
dot branch -q --set-upstream-to=origin/main main

# 5. Finish -------------------------------------------------------------------
step "Final touches"
find "$HOME/.config/hypr/scripts" "$HOME/.config/hypr/UserScripts" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) -exec chmod +x {} + 2>/dev/null || true
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  hyprctl reload >/dev/null 2>&1 && echo "Reloaded running Hyprland."
fi

cat <<EOF

Done. Next steps:
  * Log out and log back into Hyprland (or reboot).
  * Open a new terminal so the 'dotfiles' alias from ~/.zshrc is available.
  * Previous files (if any) were saved in: ${BACKUP_DIR}
  * Optional SDDM login theme: see "Optional: SDDM theme" in ~/.github/README.md
EOF
