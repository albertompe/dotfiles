# Update zinit and plugins
zinit-update() {
    echo "🔄 Updating zinit..."
    zinit self-update
    echo "✅ zinit updated!"
    echo "🔄 Updating zinit plugins..."
    zinit update --all
    echo "✅ All zinit plugins updated!"
}

# Update mise plugins and tools
mise-update() {
    echo "🔄 Updating mise plugins and tools..."
    mise plugins upgrade
    mise upgrade
    echo "✅ All mise plugins and tools updated!"
}

# Update krew plugins
krew-plugins-update() {
    echo "🔄 Updating krew plugins..."
    krew upgrade
    echo "✅ All krew plugins updated!"
}

# batdiff: use bat to show git diffs
batdiff() {
    git diff --name-only --diff-filter=d | xargs bat --diff
}
