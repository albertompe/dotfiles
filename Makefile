.DEFAULT_GOAL := install

# Detect operating system
OS := $(shell uname | tr "[:upper:]" "[:lower:]")

# List of packages to manage with stow. Default: All packages in stow_packager directory
ifeq ($(OS),linux)
	PACKAGES := fonts nvim terminator tmux zsh wezterm mise
else ifeq ($(OS),darwin)
	PACKAGES := nvim tmux zsh wezterm mise
else
	@echo "No stow packages defined for OS: $(OS)"
endif

# List of krew plugins to be installed.
KREW_PLUGINS := krew profefe neat edit-status rabbitmq

# Directory where stow will look for packages
STOW_SRC_DIR ?= $$(pwd)/stow_packages

# Default location where stow will create symbolic links
STOW_TARGET_DIR ?= ${HOME}

# Stow command to create links
STOW_CMD = stow \
	--dir="${STOW_SRC_DIR}" \
	--target="${STOW_TARGET_DIR}" \
	--no-folding \
	--dotfiles \
	--verbose

# Function to backup existing files for a specific package if they exist
# egrep + sed combined is used instead of native grep -e syntax to be
# compatible with non GNU grep on MacOS.
define backup_if_exists
	echo "Backing up existing files for package: ${1}"; \
	checks=$$(${STOW_CMD} --no ${1} 2>&1 | \
		grep 'cannot stow' | \
		sed -n 's/.*existing target \([^[:space:]]*\).*/\1/p'); \
	for file in $$checks; do \
		echo "Found existing file to backup: $$file"; \
		filepath=${STOW_TARGET_DIR}/$$file; \
		backup_suffix="backup-$$(date -u +%Y%m%d%H%M%S)"; \
		echo "Creating backup $$filepath.$$backup_suffix"; \
		mv "$$filepath" "$$filepath.$$backup_suffix"; \
	done
endef

##@ Dotfiles install

.PHONY: install
install: tools stow	mise-install krew-plugins-install	## Install required system tools, configure dotfiles and create symlinks (default)

.PHONY: update
update: tools restow zinit-update krew-plugins-update	## Update dotfiles

mise-install:
	mise install

# Install the required APT tools
.PHONY: tools
ifeq ($(OS),linux)
tools:
	sudo apt -y install cmake make zsh neovim tmux python3-pip autojump fortune curl python3-pynvim stow
else ifeq ($(OS),darwin)
	brew install stow mise oh-my-posh starship
else
tools:
	@echo "No tools installation defined for OS: $(OS)"
endif

##@ Symlinks management

.PHONY: debug
debug:			## Show stow detailed operations
	${STOW_CMD} --no $(PACKAGES) 2>&1

# Backup existing files before create symlinks
.PHONY: backup
backup:
	@echo "Checking for existing files to backup..."
	@$(foreach package,$(PACKAGES), \
		$(call backup_if_exists,$(package));)

.PHONY: stow
stow: backup	## Create symlinks
	@echo "Applying stow for packages..."
	@$(foreach package,${PACKAGES}, \
		$(STOW_CMD) ${package};)

.PHONY: unstow
unstow:		## Remove symlincs
	@echo "Removing stow links for packages..."
	@$(foreach package,$(PACKAGES), \
		$(STOW_CMD) -D $(package);)

.PHONY: restow
restow: backup unstow stow	## Reapply symlinks

##@ Zinit management

.PHONY: zinit-update
zinit-update:		## Update zinit and zinit plugins
	zsh -c 'source $${HOME}/.zshrc; zinit-update'	

.PHONY: help
help:
	@echo ""
	@echo "\033[1mUsage\033[0m"
	@echo "  make \033[36m<target>\033[0m"
	@echo "  make \033[36mhelp\033[0m        Shows this help"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""

##@ MacOS specific tools installation

.PHONY: brew-tools
ifeq ($(OS),darwin)
brew-tools:		## Install Homebrew formulae and casks defined in Brewfile (MacOS only)
	brew bundle --file=./Brewfile
endif

ifeq ($(OS),darwin)
brew-update-dump:	## Dump Homebrew formulae and casks to Brewfile (MacOS only)
	brew bundle dump --file=./Brewfile --no-vscode --no-go --force
endif

##@ Krew management

krew-plugins-install:		## Install krew plugins defined in KREW_PLUGINS variable
	krew install $(KREW_PLUGINS)

krew-plugins-update:		## Update krew plugins defined in KREW_PLUGINS variable
	krew upgrade
