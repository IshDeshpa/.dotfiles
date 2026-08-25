#!/usr/bin/env bash
set -euo pipefail

# Wrapper around the real `aurveto` and `downgrade`:
#   1. show `aurveto check`
#   2. ask for approval, then run `aurveto upgrade` (pacman -Syu, then
#      installs only the AUR packages aurveto marks ✅ allowed/whitelist)
#   3. scan the AUR section of `aurveto check` for anything marked
#      ❌ blocked — i.e. currently judged unsafe
#   4. offer to roll those back with `downgrade`
#
# This wrapper disables aurveto's AI review step (see disable_ai_review
# below) since no LLM API key is configured; only the whitelist/delay/
# static-scan (aur-scan) layers apply.
#
# Parsing is based on aurveto's real `check` output:
#   AUR updates: N (delay 14d, AI review enabled|disabled)
#     pkgname   oldver → newver (D-14) ✅ allowed
#     pkgname   oldver → newver        ✅ (whitelist)
#     pkgname   oldver → newver (D-13) ⏳ delayed (13d)
#     pkgname   oldver → newver        ❌ blocked
#   Safe: X | delayed: Y | blocked: Z

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "aurveto-upgrade: missing dependency '$1'" >&2
    exit 1
  }
}
need aurveto
need downgrade

# aurveto has no --no-ai CLI flag; AI review is a config.toml toggle
# ([ai] enabled = true/false). Ensure it's off before running, since no
# API key is configured for the LLM step.
CONFIG_FILE="$HOME/.config/aurveto/config.toml"

disable_ai_review() {
  # First run: let aurveto create its default config, so we have a file to edit.
  [[ -f "$CONFIG_FILE" ]] || aurveto config >/dev/null 2>&1 || true
  [[ -f "$CONFIG_FILE" ]] || return 0

  # Only touch `enabled = true` inside the [ai] section (leave [notify]
  # enabled, etc. untouched).
  if awk '/^\[ai\]/{f=1;next} /^\[/{f=0} f && /^enabled[[:space:]]*=[[:space:]]*true/{found=1} END{exit !found}' "$CONFIG_FILE"; then
    awk '
      /^\[ai\]/ { print; in_ai=1; next }
      /^\[/     { in_ai=0 }
      in_ai && /^enabled[[:space:]]*=/ { print "enabled = false"; next }
      { print }
    ' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo "==> Disabled AI review in $CONFIG_FILE"
  fi
}
disable_ai_review

echo "==> aurveto check"
CHECK_OUTPUT="$(aurveto check)"
echo "$CHECK_OUTPUT"
echo

read -rp "Proceed with official repo upgrade + safe AUR packages? [y/N] " ans
[[ "$ans" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

echo
echo "==> aurveto upgrade"
aurveto upgrade

echo
echo "==> Scanning for currently unsafe (blocked) AUR packages"

# Isolate just the AUR section between "AUR updates:" and the "Safe: X | ..." summary line.
AUR_SECTION="$(sed -n '/^AUR updates:/,/^Safe:/p' <<<"$CHECK_OUTPUT")"

# Packages aurveto has marked ❌ blocked (currently judged unsafe).
BLOCKED_PKGS="$(grep '❌' <<<"$AUR_SECTION" | awk '{print $1}')"

# Packages currently delayed (in the review window, not yet installed
# but not necessarily unsafe) — reported, not auto-downgraded.
DELAYED_PKGS="$(grep '⏳' <<<"$AUR_SECTION" | awk '{print $1}')"

if [[ -n "$DELAYED_PKGS" ]]; then
  echo "Still in review window (not upgraded, not flagged unsafe):"
  printf '  %s\n' $DELAYED_PKGS
  echo
fi

if [[ -z "$BLOCKED_PKGS" ]]; then
  echo "No packages currently flagged unsafe/blocked."
  exit 0
fi

echo "Flagged UNSAFE (blocked by aurveto):"
printf '  %s\n' $BLOCKED_PKGS
echo

read -rp "Downgrade these now with 'downgrade'? [y/N] " ans2
if [[ "$ans2" =~ ^[Yy]$ ]]; then
  # shellcheck disable=SC2086
  downgrade $BLOCKED_PKGS
else
  echo "Skipped. Run 'downgrade <pkg>' manually for each when ready:"
  printf '  downgrade %s\n' $BLOCKED_PKGS
fi
