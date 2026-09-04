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

function clean-mise() {
    if ! command -v mise &>/dev/null; then
        echo "⚠️ Mise is not installed or not in PATH."
        return 1
    fi

    echo "Starting Mise (runtimes & cache) cleanup..."

    # Obtain Mise data directory dynamically using Mise itself, fallback to standard path
    local misedir="$(mise where --root 2>/dev/null || echo "$HOME/.local/share/mise")"
    if [[ ! -d "$misedir" && -d "$HOME/.local/mise" ]]; then
        misedir="$HOME/.local/mise"
    fi

    # Check current disk usage
    echo "\nCurrent Mise disk usage:"
    for dir in "$misedir" "$misedir/http-tarballs" ~/.cache/mise; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null
        fi
    done

    # 1. Prune unused tool versions (filtering out internal registry warnings)
    echo "\n1. Pruning unused runtime versions..."
    mise prune -y 2>&1 | grep -v "not found in mise tool registry"

    # 2. Clear mise download cache, http-tarballs and temporary downloads without Zsh prompts
    echo "\n2. Clearing temporary tarballs and download cache..."
    mise cache clean -y 2>/dev/null

    # Safely wipe and recreate temporary directories to avoid Zsh glob errors and [yn]? prompts
    for tempdir in ~/.cache/mise "$misedir/http-tarballs" "$misedir/downloads"; do
        if [[ -d "$tempdir" ]]; then
            rm -rf "$tempdir" && mkdir -p "$tempdir"
        fi
    done
    echo "  All download caches and tarballs cleared."

    # Final disk usage summary
    echo "\nMise cleanup complete!"
    echo "\nUpdated Mise disk usage:"
    for dir in "$misedir" "$misedir/http-tarballs" ~/.cache/mise; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null
        fi
    done

    return 0
}

function clean-go() {
    if ! command -v go &>/dev/null; then
        echo "⚠️ Go is not installed or not in PATH."
        return 1
    fi

    echo "Starting Go cache cleanup..."

    # Extract Go cache paths dynamically
    local gocache=$(go env GOCACHE 2>/dev/null)
    local gomodcache=$(go env GOMODCACHE 2>/dev/null)

    # Check initial disk usage
    echo "\nCurrent Go cache usage:"
    for dir in "$gocache" "$gomodcache"; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null
        fi
    done

    # 1. Clean build and test cache (safe & recommended regularly)
    echo "\n1. Clearing Go build and test cache..."
    go clean -cache -testcache
    echo "  Build cache cleared."

    # 2. Optionally clean downloaded module cache
    if [[ "$1" == "--all" || "$1" == "-a" ]]; then
        echo "\n2. Deep clean enabled: clearing downloaded module cache (modcache)..."
        go clean -modcache
        echo "  Module cache cleared."
    else
        echo "\nFor a deep clean (remove all downloaded Go modules), run: clean-go --all / clean-go -a"
    fi

    # Final disk usage summary
    echo "\nGo cleanup complete!"
    echo "\nUpdated Go cache usage:"
    for dir in "$gocache" "$gomodcache"; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null
        fi
    done

    return 0
}

function clean-python() {
    echo "Starting Python (uv & pip) cache cleanup..."

    # Check initial cache size
    echo "\nCurrent Python cache usage:"
    for dir in ~/.cache/uv ~/.cache/pip ~/.cache/pre-commit ~/.cache/ruff ~/.cache/mypy; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null
        fi
    done

    # 1. Clean uv package cache
    if command -v uv &>/dev/null; then
        echo "\n1. Clearing uv package cache..."
        uv cache clean
        echo "  uv cache cleared."
    else
        echo "\n1. uv not installed, skipping..."
    fi

    # 2. Clean traditional pip cache
    echo "\n2. Clearing traditional pip cache..."
    if command -v pip &>/dev/null; then
        pip cache purge 2>/dev/null || rm -rf ~/.cache/pip/* 2>/dev/null
    else
        rm -rf ~/.cache/pip/* 2>/dev/null
    fi
    echo "  pip cache cleared."

    # 3. Deep clean option: remove __pycache__ and test/linter caches in ~/code
    if [[ "$1" == "--all" || "$1" == "-a" ]]; then
        echo "\n3. Deep clean enabled: removing __pycache__, .pytest_cache, and linter caches in ~/code..."
        if [[ -d "$HOME/code" ]]; then
            find "$HOME/code" -type d \( -name "__pycache__" -o -name ".pytest_cache" -o -name ".ruff_cache" -o -name ".mypy_cache" \) -prune -exec rm -rf {} + 2>/dev/null
            echo "  Workspace bytecode and linter caches removed."
        else
            echo "  ~/code directory not found, skipping workspace cleanup."
        fi

        # Clean pre-commit cache if it exists
        if [[ -d "$HOME/.cache/pre-commit" ]]; then
            rm -rf ~/.cache/pre-commit && mkdir -p ~/.cache/pre-commit
            echo "  ✓ pre-commit cache cleared."
        fi
    else
        echo "\nFor a deep clean (remove workspace __pycache__, test caches, and pre-commit cache), run: clean-python --all / clean-python -a"
    fi

    # Final disk usage summary
    echo "\nPython cleanup complete!"
    echo "\nUpdated Python cache usage:"
    for dir in ~/.cache/uv ~/.cache/pip ~/.cache/pre-commit ~/.cache/ruff ~/.cache/mypy; do
        if [[ -d "$dir" ]]; then
            du -sh "$dir" 2>/dev/null
        fi
    done

    return 0
}
