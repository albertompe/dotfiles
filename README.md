# dotfiles

Zsh using Zinit Plugin Manager (<https://github.com/zdharma-continuum/zinit>).

Oh my posh (<https://ohmyposh.dev/>) engine is used by default, with its pleasant transient prompt and minimalist configuration inspired by DreamsOfAutonomy's Zen zsh (<https://github.com/dreamsofautonomy/zen-omp>). But, you can also useStarship prompt (<https://starship.rs/>) as customizable shell prompt, or Oh My Zsh (<https://ohmyz.sh/>) + Powerlevel10k(<https://github.com/romkatv/powerlevel10k>), enabling it through the `SELECTED_PROMPT` environment variable.

Dotfiles linked using GNU Stow (<https://www.gnu.org/software/stow/>).

Contains configurations for several tools and applications:

- zsh (customized using **oh my zsh!** + **powerlevel10k**)
- wezterm
- neovim
- tmux
- fzf (configurations and key-bindings)
- terminator

## Prerequisites

- zsh
- Oh my posh (<https://ohmyposh.dev/>)
- git
- stow
- starship
- fzf
- wezterm
- neovim
- tmux
- terminator
- eza (<https://github.com/eza-community/eza>)
- zoxide (<https://github.com/ajeetdsouza/zoxide>)

## Usage

```shell
git clone git@github.com/albertompe/dotfiles.git ${HOME}/.dotfiles
cd ${HOME}/.dotfiles
make install

## Github saturation fix

`mise install` can saturate Github's API, discovering the available releases for each plugin. If you get errors related to this you can use a Github token to avoid hitting the rate limit. Create a classic token with no permissions and set it in the `GITHUB_TOKEN` environment variable:

```shell
export MISE_GITHUB_TOKEN=your_token_here
```
