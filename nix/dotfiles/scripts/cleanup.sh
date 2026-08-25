#!/usr/bin/env bash

set -uo pipefail

failures=0
cache_dir=${XDG_CACHE_HOME:-"$HOME/.cache"}
trash_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/Trash

declare -a tracked_filesystems=()
declare -A tracked_devices=()

track_filesystem() {
    local path=$1
    local device

    # Walk up to an existing path so optional cache/trash directories still map
    # to the filesystem where they would live.
    while [[ ! -e $path && $path != / ]]; do
        path=${path%/*}
        [[ -n $path ]] || path=/
    done

    device=$(stat -c '%d' -- "$path") || return
    if [[ ! -v "tracked_devices[$device]" ]]; then
        tracked_devices[$device]=1
        tracked_filesystems+=("$path")
    fi
}

available_bytes() {
    local path available total=0

    for path in "${tracked_filesystems[@]}"; do
        available=$(LC_ALL=C df -B1 --output=avail "$path" | awk 'NR == 2 { print $1 }') || continue
        [[ $available =~ ^[0-9]+$ ]] || continue
        ((total += available))
    done

    printf '%s\n' "$total"
}

human_bytes() {
    if command -v numfmt >/dev/null 2>&1; then
        numfmt --to=iec-i --suffix=B "$1"
    else
        printf '%s bytes\n' "$1"
    fi
}

run_step() {
    local description=$1
    shift

    printf '\n==> %s\n' "$description"
    if ! "$@"; then
        printf 'Warning: this cleanup step failed; continuing.\n' >&2
        ((failures += 1))
    fi
}

clear_directory() {
    local directory normalized
    directory=$1
    normalized=$(realpath -m -- "$directory") || return

    # Guard against a bad XDG variable turning this into a broad deletion.
    if [[ -z $normalized || $normalized == / || $normalized == "$HOME" ]]; then
        printf 'Refusing to clear unsafe path: %s\n' "$directory" >&2
        return 1
    fi

    [[ -d $normalized ]] || return 0
    find "$normalized" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +
}

remove_orphans() {
    local -a orphans=()
    local -a remove_command=()
    local package_helper

    if command -v yay >/dev/null 2>&1; then
        package_helper=yay
        remove_command=(yay)
    elif command -v pacman >/dev/null 2>&1; then
        package_helper=pacman
        remove_command=(sudo pacman)
    else
        printf 'Neither yay nor pacman is installed; skipping orphan removal.\n'
        return 0
    fi

    mapfile -t orphans < <("$package_helper" -Qdtq 2>/dev/null || true)
    if ((${#orphans[@]} == 0)); then
        printf 'No orphaned packages found.\n'
        return 0
    fi

    "${remove_command[@]}" -Rsn "${orphans[@]}"
}

for path in / "$HOME" /var "$cache_dir" "$trash_dir"; do
    track_filesystem "$path"
done
bytes_before=$(available_bytes)

run_step 'Removing orphaned packages' remove_orphans

if command -v paccache >/dev/null 2>&1; then
    run_step 'Keeping the two newest cached versions of installed packages' sudo paccache -rk2
    run_step 'Removing cached packages that are no longer installed' sudo paccache -ruk0
fi

if [[ -d /var/cache/pacman/pkg ]]; then
    run_step 'Removing abandoned package downloads' \
        sudo find /var/cache/pacman/pkg -mindepth 1 -maxdepth 1 \
        \( -name 'download-*' -o -name '*.part' \) -exec rm -rf -- {} +
fi

run_step 'Clearing the user cache (including hidden entries)' clear_directory "$cache_dir"
run_step 'Emptying trashed files' clear_directory "$trash_dir/files"
run_step 'Removing stale trash metadata' clear_directory "$trash_dir/info"
run_step 'Removing stale trash staging data' clear_directory "$trash_dir/expunged"

if command -v flatpak >/dev/null 2>&1; then
    run_step 'Removing unused per-user Flatpak runtimes' \
        flatpak uninstall --unused --user --assumeyes --noninteractive
    run_step 'Removing unused system Flatpak runtimes' \
        sudo flatpak uninstall --unused --system --assumeyes --noninteractive
fi

if command -v journalctl >/dev/null 2>&1; then
    run_step 'Removing archived journal entries older than seven days' \
        sudo journalctl --vacuum-time=7d
fi

if command -v systemd-tmpfiles >/dev/null 2>&1; then
    run_step 'Applying per-user temporary-file cleanup policies' \
        systemd-tmpfiles --user --clean
    run_step 'Applying system temporary-file cleanup policies' \
        sudo systemd-tmpfiles --clean
fi

bytes_after=$(available_bytes)
bytes_reclaimed=$((bytes_after - bytes_before))

printf '\n'
if ((bytes_reclaimed >= 0)); then
    printf 'Total space reclaimed: %s bytes (%s)\n' \
        "$bytes_reclaimed" "$(human_bytes "$bytes_reclaimed")"
else
    bytes_used=$((-bytes_reclaimed))
    printf 'Total space reclaimed: 0 bytes (free space decreased by %s during the run)\n' \
        "$(human_bytes "$bytes_used")"
fi

if ((failures > 0)); then
    printf '%d cleanup step(s) failed; review the warnings above.\n' "$failures" >&2
    exit 1
fi
