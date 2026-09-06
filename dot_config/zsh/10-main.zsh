# Set a secure umask
umask 077

# Path to the zsh config files
export ZSH_CONFIG_FILES="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

# Keep PATH and FPATH free of duplicates. Without this every `exec zsh` or
# `source ~/.zshrc` re-appends each entry below and the variables grow without
# bound for the life of the session.
typeset -U path PATH fpath FPATH

## Configure the PATH
#
# This block runs before any tool initialization: mise lives in ~/.local/bin on
# Linux, and activating it before that directory is on PATH only worked by
# accident on distros whose /etc/profile.d happens to add it.

# Local bin dir, prepended so user- and mise-installed binaries win over the
# system copies rather than being shadowed by them.
export PATH="$HOME/.local/bin:$PATH"

# Add user development settings from dev-profile file
if [[ -f $HOME/dev-tools/dev-profile ]]; then
    source $HOME/dev-tools/dev-profile
fi

# Add custom scripts dir to PATH
if [[ -d $HOME/scripts ]]; then
    export PATH="$PATH:$HOME/scripts"
fi

# Add LM Studio bin dir to PATH (LM Studio CLI - lms)
if [[ -d $HOME/.lmstudio/bin ]]; then
    export PATH="$PATH:$HOME/.lmstudio/bin"
fi

# Add krew (kubectl plugin manager) bin dir to PATH
if [[ -d "${KREW_ROOT:-$HOME/.krew}/bin" ]]; then
    export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
fi

# Antigravity (macOS only in practice; guarded so Linux does not carry a dead
# PATH entry)
if [[ -d "$HOME/.antigravity/antigravity/bin" ]]; then
    export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
fi

# Add Rancher Desktop bin dir to PATH
if [[ -d "$HOME/.rd/bin" ]]; then
    export PATH="$PATH:$HOME/.rd/bin"
fi

# Zsh history configuration
HISTFILE=$HOME/.zsh_history # Location of the history file
HISTSIZE=10000              # Number of commands kept in internal memory
SAVEHIST=10000              # Number of commands physically saved to the file

# Advanced history options
setopt append_history       # Append commands to the file instead of overwriting it
setopt share_history        # Share history across tabs opened at the same time
setopt hist_ignore_all_dups # Do not save consecutive duplicate commands

# Fuzzy search in command history with up/down arrows
# 1. Load the functions for searching through the command history
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search

# 2. Load the zle widgets for the up/down search functions
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# 3. Bind the keys (Compatibilidad total Ubuntu, macOS y SSH)
bindkey "^[[A" up-line-or-beginning-search
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[[B" down-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search

# p10k conditional configuration
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [ "$SELECTED_PROMPT" = "omz" ] && [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

## Tool manager
#
# mise is activated here, before the completion machinery, because it is what
# puts kubectl, oc, k3d, oh-my-posh and the rest on PATH. Nothing below can
# detect those tools until this has run.
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# Zsh completion styles
zstyle ':completion:*' menu select=long-list
zstyle ':completion:*' group-name ''
zstyle ':completion:*' list prompt '%S%M matches%s'
zstyle ':completion:*' max-errors 5

## zinit configuration

# Set the directory where we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Initialize zinit, downloading it if it's not done yet
if [ ! -d "$ZINIT_HOME" ]; then
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# Load zsh plugins.
#
# Order matters: zsh-completions must extend fpath before compinit runs;
# fzf-tab has to be loaded before anything that wraps widgets (upstream
# requirement), so it precedes zsh-autosuggestions; and
# zsh-syntax-highlighting must come last because it wraps every widget
# defined up to that point.
zinit light zsh-users/zsh-completions

# Replace zsh's default completion selection menu with fzf
zinit light Aloxaf/fzf-tab

## Cached tool completions
#
# Completions are generated once into a cache directory on fpath instead of
# being regenerated with `source <(tool completion zsh)` on every startup.
# Each of those subshells costs 150-600ms, and there were four of them.
#
# To refresh after upgrading a tool: rm -rf ~/.cache/zsh/completions
ZSH_COMPLETION_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
[[ -d $ZSH_COMPLETION_CACHE ]] || mkdir -p "$ZSH_COMPLETION_CACHE"
fpath=("$ZSH_COMPLETION_CACHE" $fpath)

# Generate a completion script into the cache if it is not there yet.
# Usage: _cache_completion <command> <completion-name> [args...]
_cache_completion() {
    local cmd=$1 name=$2
    shift 2
    command -v "$cmd" &>/dev/null || return 0
    local target="$ZSH_COMPLETION_CACHE/$name"
    [[ -s $target ]] && return 0
    if "$cmd" "$@" >"$target.tmp" 2>/dev/null && [[ -s $target.tmp ]]; then
        mv "$target.tmp" "$target"
    else
        rm -f "$target.tmp"
    fi
}

_cache_completion oc      _oc      completion zsh
_cache_completion kubectl _kubectl completion zsh
_cache_completion docker  _docker  completion zsh
_cache_completion podman  _podman  completion zsh
_cache_completion k3d     _k3d     completion zsh

unfunction _cache_completion

# compinit runs here, once, now that fpath carries both the plugin completions
# and the cached tool completions. -C skips the fpath security audit, which is
# the expensive part.
autoload -Uz compinit && compinit -C

# These wrap widgets, so they load after the completion system is up.
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting

# disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# set descriptions format to enable group support
# NOTE: don't use escape sequences (like '%F{red}%d%f') here, fzf-tab will ignore them
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
# force zsh not to show completion menu, which allows fzf-tab to capture the unambiguous prefix
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# custom fzf flags
# NOTE: fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --color=fg:1,fg+:2 --bind=tab:accept
# To make fzf-tab follow FZF_DEFAULT_OPTS.
# NOTE: This may lead to unexpected behavior since some flags break this plugin. See Aloxaf/fzf-tab#455.
zstyle ':fzf-tab:*' use-fzf-default-opts yes
# switch group using `<` and `>`
zstyle ':fzf-tab:*' switch-group '<' '>'
# Use fzf-tmux-popup to display fzf in a tmux popup window if inside tmux
zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup

## Prompt configuration

# Oh my posh conditional configuration
if [ "$SELECTED_PROMPT" = "omp" ]; then
    eval "$(oh-my-posh init zsh --config $ZSH_CONFIG_FILES/oh-my-posh/omp-config.toml)"
fi

# p10k conditional configuration
if [ "$SELECTED_PROMPT" = "omz" ]; then
    zinit light ohmyzsh/ohmyzsh
    zinit ice depth=1
    zinit light romkatv/powerlevel10k
fi

# Starship conditional configuration
if [ "$SELECTED_PROMPT" = "starship" ]; then
    export STARSHIP_CONFIG="${ZSH_CONFIG_FILES}/starship/starship.toml"
    eval "$(starship init zsh)"
    starship config palette $STARSHIP_THEME
fi

# p10k conditional configuration
# Load Powerlevel10k theme.
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[ "$SELECTED_PROMPT" = "omz" ] && source $ZSH_CONFIG_FILES/p10k-themes/p10k-lean.zsh

## fzf configuration

# fzf base configuration
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
    tree) find . -type d | fzf --preview 'tree -C {}' "$@" ;;
    *) fzf "$@" ;;
    esac
}

## Custom experience configuration

# zoxide initialization
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi

## Configure autocompletions

# terraform ships no zsh completion; it uses the bash completion bridge
if command -v terraform &>/dev/null; then
    autoload -U +X bashcompinit && bashcompinit
    complete -o nospace -C "$(command -v terraform)" terraform
fi

## Other tools

# direnv
if command -v direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi
