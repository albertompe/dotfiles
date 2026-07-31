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

function clean-docker() {
    echo "Starting Docker cleanup..."

    # 1. Remove stopped containers, unused networks, and standard cache
    echo "\n1. Removing stopped containers, unused networks, and basic cache..."
    docker system prune -f

    # 2. Clear BuildKit/buildx build cache
    echo "\n2. Clearing BuildKit build cache..."
    docker builder prune -f 2>/dev/null || true

    # 3. Deep clean option (unused images and volumes)
    if [[ "$1" == "--all" || "$1" == "-a" ]]; then
        echo "\n3. Deep clean enabled: removing unused images and volumes..."
        docker system prune -a -f --volumes
    else
        echo "\nFor a deep clean (unused images & volumes), run: clean-docker --all / clean-docker -a"
    fi

    # Docker disk usage summary
    echo "\nCurrent Docker disk usage:"
    docker system df
}
