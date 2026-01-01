.DEFAULT_GOAL := install

# Detect operating system
OS := $(shell uname | tr "[:upper:]" "[:lower:]")

# List of packages to manage with stow. Default: All packages in stow_packager directory
ifeq ($(OS),linux)
	PACKAGES := fonts nvim terminator tmux zsh
else ifeq ($(OS),darwin)
	PACKAGES := nvim tmux zsh
else
	@echo "No stow packages defined for OS: $(OS)"
endif

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
install: packages init-submodules extra-builds stow		## Install required system packages, configure dotfiles and create symlinks to all packages (default)	

.PHONY: update
update: packages update-submodules extra-builds restow	## Update dotfiles

# Install the required APT packages
.PHONY: packages
ifeq ($(OS),linux)
packages:
	sudo apt -y install cmake make zsh neovim tmux python3-pip autojump fortune curl python3-pynvim stow
else
packages:
	@echo "No package installation defined for OS: $(OS)"
endif

# Initialize git submodules
.PHONY: init-submodules
init-submodules:
	git submodule update --init --recursive

# Update git submodules
.PHONY: update-submodules
update-submodules: init-submodules
	git submodule foreach git pull origin master

.PHONY: extra-builds
extra-builds:
	cd $$(pwd)/tmux/tmux-mem-cpu-load && cmake . && make

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
