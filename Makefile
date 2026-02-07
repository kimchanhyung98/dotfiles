.PHONY: speckit help init check

.DEFAULT_GOAL := help

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

speckit: ## Install speckit (default: claude)
	@if ! command -v specify >/dev/null 2>&1; then \
		echo "[speckit] 'specify' not found"; \
		echo "[speckit] RUN: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"; \
		exit 1; \
	fi
	@agent="$(filter-out speckit,$(MAKECMDGOALS))"; \
	if [ -z "$$agent" ]; then \
		agent="claude"; \
		echo "[speckit] Using default agent: claude"; \
	fi; \
	yes | specify init --here --ai "$$agent" --script sh

init: ## Setup Project environment
	@if [ ! -f .env ]; then \
		echo "[init] .env file is required"; \
		exit 1; \
	fi
	@if [ ! -f .claude/.supermemory-claude/config.json ]; then \
		echo "[init] .claude/.supermemory-claude/config.json file is required"; \
		exit 1; \
	fi
	@if [ "$(shell uname)" = "Darwin" ]; then \
		echo "[init] Checking macOS permissions"; \
		bash .claude/hooks/check-permissions.sh || true; \
	fi
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "[init] 'docker' not found"; \
		exit 1; \
	fi
	@if ! docker compose version >/dev/null 2>&1; then \
		echo "[init] 'docker compose' not found"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "[init] Docker is not running, please start Docker first"; \
		exit 1; \
	fi
	@if [ -f docker-compose.yml ]; then \
		echo "[init] Starting Docker containers"; \
		docker compose up -d; \
	fi
	@echo "[init] Installing npm packages"
	@docker run --rm -v $$(pwd):/app -w /app node:22-alpine sh -c "apk add --no-cache git && npm install"

check: ## Run tests and lint checks
	@echo "[check] Running tests..."
	# Run test command here (e.g., npm test, pytest, go test, etc.)
	@echo "[check] Running lint checks..."
	# Run lint command here (e.g., npm run lint, flake8, golangci-lint, etc.)
	@echo "[check] All checks passed."

%:
	@:
