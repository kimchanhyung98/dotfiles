.PHONY: spec-kit agent-os help init

.DEFAULT_GOAL := help

help: ## Show available commands
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n\nTargets:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

spec-kit: ## Install spec-kit (default: claude)
	@agent=$(word 2,$(MAKECMDGOALS)); \
	if [ -z "$$agent" ]; then \
		agent="claude"; \
		echo "[spec-kit] Using default agent: claude"; \
	fi; \
	if ! command -v specify >/dev/null 2>&1; then \
		echo "[spec-kit] 'specify' not found"; \
		echo "[spec-kit] RUN: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"; \
		exit 1; \
	fi; \
	yes | specify init --here --ai $$agent --script sh

init: ## Setup Project environment
	@if [ "$(shell uname)" = "Darwin" ]; then \
		echo "[init] Checking macOS permissions"; \
		bash .claude/hooks/check-permissions.sh || true; \
	fi
	@if command -v claude >/dev/null 2>&1; then \
		echo "[init] Setting up claude-hud"; \
		claude -p "/claude-hud:setup" --model=sonnet --dangerously-skip-permissions; \
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
	@if [ ! -f .env ]; then \
		echo "[init] Copying .env.example to .env"; \
		cp .env.example .env; \
	fi
	@if [ -f docker-compose.yml ]; then \
		echo "[init] Starting Docker containers"; \
		docker compose up -d; \
	fi
	@echo "[init] Installing npm packages"
	@docker run --rm -v $$(pwd):/app -w /app node:22-alpine sh -c "apk add --no-cache git && npm install"

%:
	@:
