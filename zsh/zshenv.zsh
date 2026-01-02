# Sets the GPG_TTY to be the same as the TTY, required to enter
# GPG passphrases in a terminal
if [ -n "$TTY" ]; then
  export GPG_TTY=$(tty)
else
  export GPG_TTY="$TTY"
fi

# Wezterm theme (onedark or nord)
export WEZTERM_THEME="onedark"
# Starship theme (onedark or nord)
export STARSHIP_THEME="onedark"

# Use Neovim as default editor
export EDITOR="nvim"
export VISUAL="nvim"
