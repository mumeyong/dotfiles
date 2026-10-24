#!/usr/bin/env bash
# Restore mumeyong's Hyprland dotfiles on a fresh Debian install.
#
#   bash install.sh              # packages + dotfiles + mumeyong shell (Hyprland already installed)
#   bash install.sh --hyprland   # also build/install Hyprland first (fresh system)
#
# Options:
#   --hyprland      Run the Debian-Hyprland installer before restoring dotfiles
#   --no-packages   Skip apt packages
#   --no-shell      Skip the mumeyong shell (Ambxst) setup
#   --https         Clone over HTTPS instead of SSH (asks for GitHub username + token)
#   -h, --help      Show this help
set -euo pipefail

REPO_SSH="git@github.com:mumeyong/dotfiles.git"
REPO_HTTPS="https://github.com/mumeyong/dotfiles.git"
UPSTREAM_INSTALLER="https://github.com/LinuxBeginnings/Debian-Hyprland.git"
DOTDIR="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
PACKAGES=(git curl rsync inotify-tools jq stress-ng power-profiles-daemon lm-sensors libnotify-bin pkexec python3)

# mumeyong shell = Ambxst (https://github.com/Axenide/Ambxst, AGPL-3.0) + the
# rebrand patch in .github/ambxst/. Versions are pinned so the patch applies.
AMBXST_REPO="https://github.com/Axenide/Ambxst.git"
AMBXST_VERSION="1.3.14"
AXCTL_VERSION="v0.0.31"
MATUGEN_VERSION="4.2.0"
PHOSPHOR_VERSION="2.1.2"
NERDFONTS_VERSION="v3.5.1"
LEAGUE_GOTHIC_VERSION="1.601"
SHELL_SRC="$HOME/.local/src/ambxst"
# quickshell (and a newer tmux) come from trixie-backports
SHELL_PACKAGES=(fuzzel tmux zenity wlsunset sqlite3 tesseract-ocr tesseract-ocr-eng
  qt6-image-formats-plugins qml6-module-org-kde-syntaxhighlighting breeze-icon-theme
  qml6-module-qtmultimedia qt6-svg-plugins qt6-wayland qml6-module-qtquick-effects
  qml6-module-qt5compat-graphicaleffects gstreamer1.0-plugins-good gstreamer1.0-plugins-bad
  gstreamer1.0-libav brightnessctl ddcutil playerctl wtype upower ffmpeg unzip wl-clipboard
  network-manager bluez power-profiles-daemon fonts-roboto fonts-noto-core fonts-noto-cjk
  fonts-noto-color-emoji fonts-liberation fonts-dejavu fonts-terminus xz-utils)

with_hyprland=0
with_packages=1
with_shell=1
repo="${DOTFILES_REPO:-$REPO_SSH}"   # DOTFILES_REPO overrides (e.g. for testing)

for arg in "$@"; do
  case "$arg" in
    --hyprland) with_hyprland=1 ;;
    --no-packages) with_packages=0 ;;
    --no-shell) with_shell=0 ;;
    --https) repo="$REPO_HTTPS" ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

# 2. Hyprland (optional) ------------------------------------------------------
# Debian doesn't ship Hyprland >= 0.56 (needed for the Lua config); Debian-Hyprland builds it.
if [ "$with_hyprland" -eq 1 ]; then
  step "Installing Hyprland via Debian-Hyprland (interactive)"
  echo "Answer the installer's questions. The KoolDots dotfiles it offers are NOT needed"
  echo "(say No); if you say Yes anyway, your dotfiles are restored on top afterwards."
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

# 5. mumeyong shell (Ambxst + rebrand) ----------------------------------------
fetch() { curl -fsSL --retry 3 -o "$2" "$1"; }

install_shell() {
  local tmp; tmp="$(mktemp -d)"
  SHELL_TMP="$tmp"; trap 'rm -rf "${SHELL_TMP:-}"' EXIT

  if [ "$with_packages" -eq 1 ]; then
    if ! grep -rqs 'trixie-backports' /etc/apt/sources.list /etc/apt/sources.list.d/; then
      step "Enabling trixie-backports (for quickshell)"
      echo "deb http://deb.debian.org/debian trixie-backports main" | sudo tee /etc/apt/sources.list.d/backports.list >/dev/null
      sudo apt-get update
    fi
    step "Installing shell packages"
    sudo apt-get install -y -t trixie-backports quickshell tmux
    sudo apt-get install -y "${SHELL_PACKAGES[@]}"
    sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon || warn "Could not enable a service"
  fi

  step "Installing ambxst $AMBXST_VERSION, axctl $AXCTL_VERSION, matugen $MATUGEN_VERSION to /usr/local/bin"
  local rel="https://github.com/Axenide/Ambxst/releases/download/$AMBXST_VERSION"
  fetch "$rel/ambxst-linux-amd64" "$tmp/ambxst-linux-amd64"
  fetch "$rel/SHA256SUMS" "$tmp/SHA256SUMS"
  (cd "$tmp" && sha256sum --check --ignore-missing SHA256SUMS)
  fetch "https://github.com/Axenide/axctl/releases/download/$AXCTL_VERSION/axctl_linux_amd64" "$tmp/axctl"
  fetch "https://github.com/InioX/matugen/releases/download/v$MATUGEN_VERSION/matugen-$MATUGEN_VERSION-x86_64.tar.gz" "$tmp/matugen.tar.gz"
  mkdir -p "$tmp/matugen" && tar -xzf "$tmp/matugen.tar.gz" -C "$tmp/matugen"
  sudo install -m 755 "$tmp/ambxst-linux-amd64" /usr/local/bin/ambxst
  sudo install -m 755 "$tmp/axctl" /usr/local/bin/axctl
  sudo install -m 755 "$(find "$tmp/matugen" -type f -name matugen | head -1)" /usr/local/bin/matugen

  step "Fetching Ambxst $AMBXST_VERSION source and applying the mumeyong rebrand"
  if [ ! -d "$SHELL_SRC/.git" ]; then
    mkdir -p "$(dirname "$SHELL_SRC")"
    git clone -q "$AMBXST_REPO" "$SHELL_SRC"
  fi
  git -C "$SHELL_SRC" fetch -q --tags origin
  if git -C "$SHELL_SRC" rev-parse -q --verify mumeyong >/dev/null; then
    echo "Branch 'mumeyong' already exists in $SHELL_SRC; leaving it as is."
  else
    git -C "$SHELL_SRC" checkout -q -b mumeyong "$AMBXST_VERSION"
    git -C "$SHELL_SRC" -c user.name="$(git config user.name || echo mumeyong)" \
      -c user.email="$(git config user.email || echo mumeyong@localhost)" \
      am -q --committer-date-is-author-date "$HOME/.github/ambxst/mumeyong-rebrand.patch"
  fi
  mkdir -p "$HOME/.local/share/ambxst"
  echo "$SHELL_SRC" > "$HOME/.local/share/ambxst/shell_repo"
  # Seed the compositor config so the first login already gets binds/theme
  # (axctl only watches this file if it exists when it starts).
  [ -f "$HOME/.local/share/ambxst/axctl.toml" ] || cp "$HOME/.github/ambxst/axctl.toml.seed" "$HOME/.local/share/ambxst/axctl.toml"

  step "Installing fonts (Phosphor icons, Nerd Font symbols, League Gothic)"
  local fonts="$HOME/.local/share/fonts"
  mkdir -p "$fonts/phosphor" "$fonts/nerd-symbols" "$fonts/league-gothic"
  fetch "https://github.com/phosphor-icons/web/archive/refs/tags/v$PHOSPHOR_VERSION.zip" "$tmp/phosphor.zip"
  unzip -q -o "$tmp/phosphor.zip" -d "$tmp/phosphor"
  find "$tmp/phosphor" -name '*.ttf' -exec cp {} "$fonts/phosphor/" \;
  fetch "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERDFONTS_VERSION/NerdFontsSymbolsOnly.tar.xz" "$tmp/nf.tar.xz"
  mkdir -p "$tmp/nf" && tar -xJf "$tmp/nf.tar.xz" -C "$tmp/nf" && cp "$tmp"/nf/*.ttf "$fonts/nerd-symbols/"
  fetch "https://github.com/theleagueof/league-gothic/releases/download/$LEAGUE_GOTHIC_VERSION/LeagueGothic-$LEAGUE_GOTHIC_VERSION.tar.xz" "$tmp/lg.tar.xz"
  mkdir -p "$tmp/lg" && tar -xJf "$tmp/lg.tar.xz" -C "$tmp/lg"
  find "$tmp/lg" \( -name '*.otf' -o -name '*.ttf' \) ! -iname '*variable*' -exec cp {} "$fonts/league-gothic/" \;
  fc-cache -f "$fonts" >/dev/null
}

if [ "$with_shell" -eq 1 ]; then
  install_shell
fi

# 6. Finish -------------------------------------------------------------------
step "Final touches"
if command -v hyprctl >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
  hyprctl reload >/dev/null 2>&1 && echo "Reloaded running Hyprland."
fi

cat <<EOF

Done. Next steps:
  * Log out and log back into Hyprland (or reboot). The mumeyong shell starts by itself.
  * Open a new terminal so the 'dotfiles' alias from ~/.zshrc is available.
  * Previous files (if any) were saved in: ${BACKUP_DIR}
  * Optional SDDM login theme: see "Optional: SDDM theme" in ~/.github/README.md
EOF
