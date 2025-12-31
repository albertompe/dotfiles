# Set a secure umask
umask 077

# Set the GPG_TTY to be the same as the TTY, required to enter
# GPG passphrases in a terminal.
if [ -n "$TTY" ]; then
  export GPG_TTY=$(tty)
else
  export GPG_TTY="$TTY"
fi

# Aliases definition
source $DOTFILES/zsh/aliases.zsh

# FZF settings
source $DOTFILES/zsh/fzf.zsh

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
