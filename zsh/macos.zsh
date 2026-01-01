# macOS specific settings

# Update system tools function
system-update() {
  echo "🛠️ Updating system tools..."
  brew update && brew upgrade
  zinit-update
  echo "🎉 Everything's fresh and clean!"
}
