.PHONY: help init apply diff force-scripts test-headless clean-state \
        lint lint-templates lint-toml lint-actions \
        audit-brew audit-flatpaks audit-zed-extensions

# audit goals rely on bash process substitution (<(...))
SHELL := $(shell command -v bash 2>/dev/null || echo /bin/bash)
# Default flags are just `-c`, so make only ever sees the status of the last
# command in a recipe line. Every audit target below is one long continued
# line, which silently swallowed failures in the middle of it.
.SHELLFLAGS := -e -o pipefail -c

# Colors are built with printf so the bytes are real escapes. Defining them as
# literal "\033[..." only works inside awk, which does its own unescaping; the
# bash builtin echo prints them verbatim without -e.
YELLOW := $(shell printf '\033[33m')
GREEN  := $(shell printf '\033[32m')
BLUE   := $(shell printf '\033[34m')
RED    := $(shell printf '\033[31m')
RESET  := $(shell printf '\033[0m')

# Zed settings are JSONC (trailing commas + // comments); jq/yq can't read them
# directly. The helper is string-aware, so a "https://..." value is not
# mistaken for a comment.
JSONC2JSON := python3 .ci/jsonc2json.py

help: ## Show this help message
	@echo "$(GREEN)Dotfiles Management Commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-22s$(RESET) %s\n", $$1, $$2}'

init: ## Re-evaluate chezmoi initial configuration interactively
	rm -f ~/.config/chezmoi/chezmoi.toml
	chezmoi init

apply: ## Apply dotfiles and template changes without forcing completed scripts
	chezmoi apply

diff: ## Display a dry-run simulation of pending changes
	chezmoi apply --dry-run --verbose

force-scripts: ## Force full re-execution of ALL run_once_ scripts
	@echo "$(YELLOW)Re-installing packages and re-running scripts...$(RESET)"
	chezmoi state delete-bucket --bucket=scriptState
	chezmoi apply

test-headless: ## Simulate initialization on a headless server (no GUI)
	rm -f ~/.config/chezmoi/chezmoi.toml
	CHEZMOI_HEADLESS=true CHEZMOI_ENABLE_CONTAINER_SERVICES=false chezmoi init
	chezmoi apply --dry-run --verbose

clean-state: ## Purge local chezmoi state database buckets
	@echo "$(YELLOW)Purging chezmoi local state database...$(RESET)"
	chezmoi state delete-bucket --bucket=scriptState || true
	chezmoi state delete-bucket --bucket=entryState || true

lint: ## Run every static check CI runs (templates, TOML, workflows)
	@.ci/lint.sh all

lint-templates: ## Render run_once templates and check bash syntax + shellcheck
	@.ci/lint.sh templates

lint-toml: ## Verify every TOML file in the repo parses
	@.ci/lint.sh toml

lint-actions: ## Run actionlint over .github/workflows
	@.ci/lint.sh actions

audit-brew: ## Compare installed Homebrew packages against dotfiles manifest
	@command -v yq >/dev/null 2>&1 || { echo "$(YELLOW)==> Error: 'yq' is required for auditing. Install it via 'mise' or 'brew install yq'.$(RESET)"; exit 1; }
	@command -v brew >/dev/null 2>&1 || { echo "$(YELLOW)==> Error: 'brew' is required for this audit (macOS or Linuxbrew only).$(RESET)"; exit 1; }
	@echo "$(BLUE)==================================================$(RESET)"
	@echo "$(BLUE)  HOMEBREW DRIFT AUDIT (Local vs. Dotfiles)       $(RESET)"
	@echo "$(BLUE)==================================================$(RESET)"
	@echo ""
	@echo "$(GREEN)[+] CLI Formulas installed locally but missing from chezmoi:$(RESET)"
	@MISSING_BREWS=$$(comm -23 <(brew leaves | sort) <(yq -p toml -o yaml '.packages.darwin.brews[]' .chezmoidata/packages.toml | sort)); \
	if [ -z "$$MISSING_BREWS" ]; then \
		echo "    (none - all CLI formulas are tracked)"; \
	else \
		echo "$$MISSING_BREWS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(RED)[-] CLI Formulas in chezmoi but not installed locally:$(RESET)"
	@STALE_BREWS=$$(comm -13 <(brew leaves | sort) <(yq -p toml -o yaml '.packages.darwin.brews[]' .chezmoidata/packages.toml | sort)); \
	if [ -z "$$STALE_BREWS" ]; then \
		echo "    (none - all tracked formulas are installed)"; \
	else \
		echo "$$STALE_BREWS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(GREEN)[+] GUI Casks installed locally but missing from chezmoi:$(RESET)"
	@MISSING_CASKS=$$(comm -23 <(brew list --cask | sort) <(yq -p toml -o yaml '.packages.darwin.casks[]' .chezmoidata/packages.toml | sort)); \
	if [ -z "$$MISSING_CASKS" ]; then \
		echo "    (none - all GUI casks are tracked)"; \
	else \
		echo "$$MISSING_CASKS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(RED)[-] GUI Casks in chezmoi but not installed locally:$(RESET)"
	@STALE_CASKS=$$(comm -13 <(brew list --cask | sort) <(yq -p toml -o yaml '.packages.darwin.casks[]' .chezmoidata/packages.toml | sort)); \
	if [ -z "$$STALE_CASKS" ]; then \
		echo "    (none - all tracked casks are installed)"; \
	else \
		echo "$$STALE_CASKS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(BLUE)==================================================$(RESET)"

audit-flatpaks: ## Compare installed Flatpak apps against dotfiles manifest
	@command -v yq >/dev/null 2>&1 || { echo "$(YELLOW)==> Error: 'yq' is required for auditing. Install it via 'mise' or 'brew install yq'.$(RESET)"; exit 1; }
	@command -v flatpak >/dev/null 2>&1 || { echo "$(YELLOW)==> Error: 'flatpak' is required for auditing.$(RESET)"; exit 1; }
	@echo "$(BLUE)==================================================$(RESET)"
	@echo "$(BLUE)  FLATPAK DRIFT AUDIT (Local vs. Dotfiles)        $(RESET)"
	@echo "$(BLUE)==================================================$(RESET)"
	@echo ""
	@echo "$(GREEN)[+] Installed locally but missing from chezmoi:$(RESET)"
	@MISSING=$$(comm -23 <(flatpak list --app --columns=application | sort) <(yq -p toml -o yaml '.flatpak.gui_apps[], .flatpak.cli_apps[]' .chezmoidata/flatpaks.toml | sort)); \
	if [ -z "$$MISSING" ]; then \
		echo "    (none - all Flatpak apps are tracked)"; \
	else \
		echo "$$MISSING" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(RED)[-] In chezmoi but not installed locally:$(RESET)"
	@STALE=$$(comm -13 <(flatpak list --app --columns=application | sort) <(yq -p toml -o yaml '.flatpak.gui_apps[], .flatpak.cli_apps[]' .chezmoidata/flatpaks.toml | sort)); \
	if [ -z "$$STALE" ]; then \
		echo "    (none - all tracked Flatpak apps are installed)"; \
	else \
		echo "$$STALE" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(BLUE)==================================================$(RESET)"

audit-zed-extensions: ## Compare installed Zed extensions against auto_install_extensions in settings
	@command -v jq >/dev/null 2>&1 || { echo "$(YELLOW)==> Error: 'jq' is required. Install it via 'mise' or 'brew install jq'.$(RESET)"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "$(YELLOW)==> Error: 'python3' is required.$(RESET)"; exit 1; }
	@ZED_EXT_DIR="$${XDG_DATA_HOME:-$$HOME/.local/share}/zed/extensions/installed"; \
	SETTINGS="$(CURDIR)/dot_config/zed/settings.json"; \
	if [ ! -d "$$ZED_EXT_DIR" ]; then echo "$(YELLOW)==> No Zed extensions dir found: $$ZED_EXT_DIR$(RESET)"; exit 0; fi; \
	TRACKED="$$($(JSONC2JSON) < "$$SETTINGS" | jq -r '.auto_install_extensions // {} | to_entries | map(select(.value == true) | .key) | sort[]')"; \
	INSTALLED="$$(cd "$$ZED_EXT_DIR" && find . -maxdepth 1 -mindepth 1 -exec basename {} \; | sort)"; \
	echo "$(BLUE)==================================================$(RESET)"; \
	echo "$(BLUE)   ZED EXTENSIONS DRIFT AUDIT (Local vs. Dotfiles)  $(RESET)"; \
	echo "$(BLUE)==================================================$(RESET)"; \
	echo ""; \
	echo "$(GREEN)[+] Installed locally but missing from auto_install_extensions:$(RESET)"; \
	UNTRACKED=$$(comm -23 <(printf '%s\n' "$$INSTALLED") <(printf '%s\n' "$$TRACKED" | sort)); \
	if [ -z "$$UNTRACKED" ]; then echo "    (none - all local extensions are tracked)"; else echo "$$UNTRACKED" | sed 's/^/    - /'; fi; \
	echo ""; \
	echo "$(RED)[-] Declared in auto_install_extensions but not installed locally:$(RESET)"; \
	NOTINSTALLED=$$(comm -13 <(printf '%s\n' "$$INSTALLED") <(printf '%s\n' "$$TRACKED" | sort)); \
	if [ -z "$$NOTINSTALLED" ]; then echo "    (none - all tracked extensions are installed)"; else echo "$$NOTINSTALLED" | sed 's/^/    - /'; fi; \
	echo ""; \
	echo "$(BLUE)==================================================$(RESET)"
