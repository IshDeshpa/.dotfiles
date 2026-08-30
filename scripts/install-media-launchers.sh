#!/usr/bin/env bash
set -euo pipefail

# Install native media clients where they are available, then create
# application-menu launchers for the local media stack and streaming sites.
# Override any URL when your Docker port mapping differs, for example:
#   RADARR_URL=http://127.0.0.1:8787 ./install-media-launchers.sh

# audiotube is in Arch's Extra repository. Chromium provides standalone
# --app windows for services that do not ship a Linux client. Spotify is
# handled separately below because it is an AUR package on this system.
if [[ "${MEDIA_LAUNCHER_INSTALL_PACKAGES:-1}" == "1" ]]; then
    if ! command -v pacman >/dev/null 2>&1; then
        printf 'This package-installing script requires Arch Linux (pacman).\n' >&2
        exit 1
    fi

    sudo pacman -S --needed chromium audiotube curl

    # Spotify is distributed through the AUR rather than the enabled Arch
    # repositories on this installation.
    if ! command -v spotify >/dev/null 2>&1; then
        if command -v yay >/dev/null 2>&1; then
            yay -S --needed spotify
        elif command -v paru >/dev/null 2>&1; then
            paru -S --needed spotify
        else
            printf 'Spotify is not installed and no AUR helper (yay or paru) was found.\n' >&2
            printf 'Install yay/paru, then rerun this script.\n' >&2
            exit 1
        fi
    fi

    # The YouTube Music Electron client is an optional AUR alternative to
    # audiotube. It is deliberately not installed: audiotube is official,
    # lighter, and avoids adding an AUR build to the default path.
fi

browser="${BROWSER_BIN:-chromium}"
if ! command -v "${browser}" >/dev/null 2>&1; then
    printf 'Chromium was not found: %s\n' "${browser}" >&2
    printf 'Install chromium or set BROWSER_BIN to another Chromium-based executable.\n' >&2
    exit 1
fi

applications_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/applications"
icons_dir="${XDG_DATA_HOME:-${HOME}/.local/share}/icons/hicolor/scalable/apps"

mkdir -p "${applications_dir}"
mkdir -p "${icons_dir}"

download_icon() {
    local id="$1"
    local icon_url="$2"
    local icon_path="${icons_dir}/${id}.svg"

    if [[ -s "${icon_path}" ]]; then
        printf '%s\n' "${icon_path}"
        return
    fi

    if command -v curl >/dev/null 2>&1 &&
        curl --fail --silent --location \
            --output "${icon_path}" \
            "${icon_url}"; then
        printf '%s\n' "${icon_path}"
    else
        rm -f "${icon_path}"
        printf 'Could not download the %s icon; using the desktop icon name instead.\n' "${id}" >&2
        printf '%s\n' "${id}"
    fi
}

write_launcher() {
    local id="$1"
    local name="$2"
    local url="$3"
    local categories="$4"
    local mode="${5:-app}"
    local icon="${6:-${id}}"

    if [[ "${mode}" == "native" ]]; then
        cat > "${applications_dir}/${id}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${name}
Comment=Open ${name} as a desktop application
Exec=${url}
Icon=${icon}
Categories=${categories};
Terminal=false
StartupNotify=true
EOF
        return
    fi

    cat > "${applications_dir}/${id}.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=${name}
Comment=Open ${name} as a standalone web app
Exec=${browser} --app=${url}
TryExec=${browser}
Icon=${icon}
Categories=${categories};
Terminal=false
StartupNotify=true
EOF
}

# Local services. These are the usual ports for the listed images.
icon_base_url="https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg"
write_launcher "bazarr" "Bazarr" "${BAZARR_URL:-http://127.0.0.1:6767}" "AudioVideo;Network" "app" "$(download_icon bazarr "${icon_base_url}/bazarr.svg")"
write_launcher "sonarr" "Sonarr" "${SONARR_URL:-http://127.0.0.1:8989}" "AudioVideo;Network" "app" "$(download_icon sonarr "${icon_base_url}/sonarr.svg")"
write_launcher "transmission" "Transmission" "${TRANSMISSION_URL:-http://127.0.0.1:9091}" "Network;FileTransfer" "app" "$(download_icon transmission "${icon_base_url}/transmission.svg")"
write_launcher "prowlarr" "Prowlarr" "${PROWLARR_URL:-http://127.0.0.1:9696}" "AudioVideo;Network" "app" "$(download_icon prowlarr "${icon_base_url}/prowlarr.svg")"
write_launcher "radarr" "Radarr" "${RADARR_URL:-http://127.0.0.1:7878}" "AudioVideo;Network" "app" "$(download_icon radarr "${icon_base_url}/radarr.svg")"
write_launcher "kapowarr" "Kapowarr" "${KAPOWARR_URL:-http://127.0.0.1:5656}" "AudioVideo;Network" "app" "$(download_icon kapowarr "${icon_base_url}/kapowarr.svg")"
write_launcher "seerr" "Seerr" "${SEERR_URL:-http://127.0.0.1:5055}" "AudioVideo;Network" "app" "$(download_icon seerr "${icon_base_url}/seerr.svg")"
write_launcher "jellyfin" "Jellyfin" "${JELLYFIN_URL:-http://127.0.0.1:8096}" "AudioVideo;Network" "app" "$(download_icon jellyfin "${icon_base_url}/jellyfin.svg")"

# Native clients. Keep the URL argument as the executable so write_launcher
# can generate the .desktop file without another templating function.
if command -v spotify >/dev/null 2>&1; then
    write_launcher "spotify" "Spotify" "spotify" "AudioVideo;Audio;Network" "native"
fi
if command -v audiotube >/dev/null 2>&1; then
    write_launcher "youtube-music" "YouTube Music" "audiotube" "AudioVideo;Audio;Network" "native"
fi

# Streaming services.
write_launcher "max" "HBO Max" "https://www.max.com/" "AudioVideo;Network" "app" "$(download_icon max "${icon_base_url}/max.svg")"
write_launcher "hulu" "Hulu" "https://www.hulu.com/" "AudioVideo;Network" "app" "$(download_icon hulu "${icon_base_url}/hulu.svg")"
write_launcher "netflix" "Netflix" "https://www.netflix.com/" "AudioVideo;Network" "app" "$(download_icon netflix "${icon_base_url}/netflix.svg")"
write_launcher "youtube" "YouTube" "https://www.youtube.com/" "AudioVideo;Network" "app" "$(download_icon youtube "${icon_base_url}/youtube.svg")"
write_launcher "disney-plus" "Disney+" "https://www.disneyplus.com/" "AudioVideo;Network" "app" "$(download_icon disney-plus "${icon_base_url}/disney-plus.svg")"
write_launcher "prime-video" "Prime Video" "https://www.primevideo.com/" "AudioVideo;Network" "app" "$(download_icon prime-video "${icon_base_url}/prime-video.svg")"
write_launcher "apple-tv" "Apple TV" "https://tv.apple.com/" "AudioVideo;Network" "app" "$(download_icon apple-tv "${icon_base_url}/apple-tv.svg")"

if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "${applications_dir}" >/dev/null 2>&1 || true
fi

printf 'Installed media launchers in %s\n' "${applications_dir}"
