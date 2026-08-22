#!/usr/bin/env bash
set -euo pipefail

# Lists explicitly-installed pacman packages ordered by the most recent
# access time (atime) of any binary they own, oldest first, to help spot
# packages you probably don't need anymore.
#
# How it works:
#   - `pacman -Qqe` gives explicitly-installed packages (skips things
#     only pulled in as dependencies, which you didn't choose directly).
#   - `pacman -Ql <pkg>` lists that package's files; filtered down to
#     paths under a bin/ directory as a proxy for "runnable things".
#   - `stat -c %X` reads each binary's atime; the newest atime across a
#     package's binaries is treated as "last used".
#   - Sorted ascending, so the stalest packages are at the top.
#
# Caveats:
#   - Requires atime tracking on / (relatime, the usual default, is
#     fine; noatime disables this entirely — checked below).
#   - Libraries, fonts, data-only packages have no binary to check and
#     are listed separately as "can't determine".
#   - Some filesystems/kernels don't bump atime on mmap'd shared
#     libraries, so a GUI app launched only via .desktop files that
#     dlopen a lib (rather than exec a bin) can look stale even if used.
#   - A daily-resolution relatime means "used earlier today" and
#     "used yesterday" may look identical; this is a coarse tool for
#     finding things untouched for weeks/months, not a precise log.

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1" >&2; exit 1; }; }
need pacman
need stat
need findmnt

ROOT_OPTS="$(findmnt -no OPTIONS / )"
if grep -q 'noatime' <<<"$ROOT_OPTS"; then
  echo "WARNING: root filesystem is mounted with 'noatime' - access times" >&2
  echo "are never updated, so this report would be meaningless." >&2
  echo "Remount with 'relatime' (usual default) or 'atime' to use this tool." >&2
  exit 1
fi

TMP_TS="$(mktemp)"
TMP_NOBIN="$(mktemp)"
trap 'rm -f "$TMP_TS" "$TMP_NOBIN"' EXIT

while read -r pkg; do
  files="$(pacman -Ql "$pkg" 2>/dev/null | awk '{print $2}' | grep -E '/(s)?bin/' || true)"
  if [[ -z "$files" ]]; then
    echo "$pkg" >> "$TMP_NOBIN"
    continue
  fi

  newest=0
  while IFS= read -r f; do
    [[ -f "$f" && -x "$f" ]] || continue
    atime="$(stat -c %X "$f" 2>/dev/null || echo 0)"
    (( atime > newest )) && newest="$atime"
  done <<<"$files"

  if [[ "$newest" -gt 0 ]]; then
    printf '%s\t%s\n' "$newest" "$pkg" >> "$TMP_TS"
  else
    echo "$pkg" >> "$TMP_NOBIN"
  fi
done < <(pacman -Qqe)

echo "Packages by last-used binary, oldest first:"
echo
sort -n "$TMP_TS" | while IFS=$'\t' read -r ts pkg; do
  printf '  %-32s %s\n' "$pkg" "$(date -d @"$ts" '+%Y-%m-%d')"
done

if [[ -s "$TMP_NOBIN" ]]; then
  echo
  echo "No binary found (libraries/fonts/data-only, or file missing) -"
  echo "can't judge usage this way, review manually:"
  sort "$TMP_NOBIN" | sed 's/^/  /'
fi
