#!/usr/bin/env bash
# Power / thermal menu for the waybar battery module (left-click).
# Power profiles use powerprofilesctl (no root). Fan mode and CPU power
# limit go through PowerMenuHelper.sh via pkexec (polkit password prompt).

scriptsDir="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/scripts"
helper="$scriptsDir/PowerMenuHelper.sh"
rofi_theme="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/rofi/config-Monitors.rasi"

if pidof rofi >/dev/null; then
  pkill rofi
fi

asus_hwmon() {
  local d
  for d in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$d/name" 2>/dev/null)" = "asus" ] && { echo "$d"; return; }
  done
}

coretemp_hwmon() {
  local d
  for d in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$d/name" 2>/dev/null)" = "coretemp" ] && { echo "$d"; return; }
  done
}

status_line() {
  local hw ct profile temp fans="n/a" fanmode="n/a" pl="n/a" bat
  hw="$(asus_hwmon)"
  ct="$(coretemp_hwmon)"
  profile="$(powerprofilesctl get 2>/dev/null || echo unknown)"
  temp="$(( $(cat "$ct/temp1_input" 2>/dev/null || echo 0) / 1000 ))°C"
  if [ -n "$hw" ]; then
    fans="$(cat "$hw/fan1_input" 2>/dev/null)/$(cat "$hw/fan2_input" 2>/dev/null) RPM"
    case "$(cat "$hw/pwm1_enable" 2>/dev/null)" in
      0) fanmode="full" ;;
      2) fanmode="auto" ;;
    esac
  fi
  local rapl=/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
  [ -r "$rapl" ] && pl="$(( $(cat "$rapl") / 1000000 ))W"
  bat="$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null)% $(cat /sys/class/power_supply/BAT0/status 2>/dev/null)"
  printf '%s | %s | fans %s (%s) | limit %s | bat %s' "$profile" "$temp" "$fans" "$fanmode" "$pl" "$bat"
}

mark() { [ "$1" = "$2" ] && printf ' ✓'; }

current_profile="$(powerprofilesctl get 2>/dev/null)"
options="󰓅  Performance$(mark "$current_profile" performance)
󰾅  Balanced$(mark "$current_profile" balanced)
󰾆  Power saver$(mark "$current_profile" power-saver)
󰈐  Fans: full speed
󰈐  Fans: auto
  CPU limit: 45W (cooler, quieter)
  CPU limit: 65W (default)"

choice="$(printf '%s\n' "$options" | rofi -i -dmenu -config "$rofi_theme" -p "Power" -mesg "$(status_line)")"
[ -n "$choice" ] || exit 0

run_root() {
  if pkexec "$helper" "$@"; then
    return 0
  fi
  notify-send -u critical -a PowerMenu "Power menu" "Failed or cancelled: $*"
  return 1
}

case "$choice" in
  *Performance*) powerprofilesctl set performance ;;
  *Balanced*)    powerprofilesctl set balanced ;;
  *"Power saver"*) powerprofilesctl set power-saver ;;
  *"full speed"*) run_root fan full ;;
  *"Fans: auto"*) run_root fan auto ;;
  *45W*) run_root limit 45 ;;
  *65W*) run_root limit 65 ;;
  *) exit 0 ;;
esac

sleep 0.5
notify-send -u low -a PowerMenu "Power" "$(status_line)"
