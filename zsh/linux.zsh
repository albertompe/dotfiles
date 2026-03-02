# Linux specific settings

# Update system tools function
system-update() {
  echo "🛠️ Updating system tools..."
  echo "🔄 Updating apt packages..."
  sudo apt update && sudo apt upgrade -y
  echo "✅ apt packages updated!"
  zinit-update
  mise-update
  krew-plugins-update
  echo "🎉 Everything's fresh and clean!"
}
