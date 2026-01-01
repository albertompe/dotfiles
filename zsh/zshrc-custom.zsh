# Set a secure umask
umask 077

# Set the GPG_TTY to be the same as the TTY, required to enter
# GPG passphrases in a terminal
if [ -n "$TTY" ]; then
  export GPG_TTY=$(tty)
else
  export GPG_TTY="$TTY"
fi

# Path to the dotfiles
export DOTFILES="$HOME/.dotfiles"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Initialize zsh complations with caching
autoload -Uz compinit && compinit -C

# Zsh completion styles
zstyle ':completion:*' menu select=long-list
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list prompt '%S%M matches%s'
zstyle ':completion:*' max-errors 5

# Set the directory where we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Initialize zinit, downloading it if it's not done yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

zinit light ohmyzsh/ohmyzsh
zinit ice depth=1; zinit light romkatv/powerlevel10k
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# fzf configuration
export FZF_BASE="$HOME/.fzf"
export FZF_COMPLETION_TRIGGER='**'
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout reverse
    --border rounded
    --prompt '∷ '
    --pointer ▶
    --marker ⇒"

# Load fzf key-bindings and completion when installing
# CTRL-T: Fuzzy find all files and subdirectories of the working directory, and output the selection to STDOUT
# CTRL-R: Fuzzy find through your shell history, and output the selection to STDOUT
# ALT-C (Esc + C if using macOS): Fuzzy find all subdirectories of the working directory, and run the command “cd” with the output as argument
zinit ice wait lucid atinit"source shell/key-bindings.zsh; source shell/completion.zsh"
zinit light junegunn/fzf

# Custom fzf command completion runner
_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    tree)         find . -type d | fzf --preview 'tree -C {}' "$@";;
    *)            fzf "$@" ;;
  esac
}

# Update zinit and plugins
zinit-update() {
    echo "🔄 Updating zinit..."
    zinit self-update
    echo "✅ zinit updated!"
    echo "🔄 Updating zinit plugins..."
    zinit update --all
    echo "✅ All zinit plugins updated!"
}

# Load Powerlevel10k theme.
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
source $DOTFILES/zsh/themes/p10k-lean.zsh

# Aliases definition
source $DOTFILES/zsh/aliases.zsh

# macOS and Linux specific settings
local uname="$(uname -s)"
[[ ${uname} == "Darwin" ]] && source $DOTFILES/zsh/macos.zsh
[[ ${uname} == "Linux" ]] && source $DOTFILES/zsh/linux.zsh
unset uname

# batdiff: use bat to show git diffs
batdiff() {
    git diff --name-only --diff-filter=d | xargs bat --diff
}

# Add user development settings from dev-profile file
if [[ -f $HOME/dev-tools/dev-profile ]]; then
    source $HOME/dev-tools/dev-profile
fi

# Add custom scripts dir to PATH
if [[ -d $HOME/scripts ]]; then
    export PATH=$PATH:$HOME/scripts
fi

# Add LM Studio bin dir to PATH
if [[ -d $HOME/.lmstudio/bin ]]; then
    export PATH="$PATH:$HOME/.lmstudio/bin"
fi

# Add krew (kubectl plugin manager) bin dir to PATH
if [[ -d "${KREW_ROOT:-$HOME/.krew}/bin" ]]; then
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi

# goenv
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - zsh)"

# oc autocompletion
if command -v oc &> /dev/null; then
    source <(oc completion zsh)
fi

# kubectl autocompletion
if command -v kubectl &> /dev/null; then
    source <(kubectl completion zsh)
fi

# docker autocompletion
if command -v docker &> /dev/null; then
    if [ ! -d ~/.docker/completions ]; then
        mkdir -p $HOME/.docker/completions
    fi
    if [ ! -f ~/.docker/completions/_docker ]; then
        docker completion zsh > $HOME/.docker/completions/_docker
    fi

    FPATH="$HOME/.docker/completions:$FPATH"
    autoload -Uz compinit
    compinit
fi

# terraform autocompletion
if command -v terraform &> /dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C $(command -v terraform) terraform
fi

# nvm (Node Version Manager) 
if [[ -d "/opt/homebrew/opt/nvm" ]]; then
    export NVM_DIR="$HOME/.nvm"
    # Load nvm
    [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
    # Load nvm bash_completion
    [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
fi
