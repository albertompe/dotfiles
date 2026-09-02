.PHONY: help init apply force-scripts test-headless test-ci clean-state diff

# Color terminal output
YELLOW := \033[33m
GREEN  := \033[32m
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
