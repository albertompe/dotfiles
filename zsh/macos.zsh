# macOS specific settings

# Update system tools function
system-update() {
  echo "🛠️ Updating system tools..."
  echo "🔄 Updating brew tools and casks..."
  brew update && brew upgrade
  brew upgrade --cask --greedy
  echo "✅ brew updated!"
  zinit-update
  mise-update
  echo "🎉 Everything's fresh and clean!"
}

# Homebrew installed tools manpages
export MANPATH="$MANPATH:$(brew --prefix)/share/man:$HOME/.local/share/mise/installs/**/share/man"
