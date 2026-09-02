.PHONY: help init apply force-scripts test-headless clean-state diff audit-brew

# Color terminal output
YELLOW := \033[33m
GREEN  := \033[32m
BLUE   := \033[34m
RESET  := \033[0m

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
	CHEZMOI_HEADLESS=true CHEZMOI_ENABLE_SERVICES=false chezmoi init
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
	@echo "$(GREEN)[+] GUI Casks installed locally but missing from chezmoi:$(RESET)"
	@MISSING_CASKS=$$(comm -23 <(brew list --cask | sort) <(yq '.packages.darwin.casks[]' .chezmoidata/packages.toml 2>/dev/null | sort)); \
	if [ -z "$$MISSING_CASKS" ]; then \
		echo "    (none - all GUI casks are tracked)"; \
	else \
		echo "$$MISSING_CASKS" | sed 's/^/    - /'; \
	fi
	@echo ""
	@echo "$(BLUE)==================================================$(RESET)"
