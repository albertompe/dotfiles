# dotfiles

Installs required system packages, uses git submodules and create symlinks with GNU Stow.

Includes:
- zsh customized using **oh my zsh!** + **powerlevel10k**
- vim
- tmux
- fzf
- terminator
- required fonts

## Usage

```shell
git clone git@github.com/albertompe/dotfiles.git ${HOME}/.dotfiles
cd ${HOME}/.dotfiles
make install
