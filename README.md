# dotfiles

Shell and tools install and configure, installing required packages and configuring with git submodules and dotfiles linked using GNU stow.

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
