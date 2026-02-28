# macOS specific settings

# Update system tools function
system-update() {
  echo "🛠️ Updating system tools..."
  brew update && brew upgrade
  brew upgrade --cask --greedy
  zinit-update
  echo "🎉 Everything's fresh and clean!"
}

# Homebrew installed tools manpages
export MANPATH="$MANPATH:$(brew --prefix)/share/man:$HOME/.local/share/mise/installs/**/share/man"
