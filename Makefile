.PHONY: help check test test-macos test-linux init

.DEFAULT_GOAL := help

help: ## 사용 가능한 명령어 목록 출력
	@awk 'BEGIN {FS = ":.*##"; printf "\n사용법:\n  make \033[36m<target>\033[0m\n\n명령어:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

check: ## 빠른 정적·격리 검사 실행
	@bash tests/run.sh local

test: check ## 현재 플랫폼에서 macOS·Linux 전체 테스트 실행
	@case "$$(uname -s)" in \
		Darwin) $(MAKE) --no-print-directory test-macos ;; \
		Linux) echo "[test] skipping macOS tests on Linux" ;; \
		*) echo "[test] unsupported host: $$(uname -s)"; exit 1 ;; \
	esac
	@$(MAKE) --no-print-directory test-linux
	@echo "[test] all tests passed"

test-macos: ## macOS 로컬 통합 테스트 실행
	@if [ "$$(uname -s)" != "Darwin" ]; then \
		echo "[test-macos] macOS host required"; \
		exit 1; \
	fi
	@bash tests/run.sh macos

test-linux: ## Linux 통합 테스트 실행(macOS에서는 Ubuntu 26.04 Docker 사용)
	@set -e; case "$$(uname -s)" in \
		Darwin) \
			if ! command -v docker >/dev/null 2>&1; then \
				echo "[test-linux] docker not found"; \
				exit 1; \
			fi; \
			if ! docker info >/dev/null 2>&1; then \
				echo "[test-linux] Docker daemon is not running"; \
				exit 1; \
			fi; \
			echo "[test-linux] building Ubuntu 26.04 test container"; \
			docker build -q -t dotfiles-test -f tests/linux/Dockerfile .; \
			docker run --rm dotfiles-test; \
			docker run --rm -e CODESPACES=true dotfiles-test \
				bash /home/testuser/tests/run.sh codespaces; \
			echo "[test-linux] all container tests passed" \
			;; \
		Linux) \
			if [ "$$(id -u)" -eq 0 ]; then \
				echo "[test-linux] non-root host required"; \
				exit 1; \
			fi; \
			if ! command -v chezmoi >/dev/null 2>&1; then \
				echo "[test-linux] chezmoi not found"; \
				exit 1; \
			fi; \
			test_environment=linux; \
			if [ "$${CODESPACES:-false}" = "true" ]; then \
				test_environment=codespaces; \
			else \
				if [ ! -r /etc/os-release ]; then \
					echo "[test-linux] /etc/os-release not found"; \
					exit 1; \
				fi; \
				. /etc/os-release; \
				if [ "$${ID:-}" != "ubuntu" ] || [ "$${VERSION_ID:-}" != "26.04" ]; then \
					echo "[test-linux] Ubuntu 26.04 host required"; \
					exit 1; \
				fi; \
			fi; \
			test_root="$$(mktemp -d)"; \
			trap 'rm -rf "$$test_root"' EXIT; \
			mkdir -p "$$test_root/home/.config/chezmoi"; \
			printf '%s\n' \
				"sourceDir = \"$(CURDIR)/home\"" \
				'' \
				'[data]' \
				'    name = "TestUser"' \
				'    email = "test@example.com"' \
				'    deviceName = "test-device"' \
				> "$$test_root/home/.config/chezmoi/chezmoi.toml"; \
			HOME="$$test_root/home" \
			XDG_CONFIG_HOME="$$test_root/home/.config" \
			CHEZMOI_TEST_SOURCE_DIR="$(CURDIR)/home" \
			CHEZMOI_TEST_INSTALL_SCRIPT="$(CURDIR)/install.sh" \
				bash tests/run.sh "$$test_environment"; \
			echo "[test-linux] all local $$test_environment tests passed" \
			;; \
		*) \
			echo "[test-linux] unsupported host: $$(uname -s)"; \
			exit 1 \
			;; \
	esac

init: ## 로컬 개발·테스트 환경 설정
	@if ! command -v docker >/dev/null 2>&1; then \
		echo "[init] docker not found"; \
		exit 1; \
	fi
	@if ! docker info >/dev/null 2>&1; then \
		echo "[init] Docker daemon is not running"; \
		exit 1; \
	fi
	@if ! command -v npm >/dev/null 2>&1; then \
		echo "[init] npm not found"; \
		exit 1; \
	fi
	@echo "[init] installing npm dependencies and configuring Husky"
	@npm ci
	@echo "[init] development environment ready"
