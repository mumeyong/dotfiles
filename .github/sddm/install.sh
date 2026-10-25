#!/usr/bin/env bash
# Install the mumeyong SDDM login theme and keep it synced with the wallpaper.
#
#   bash ~/.github/sddm/install.sh
#
# Copies ~/.local/share/sddm-themes/mumeyong to /usr/share/sddm/themes/mumeyong
# (owned by you, so later syncs need no sudo), makes it the active SDDM theme,
# and enables the sddm-wallpaper-sync.path user unit.
set -euo pipefail

THEME_SRC="$HOME/.local/share/sddm-themes/mumeyong"
THEME_DST="/usr/share/sddm/themes/mumeyong"
CACHE_DIR="/var/cache/sddm-wallpaper"
SDDM_CONF="/etc/sddm.conf"
PACKAGES=(sddm jq imagemagick ffmpeg qml6-module-qtquick-controls qml6-module-qtquick-layouts
  qml6-module-qtquick-effects)

step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }

[ "$(id -u)" -ne 0 ] || { echo "Run as your normal user, not root (sudo is used when needed)." >&2; exit 1; }
[ -f "$THEME_SRC/Main.qml" ] || { echo "Theme not found at $THEME_SRC (restore the dotfiles first)." >&2; exit 1; }

step "Installing packages: ${PACKAGES[*]}"
sudo apt-get install -y "${PACKAGES[@]}"

step "Installing theme to $THEME_DST"
sudo install -d -o "$USER" -m 755 "$THEME_DST" "$CACHE_DIR"
cp -r "$THEME_SRC"/. "$THEME_DST"/
rm -f "$THEME_DST/theme.conf.user"
install -m 644 /dev/null "$THEME_DST/theme.conf.user"

step "Making mumeyong the active SDDM theme"
[ -f "$SDDM_CONF.bak" ] || sudo cp -a "$SDDM_CONF" "$SDDM_CONF.bak" 2>/dev/null || true
if sudo grep -qE '^\s*Current=' "$SDDM_CONF" 2>/dev/null; then
  sudo sed -i 's/^\(\s*Current=\).*/\1mumeyong/' "$SDDM_CONF"
else
  printf '[Theme]\nCurrent=mumeyong\n' | sudo tee -a "$SDDM_CONF" >/dev/null
fi
# The theme has no on-screen keyboard; Qt would otherwise pop up its own window
if [ -f /etc/sddm.conf.d/virtualkbd.conf ]; then
  sudo mv /etc/sddm.conf.d/virtualkbd.conf /etc/sddm.conf.d/virtualkbd.conf.disabled
fi

step "Enabling wallpaper sync"
systemctl --user daemon-reload
systemctl --user enable --now sddm-wallpaper-sync.path
"$HOME/.local/bin/sddm-wallpaper-sync"

echo
echo "Done. The login screen now follows your wallpaper. Undo: sudo mv $SDDM_CONF.bak $SDDM_CONF"
