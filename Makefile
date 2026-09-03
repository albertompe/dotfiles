.PHONY: help init apply force-scripts test-headless clean-state diff audit-brew audit-flatpaks audit-zed-extensions

# audit goals rely on bash process substitution (<(...))
SHELL := /bin/bash

# Color terminal output
YELLOW := \033[33m
GREEN  := \033[32m
BLUE   := \033[34m
RED    := \033[31m
RESET  := \033[0m

# Zed settings are JSONC (trailing commas + // comments); jq/yq can't read them directly
JSONC2JSON := python3 -c "import sys,re,json; s=sys.stdin.read(); s='\n'.join(re.sub(r'//.*$$','',l) for l in s.splitlines()); s=re.sub(r',\s*([}\]])',r'\1',s); print(json.dumps(json.loads(s)))"

help: ## Show this help message
	@echo "$(GREEN)Dotfiles Management Commands:$(RESET)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-18s$(RESET) %s\n", $$1, $$2}'

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

audit-brew: ## Compare installed Homebrew packages against dotfiles manifest
	@command -v yq >/dev/null 2>&1 || { echo "$(YELLOW)==> Error: 'yq' is required for auditing. Install it via 'mise' or 'brew install yq'.$(RESET)"; exit 1; }
	@echo "$(BLUE)==================================================$(RESET)"
	@echo "$(BLUE)  HOMEBREW DRIFT AUDIT (Local vs. Dotfiles)       $(RESET)"
	@echo "$(BLUE)==================================================$(RESET)"
	@echo ""
	@echo "$(GREEN)[+] CLI Formulas installed locally but missing from chezmoi:$(RESET)"
	@MISSING_BREWS=$$(comm -23 <(brew leaves | sort) <(yq '.packages.darwin.brews[]' .chezmoidata/packages.toml 2>/dev/null | sort)); \
	if [ -z "$$MISSING_BREWS" ]; then \
		echo "    (none - all CLI formulas are tracked)"; \
	else \
		echo "$$MISSING_BREWS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(RED)[-] CLI Formulas in chezmoi but not installed locally:$(RESET)"
	@STALE_BREWS=$$(comm -13 <(brew leaves | sort) <(yq '.packages.darwin.brews[]' .chezmoidata/packages.toml 2>/dev/null | sort)); \
	if [ -z "$$STALE_BREWS" ]; then \
		echo "    (none - all tracked formulas are installed)"; \
	else \
		echo "$$STALE_BREWS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(GREEN)[+] GUI Casks installed locally but missing from chezmoi:$(RESET)"
	@MISSING_CASKS=$$(comm -23 <(brew list --cask | sort) <(yq '.packages.darwin.casks[]' .chezmoidata/packages.toml 2>/dev/null | sort)); \
	if [ -z "$$MISSING_CASKS" ]; then \
		echo "    (none - all GUI casks are tracked)"; \
	else \
		echo "$$MISSING_CASKS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(RED)[-] GUI Casks in chezmoi but not installed locally:$(RESET)"
	@STALE_CASKS=$$(comm -13 <(brew list --cask | sort) <(yq '.packages.darwin.casks[]' .chezmoidata/packages.toml 2>/dev/null | sort)); \
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
	@MISSING=$$(comm -23 <(flatpak list --app --columns=application | sort) <(yq '.flatpak.gui_apps[]' .chezmoidata/flatpaks.toml 2>/dev/null | sort)); \
	if [ -z "$$MISSING" ]; then \
		echo "    (none - all Flatpak apps are tracked)"; \
	else \
		echo "$$MISSING" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(RED)[-] In chezmoi but not installed locally:$(RESET)"
	@STALE=$$(comm -13 <(flatpak list --app --columns=application | sort) <(yq '.flatpak.gui_apps[]' .chezmoidata/flatpaks.toml 2>/dev/null | sort)); \
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
	SETTINGS="dot_config/zed/settings.json"; \
	if [ ! -d "$$ZED_EXT_DIR" ]; then echo "$(YELLOW)==> No Zed extensions dir found: $$ZED_EXT_DIR$(RESET)"; exit 0; fi; \
	TRACKED="$$($(JSONC2JSON) < "$$SETTINGS" | jq -r '.auto_install_extensions // {} | to_entries | map(select(.value == true) | .key) | sort[]')"; \
	echo "$(BLUE)==================================================$(RESET)"; \
	echo "$(BLUE)   ZED EXTENSIONS DRIFT AUDIT (Local vs. Dotfiles)  $(RESET)"; \
	echo "$(BLUE)==================================================$(RESET)"; \
	echo ""; \
	echo "$(GREEN)[+] Installed locally but missing from auto_install_extensions:$(RESET)"; \
	UNTRACKED=$$(comm -23 <(ls "$$ZED_EXT_DIR" | sort) <(printf '%s\n' $$TRACKED | sort)); \
	if [ -z "$$UNTRACKED" ]; then echo "    (none - all local extensions are tracked)"; else echo "$$UNTRACKED" | sed 's/^/    - /'; fi; \
	echo ""; \
	echo "$(RED)[-] Declared in auto_install_extensions but not installed locally:$(RESET)"; \
	NOTINSTALLED=$$(comm -13 <(ls "$$ZED_EXT_DIR" | sort) <(printf '%s\n' $$TRACKED | sort)); \
	if [ -z "$$NOTINSTALLED" ]; then echo "    (none - all tracked extensions are installed)"; else echo "$$NOTINSTALLED" | sed 's/^/    - /'; fi; \
	echo ""; \
	echo "$(BLUE)==================================================$(RESET)"
