# Update every layer of the system: distro packages, shell tooling and the
# sandboxed app stores.
#
# The package manager is detected at runtime rather than baked in by a chezmoi
# template. This file is shared by every Linux host, and runtime detection also
# holds up when the same $HOME is reused from a container or a distro is
# switched underneath it.
system-update() {
    echo "🛠️ Updating system tools..."

    # --- Distro packages ---------------------------------------------------
    if command -v dnf &> /dev/null; then
        echo "🔄 Updating dnf packages..."
        # --refresh forces a metadata refresh, which is what `apt update` does
        # as a separate step.
        if sudo dnf upgrade --refresh -y; then
            echo "✅ dnf packages updated!"
        else
            echo "❌ dnf update failed."
        fi
    elif command -v apt-get &> /dev/null; then
        echo "🔄 Updating apt packages..."
        # apt-get, not apt: apt warns that it "does not have a stable CLI
        # interface" and is not meant to be scripted.
        if sudo apt-get update && sudo apt-get upgrade -y; then
            echo "✅ apt packages updated!"
        else
            echo "❌ apt update failed."
        fi
    else
        echo "⚠️ No supported package manager found (dnf/apt-get); skipping."
    fi

    # --- Shell and developer tooling ---------------------------------------
    # Guarded on the underlying tool: these are shell functions, so they are
    # always defined and would otherwise fail with a bare "command not found"
    # partway through the run on a machine where the tool is absent.
    # `command -v` resolves zsh functions too, which is what zinit is.
    command -v zinit &> /dev/null && zinit-update
    command -v chezmoi &> /dev/null && chezmoi-update
    command -v mise &> /dev/null && mise-update
    command -v krew &> /dev/null && krew-plugins-update

    # --- Snaps -------------------------------------------------------------
    if command -v snap &> /dev/null; then
        echo "🔄 Updating snaps..."
        if sudo snap refresh; then
            echo "✅ snaps updated!"
        else
            echo "❌ snap refresh failed."
        fi
    fi

    # --- Flatpaks ----------------------------------------------------------
    if command -v flatpak &> /dev/null; then
        echo "🔄 Updating flatpaks..."
        # --user is the important part. `flatpak update` defaults to --system,
        # so the previous `sudo flatpak update` refreshed the system scope and
        # left every flatpak this repo installs untouched: the install script
        # uses `flatpak install --user`.
        if flatpak update --user -y; then
            echo "✅ user flatpaks updated!"
        else
            echo "❌ user flatpak update failed."
        fi

        # Only touch the system scope when something is actually installed
        # there, to avoid a pointless sudo prompt.
        if [[ -n "$(flatpak list --system --app 2> /dev/null)" ]]; then
            if sudo flatpak update --system -y; then
                echo "✅ system flatpaks updated!"
            else
                echo "❌ system flatpak update failed."
            fi
        fi
    fi

    echo "🎉 Everything's fresh and clean!"
}
