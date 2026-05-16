#!/usr/bin/env bash
# scripts/setup/spotify.sh
# /setup-spotify — installs Spotify and configures Spicetify.
#
# @meta name: Setup Spotify + Spicetify
# @meta description: Install Spotify and configure Spicetify (AUR on Arch, Flatpak elsewhere)
# @meta icon: music_note
# @meta keywords: spotify music spicetify aur flatpak
#
# Arch family : `spotify` (AUR) + `spicetify-cli` (AUR). Tries
#               `spicetify backup apply` first; only launches Spotify
#               (so the user can sign in and Spotify can generate its
#               prefs file) if the first apply fails. Then sets prefs_path,
#               retries, installs the Marketplace, and — only if the user
#               has enabled `appearance.wallpaperTheming.enableSpicetify`
#               in config.json — applies the iNiR Spicetify theme.
# Other distros: falls back to the Flatpak build of Spotify. Spicetify is
#                skipped because it cannot patch the Flatpak install reliably.

set -Eeuo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
. "$SCRIPT_DIR/_lib.sh"

CONFIG_PATH="${XDG_CONFIG_HOME:-$HOME/.config}/illogical-impulse/config.json"

_find_prefs() {
    find "$HOME" -path '*/spotify/prefs' -print -quit 2>/dev/null
}

_await_or_force_close_spotify() {
    echo
    echo "  ┌─────────────────────────────────────────────────────────────┐"
    echo "  │  Sign in to Spotify so it can write its prefs file.         │"
    echo "  │  Quit Spotify normally to continue, OR press Enter here     │"
    echo "  │  to force-quit it.                                          │"
    echo "  └─────────────────────────────────────────────────────────────┘"
    echo

    local waited=0
    while ! pgrep -x spotify >/dev/null 2>&1; do
        sleep 1
        waited=$((waited + 1))
        (( waited >= 30 )) && { echo "  · Spotify did not start; continuing anyway." >&2; return 0; }
    done

    while pgrep -x spotify >/dev/null 2>&1; do
        if read -r -t 2 _; then
            echo "  · Force-closing Spotify…"
            pkill -x spotify || true
            for _ in 1 2 3 4 5; do
                pgrep -x spotify >/dev/null 2>&1 || break
                sleep 1
            done
            pgrep -x spotify >/dev/null 2>&1 && pkill -9 -x spotify || true
            break
        fi
    done
    echo "  · Spotify closed — resuming setup."
}

_theme_enabled_in_config() {
    [[ -f "$CONFIG_PATH" ]] || return 1
    have_cmd jq || return 1
    [[ "$(jq -r '.appearance.wallpaperTheming.enableSpicetify // false' \
        "$CONFIG_PATH" 2>/dev/null)" == "true" ]]
}

setup_init "spotify" "Setup Spotify + Spicetify"

if is_arch_like; then
    TOTAL=5

    setup_progress 1 $TOTAL "Installing Spotify (AUR) and Spicetify CLI"
    install_arch -- spotify spicetify-cli

    setup_progress 2 $TOTAL "Granting Spicetify write access to /opt/spotify"
    sudo chmod a+wr /opt/spotify
    sudo chmod a+wr /opt/spotify/Apps -R

    setup_progress 3 $TOTAL "Applying Spicetify backup"
    prefs="$(_find_prefs)"
    if [[ -n "$prefs" ]]; then
        echo "  · prefs already exists at $prefs"
        spicetify config prefs_path "$prefs" >/dev/null 2>&1 || true
    fi

    if ! spicetify backup apply; then
        echo
        echo "  · backup apply failed (likely no prefs file yet)."
        echo "  · Launching Spotify so it can generate its prefs…"
        setsid -f spotify >/dev/null 2>&1 < /dev/null || \
            nohup spotify >/dev/null 2>&1 < /dev/null &
        setup_notify "Sign in to Spotify, then quit it (or press Enter in the terminal to force-quit)" "media-playback-start"
        _await_or_force_close_spotify

        prefs="$(_find_prefs)"
        if [[ -z "$prefs" ]]; then
            setup_fail "Could not locate spotify/prefs after first run; aborting."
            setup_finish_pause
            exit 1
        fi
        echo "  · Found prefs at $prefs"
        spicetify config prefs_path "$prefs" >/dev/null 2>&1 || true
        spicetify backup apply
    fi

    setup_progress 4 $TOTAL "Installing Spicetify Marketplace"
    if curl -fsSL https://raw.githubusercontent.com/spicetify/marketplace/main/resources/install.sh \
        | sh; then
        echo "Marketplace installed."
    else
        echo "warning: Marketplace installer failed; you can rerun it later." >&2
    fi

    if _theme_enabled_in_config; then
        setup_progress 5 $TOTAL "Applying iNiR Spicetify theme"
        theme_script="$SCRIPT_DIR/../colors/apply-spicetify-theme.sh"
        if [[ -x "$theme_script" ]]; then
            if "$theme_script"; then
                echo "iNiR theme applied."
            else
                echo "warning: theme script returned non-zero; rerun it manually if Spotify looks unstyled." >&2
            fi
        else
            echo "warning: $theme_script not found or not executable; skipping theme." >&2
        fi
    else
        setup_progress 5 $TOTAL "Skipping iNiR theme (appearance.wallpaperTheming.enableSpicetify is off)"
        echo "  · Enable it in Settings → Themes → 'Spotify theming' to apply the iNiR theme."
    fi

    setup_done "Spotify + Spicetify ready. Launch Spotify to verify."
else
    TOTAL=2
    setup_progress 1 $TOTAL "Installing Spotify via Flatpak (no Spicetify on non-Arch)"
    install_flatpak com.spotify.Client

    setup_progress 2 $TOTAL "Skipping Spicetify (unsupported on Flatpak Spotify)"
    setup_done "Spotify installed via Flatpak. Spicetify was skipped."
fi

setup_finish_pause
