# dotfiles

Zsh using Zinit Plugin Manager (https://github.com/zdharma-continuum/zinit).

Starship prompt (https://starship.rs/) as customizable shell prompt.

Dotfiles linked using GNU Stow (https://www.gnu.org/software/stow/).

Contains configurations for several tools and applications:
- zsh (customized using **oh my zsh!** + **powerlevel10k**)
- wezterm
- neovim
- tmux
- fzf (configurations and key-bindings)
- terminator

## Prerequisites
- zsh
- git
- stow
- starship
- fzf
- wezterm
- neovim
- tmux
- terminator

## Usage

```shell
git clone git@github.com/albertompe/dotfiles.git ${HOME}/.dotfiles
cd ${HOME}/.dotfiles
make install
