# Linux specific settings

# Update system tools function
system-update() {
  echo "🛠️ Updating system tools..."
  sudo apt update && sudo apt upgrade -y
  zinit-update
  echo "🎉 Everything's fresh and clean!"
}
