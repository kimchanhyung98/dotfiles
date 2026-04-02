.PHONY: help dev check claude init speckit

.DEFAULT_GOAL := help

help: ## 사용 가능한 명령어 목록 출력
	@awk 'BEGIN {FS = ":.*##"; printf "\n사용법:\n  make \033[36m<target>\033[0m\n\n명령어:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

dev: ## 전체 설정 (init + claude + speckit)
	@$(MAKE) init
	@$(MAKE) claude
	@$(MAKE) speckit

check: ## 테스트 및 린트 검사 실행
ifeq ($(shell uname),Darwin)
	@echo "[check] Running macOS tests (read-only)"
	@bash tests/macos.sh
endif
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "[check] 'docker' not found"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "[check] Docker is not running, please start Docker first"; \
		exit 1; \
	fi
	@echo "[check] Building Linux test container"
	@docker build --no-cache -q -t dotfiles-test -f tests/Dockerfile .
	@docker run --rm dotfiles-test
	@echo "[check] all checks passed"

claude: ## Claude Code 환경 설정
	@echo "[claude] downloading AGENTS.md..."
	@tmp_claude=$$(mktemp); \
	claude_url="https://raw.githubusercontent.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md"; \
	if ! curl -fsSL "$$claude_url" -o "$$tmp_claude"; then \
		rm -f "$$tmp_claude"; \
		echo "[claude] AGENTS.md download failed"; \
		exit 1; \
	fi; \
	if [ -f AGENTS.md ] && grep -qF "Behavioral guidelines to reduce common LLM coding mistakes" AGENTS.md; then \
		echo "[claude] AGENTS.md already up to date"; \
	elif [ -f AGENTS.md ]; then \
		printf '\n' >> AGENTS.md; \
		cat "$$tmp_claude" >> AGENTS.md; \
	else \
		mv "$$tmp_claude" AGENTS.md; \
	fi; \
	rm -f "$$tmp_claude"

init: ## 프로젝트 환경 설정
	@if [ ! -f .env ]; then \
		echo "[init] .env not found"; \
		exit 1; \
	fi
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "[init] docker not found"; \
		exit 1; \
	fi
	@if ! docker compose version >/dev/null 2>&1; then \
		echo "[init] docker compose not found"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "[init] docker is not running"; \
		exit 1; \
	fi
	@if [ -f docker-compose.yml ]; then \
		echo "[init] starting docker containers..."; \
		docker compose up -d; \
	fi
	@echo "[init] installing npm packages..."
	@docker run --rm -v $$(pwd):/app -w /app node:22-alpine sh -c "apk add --no-cache git && npm install"

speckit: ## speckit 설치 (AGENT=claude, 예: make speckit AGENT=copilot)
	@if ! command -v specify >/dev/null 2>&1; then \
		echo "[speckit] specify not found"; \
		echo "[speckit] run: uv tool install specify-cli --from git+https://github.com/github/spec-kit.git"; \
		exit 1; \
	fi
	@yes | specify init --here --ai "$(or $(AGENT),claude)" --script sh
