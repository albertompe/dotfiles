# macOS specific settings

# Set GPG_TTY to enable gpg-agent support for pinentry
git() {
    if [[ "$1" == "commit" || "$1" == "tag" ]]; then
        export GPG_TTY=$(tty)
    fi
    command git "$@"
}
