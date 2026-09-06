# System cleanup helpers that depend on Linux-only tooling (snap, apt, dnf,
# systemd-journald). They live under linux-specific/ because loaded from the
# common directory they were defined on macOS too, where none of these
# commands exist.
#
# Each one checks for its own tool before doing anything: within Linux these
# are not interchangeable either — Fedora ships no snapd and no apt, Debian no
# dnf — so calling one on the wrong distro used to end in command-not-found.

function clean-snap() {
    if ! command -v snap &> /dev/null; then
        echo "snap is not installed; nothing to clean."
        return 0
    fi

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
    if ! command -v apt-get &> /dev/null; then
        echo "apt is not installed; nothing to clean."
        return 0
    fi

    echo "Starting APT cache and package cleanup..."

    # Check initial cache size
    echo "\nCurrent APT cache usage:"
    sudo du -sh /var/cache/apt/archives 2>/dev/null || echo "  0B"

    # 1. Remove unused dependency packages and leftover configs
    echo "\n1. Removing orphaned dependencies and residual configs..."
    sudo apt-get autoremove --purge -y

    # 2. Clean the entire downloaded .deb archive cache
    echo "\n2. Clearing downloaded package cache..."
    sudo apt-get clean

    # Final disk usage summary
    echo "\nAPT cleanup complete!"
    echo "\nUpdated APT cache usage:"
    sudo du -sh /var/cache/apt/archives 2>/dev/null || echo "  0B"

    return 0
}

# Report DNF cache size. dnf5 moved the cache to /var/cache/libdnf5; dnf4 used
# /var/cache/dnf. Report whichever exists rather than assuming a version.
function _dnf-cache-usage() {
    local dir found=1
    for dir in /var/cache/libdnf5 /var/cache/dnf; do
        if [[ -d "$dir" ]]; then
            sudo du -sh "$dir" 2>/dev/null && found=0
        fi
    done
    (( found == 0 )) || echo "  0B"
}

function clean-dnf() {
    if ! command -v dnf &> /dev/null; then
        echo "dnf is not installed; nothing to clean."
        return 0
    fi

    echo "Starting DNF cache and package cleanup..."

    echo "\nCurrent DNF cache usage:"
    _dnf-cache-usage

    # 1. Orphaned dependencies, the counterpart of `apt autoremove`
    echo "\n1. Removing orphaned dependencies..."
    sudo dnf autoremove -y

    # 2. Old kernels. Fedora keeps installonly_limit versions (3 by default)
    #    and they live in /boot, which is small and easy to fill.
    echo "\n2. Removing superseded kernels (keeping the 2 most recent)..."
    sudo dnf remove --oldinstallonly --limit=2 -y

    # 3. Cached packages, repo metadata and the resolver dbcache
    echo "\n3. Clearing package cache and repository metadata..."
    sudo dnf clean all

    echo "\nDNF cleanup complete!"
    echo "\nUpdated DNF cache usage:"
    _dnf-cache-usage

    return 0
}

function clean-journal-logs() {
    if ! command -v journalctl &> /dev/null; then
        echo "systemd-journald is not present; nothing to clean."
        return 0
    fi

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
