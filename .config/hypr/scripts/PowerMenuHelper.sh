#!/usr/bin/env bash
# Root helper for PowerMenu.sh (run via pkexec). Accepts only:
#   fan full|auto     - ASUS fan mode (pwm_enable 0 = full speed, 2 = auto)
#   limit 45|65       - Intel RAPL sustained (long_term) package power limit in watts
set -euo pipefail

asus_hwmon() {
  local d
  for d in /sys/class/hwmon/hwmon*; do
    [ "$(cat "$d/name" 2>/dev/null)" = "asus" ] && { echo "$d"; return 0; }
  done
  return 1
}

case "${1:-} ${2:-}" in
  "fan full"|"fan auto")
    hw="$(asus_hwmon)" || { echo "asus hwmon not found" >&2; exit 1; }
    value=2
    [ "$2" = "full" ] && value=0
    for f in "$hw"/pwm*_enable; do
      echo "$value" >"$f"
    done
    ;;
  "limit 45"|"limit 65")
    echo "$(( $2 * 1000000 ))" >/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
    ;;
  *)
    echo "usage: $0 fan full|auto | limit 45|65" >&2
    exit 2
    ;;
esac
