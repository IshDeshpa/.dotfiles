#!/usr/bin/env bash

set -e

if [ "$(id -u)" != '0' ]; then
  echo 'This script must be run as root'
  exit 1
fi


NAME="$(basename "$0")"

MAIN_DIR='/tmp/extreme-powersaver'
GOV_BAK="${MAIN_DIR}/gov"
PST_BAK="${MAIN_DIR}/pstate"
APP_BAK="${MAIN_DIR}/app"

GOV_FILES=(/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor)
PST_FILE='/sys/devices/system/cpu/amd_pstate/status'
APP_FILE='/sys/firmware/acpi/platform_profile'

NO_RESTORE_APP=false

print_help() {
  echo "${NAME} - Configure extrem powersaver mode"
  echo ''
  echo "${NAME} [OPTIONS] ACTION"
  echo ''
  echo 'options:'
  echo '--no-restore-app     dont restore application power profile when disabling'
  echo ''
  echo 'actions:'
  echo '-h, --help           show brief help'
  echo '-e, --enable         enable extrem powersaver mode'
  echo '-d, --disable        disable extrem powersaver mode'
  echo '-t, --toggle         toggle extrem powersaver mode'
}

enable_epm() {
  # Back up the current settings
  cat "${GOV_FILES[@]}" > "$GOV_BAK"
  cat "$PST_FILE" > "$PST_BAK"
  cat "$APP_FILE" > "$APP_BAK"

  echo 'powersave' | tee "${GOV_FILES[@]}" > /dev/null
  echo 'guided' | tee "$PST_FILE" > /dev/null
  echo 'low-power' | tee "$APP_FILE" > /dev/null
}

disable_epm() {
  # Reset each cpu<n> scheduler to it's original value stored in GOV_BAK
  i=0
  while read -r line; do
    echo "$line" | tee "${GOV_FILES[i]}" > /dev/null
    i=$((i+1))
  done < "$GOV_BAK"

  cat "$PST_BAK" | tee "$PST_FILE" > /dev/null

  if [ "$NO_RESTORE_APP" = false ]; then
    cat "$APP_BAK" | tee "$APP_FILE" > /dev/null
  fi

  rm "$PST_BAK" "$GOV_BAK" "$APP_BAK"
}

is_epm_enabled() {
  [ -f "$PST_BAK" ] && [ -f "$GOV_BAK" ] && [ -f "$APP_BAK" ]
}


mkdir -p "$MAIN_DIR"

while [ $# -gt 0 ]; do
  case "$1" in
    -h|--help)
      print_help
      exit 0
      ;;
    -e|--enable)
      if ! is_epm_enabled; then
        enable_epm
      fi
      exit 0
      ;;
    -d|--disable)
      if is_epm_enabled; then
        disable_epm
      fi
      exit 0
      ;;
    -t|--toggle)
      if is_epm_enabled; then
        disable_epm
      else
        enable_epm
      fi
      exit 0
      ;;
    --no-restore-app)
      NO_RESTORE_APP=true
      ;;
    *)
      print_help
      exit 1
      ;;
  esac
  shift
done

# No action was passed, otherwise we would have exited
print_help
exit 1
