# System cleanup helpers that depend on Linux-only tooling (snap, apt,
# systemd-journald). They live under linux-specific/ because loaded from the
# common directory they were defined on macOS too, where none of these
# commands exist.

function clean-snap() {
    echo "Starting deep Snap cleanup..."

    echo "\nCurrent Snap disk usage:"
    for dir in /var/lib/snapd/snaps /var/lib/snapd/cache /var/lib/snapd/snapshots; do
        if [[ -d "$dir" ]]; then
            sudo du -sh "$dir" 2>/dev/null
        fi
    done

    # 1. Remove old disabled versions (locale-independent)
    echo "\n1. Searching for old disabled versions..."
    local disabled_snaps=$(LANG=C snap list --all | awk '/disabled/{print $1, $3}')

    if [[ -n "$disabled_snaps" ]]; then
        echo "$disabled_snaps" | while read snapname revision; do
            echo "  -> Removing $snapname (revision $revision)..."
            sudo snap remove "$snapname" --revision="$revision"
        done
    else
        echo "  No old disabled versions found."
    fi

    # 2. Clear temporary download cache
    echo "\n2. Clearing temporary download cache..."
    sudo sh -c 'rm -rf /var/lib/snapd/cache/*'
    echo "  Download cache cleared."

    # 3. Remove automatic snapshots
    echo "\n3. Checking automatic snapshots..."
    local snapshots=$(snap saved 2>/dev/null | tail -n +2 | awk '{print $1}')

    if [[ -n "$snapshots" ]]; then
        echo "$snapshots" | while read id; do
            echo "  -> Removing snapshot ID: $id..."
            sudo snap forget "$id"
        done
    else
        echo "  No snapshots to remove."
    fi

    # 4. Final disk usage summary
    echo "\nSnap cleanup complete!"
    echo "\nUpdated Snap disk usage:"
    for dir in /var/lib/snapd/snaps /var/lib/snapd/cache /var/lib/snapd/snapshots; do
        if [[ -d "$dir" ]]; then
            sudo du -sh "$dir" 2>/dev/null
        fi
    done

    # Ensure function returns success (0)
    return 0
}

function clean-apt() {
    echo "Starting APT cache and package cleanup..."

    # Check initial cache size
    echo "\nCurrent APT cache usage:"
    sudo du -sh /var/cache/apt/archives 2>/dev/null || echo "  0B"

    # 1. Remove unused dependency packages and leftover configs
    echo "\n1. Removing orphaned dependencies and residual configs..."
    sudo apt autoremove --purge -y

    # 2. Clean the entire downloaded .deb archive cache
    echo "\n2. Clearing downloaded package cache..."
    sudo apt clean

    # Final disk usage summary
    echo "\nAPT cleanup complete!"
    echo "\nUpdated APT cache usage:"
    sudo du -sh /var/cache/apt/archives 2>/dev/null || echo "  0B"

    return 0
}

function clean-journal-logs() {
    echo "Starting systemd journal logs cleanup..."

    # Check current logs disk usage
    echo "\nCurrent journal logs disk usage:"
    journalctl --disk-usage 2>/dev/null

    # Default retention is 7 days unless specified (e.g., clean-logs 3d)
    local retention="${1:-7d}"

    echo "\nCleaning logs older than ${retention}..."
    sudo journalctl --vacuum-time="${retention}"

    # Final disk usage summary
    echo "\nJournal logs cleanup complete!"
    echo "\nUpdated journal logs disk usage:"
    journalctl --disk-usage 2>/dev/null

    return 0
}
