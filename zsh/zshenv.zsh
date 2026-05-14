# Sets the GPG_TTY to be the same as the TTY, required to enter
# GPG passphrases in a terminal
if [ -n "$TTY" ]; then
  export GPG_TTY=$(tty)
else
  export GPG_TTY="$TTY"
fi

# Select prompt:
#   - "omp": Oh my posh
#   - "omz": Oh my zsh + powerlevel10k
#   - "starship"
export SELECTED_PROMPT="omp"

# Global theme: "onedark" or "nord"
export DOTFILES_THEME="onedark"

# Wezterm theme. DOTFILES_THEME set by default. You can override it here if needed: "onedark" or "nord"
export WEZTERM_THEME=$DOTFILES_THEME
# Starship theme. DOTFILES_THEME set by default. You can override it here if needed: "onedark" or "nord"
export STARSHIP_THEME=$DOTFILES_THEME

# Set the default editor (Zed if installed and not in a ssh connection, nvim otherwise)
if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ]; then
  export EDITOR="nvim"
  export VISUAL="nvim"
elif [ -x "/opt/homebrew/bin/zed" ] || [ -x "$HOME/.local/bin/zed" ] || [ -x "/usr/local/bin/zed" ]; then
  export VISUAL="zed --wait"
  export EDITOR="zed --wait"
else
  export EDITOR="nvim"
  export VISUAL="nvim"
fi
