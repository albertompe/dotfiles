# Sets the GPG_TTY to be the same as the TTY, required to enter
# GPG passphrases in a terminal
if [ -n "$TTY" ]; then
  export GPG_TTY=$(tty)
else
  export GPG_TTY="$TTY"
fi

# Select prompt: "p10k" or "starship"
export SELECTED_PROMPT="starship"

# Global theme: "onedark" or "nord"
export DOTFILES_THEME="onedark"

# Wezterm theme. DOTFILES_THEME set by default. You can override it here if needed: "onedark" or "nord"
export WEZTERM_THEME=$DOTFILES_THEME
# Starship theme. DOTFILES_THEME set by default. You can override it here if needed: "onedark" or "nord"
export STARSHIP_THEME=$DOTFILES_THEME

# Use Neovim as default editor
export EDITOR="nvim"
export VISUAL="nvim"
