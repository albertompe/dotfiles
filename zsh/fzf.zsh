# Setup fzf
# ---------
export PATH="${PATH:+${PATH}:}${DOTFILES}/fzf/bin"

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "${DOTFILES}/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
# ------------
source "${DOTFILES}/fzf/shell/key-bindings.zsh"
