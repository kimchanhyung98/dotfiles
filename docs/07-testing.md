# Chezmoi Dotfiles Testing

이 문서는 현재 구현된 테스트 경로를 설명한다. 전체 dotfiles 적용 CI(`test-dotfiles.yml`)는 현재 저장소에 없으며, GitHub Actions는 브랜치명과 PR 제목 검증만 수행한다.

## 대상 범위

- 템플릿 29개
  - 배포 템플릿 12개: `home/.chezmoi.toml.tmpl`, zsh/git/AI/cmux/ghostty/tokscale/LaunchAgent 등
  - 실행 스크립트 17개: 공통 2개, darwin 10개, linux 5개
- 테스트 스크립트
  - `tests/macos.sh`
  - `tests/linux.sh`
  - `tests/zsh-config.sh`
  - `tests/skills-migrate.sh`
  - `tests/mattpocock-skills-sync.sh`

## 로컬 테스트

`make check`가 현재 유일한 전체 검증 진입점이다.

```text
make check
├── [macOS host] tests/macos.sh
└── tests/Dockerfile build → tests/linux.sh
```

macOS가 아닌 호스트에서는 `tests/macos.sh`를 건너뛰고 Docker 기반 Linux 테스트만 실행한다. Docker CLI가 없거나 Docker daemon이 실행 중이 아니면 `make check`는 실패한다.

Docker 설정 경로 권한 문제가 있는 환경에서는 다음처럼 임시 Docker config를 지정한다.

```sh
DOCKER_CONFIG=/private/tmp/dotfiles-docker-config make check
```

## macOS 테스트

`tests/macos.sh`는 임시 HOME을 만들고 `chezmoi init --source "$REPO_DIR/home"`으로 격리된 source를 사용한다. 실제 사용자 HOME에는 적용하지 않는다.

엄격 실패 항목:

| 영역 | 검증 내용 |
|---|---|
| 템플릿 | `chezmoi cat`으로 관리 파일 템플릿 렌더링 |
| Codex | `home/dot_codex/config.toml.tmpl` 권한 deny/write 규칙과 cloudflare plugin 비활성 상태 |
| cmux | `cmux.json` JSON 구조와 automation 기본값 |
| App settings | Rectangle JSON, Stats plist, app-settings 스크립트 |
| Skills | legacy skills cleanup, `.claude/skills`/`.agents/skills` symlink topology |
| mattpocock skills | 선택된 upstream skill 동기화와 stale runtime state 제거 |
| Brew | `pkgconf`, `docker-desktop`, zerobrew 우선 및 Homebrew 폴백 |
| tokscale | submit wrapper, LaunchAgent plist, launchd bootstrap 스크립트 target path |
| Zsh | LANG 폴백과 fzf 바인딩 순서 회귀 검증 |
| ShellCheck | shellcheck가 설치된 경우 공통+darwin 렌더링 스크립트 lint |

관찰 항목:

- `chezmoi diff`
- `chezmoi apply --dry-run --verbose`
- `chezmoi verify`
- `chezmoi doctor`

임시 HOME에서는 아직 실제 적용 전 차이가 있을 수 있으므로, 위 항목은 일부 non-zero 결과를 warning으로 보고 테스트 실패로 보지 않는다.

## Linux Docker 테스트

`tests/Dockerfile`은 `ubuntu:24.04` 기반으로 비root `testuser`를 만들고, `home/`을 chezmoi source directory로 복사한 뒤 `tests/linux.sh`를 실행한다.

컨테이너 사전 설치 항목:

- curl, git, vim, zsh, sudo, ca-certificates, locales
- shellcheck, zoxide, bat
- nodejs, npm
- chezmoi

`tests/linux.sh`의 주요 검증:

| 단계 | 검증 내용 |
|---|---|
| chezmoi version | 실행 가능 여부와 버전 출력 |
| 템플릿 | `chezmoi cat`으로 관리 파일 렌더링 |
| OS ignore | macOS-only 파일(Rectangle, Stats, cmux, tokscale, LaunchAgent 등)이 Linux에서 관리되지 않는지 확인 |
| Skills | cleanup, symlink topology, mattpocock sync |
| Zsh | `tests/zsh-config.sh` |
| Doctor | `chezmoi doctor --no-network` error 여부 |
| Apply | dry-run 후 `chezmoi apply --force --verbose` 실제 적용 |
| Verify | `chezmoi managed` 목록과 `chezmoi verify` |
| ShellCheck | 공통+linux 렌더링 스크립트 lint |

## Git Hooks와 GitHub Checks

| 위치 | 시점 | 동작 |
|---|---|---|
| `.husky/pre-commit` | `git commit` 전 | `make check` 실행 |
| `.husky/commit-msg` | `git commit` 전 | `.husky/validate-commit.cjs`로 conventional commit 형식 검증 |
| `.husky/pre-push` | `git push` 전 | `.husky/validate-branch.cjs`로 브랜치명 검증 |
| `.github/workflows/branch-name-check.yml` | PR 생성/수정 | PR head branch 형식 검증 |
| `.github/workflows/pr-title-check.yml` | PR 생성/수정/label 변경 | `amannn/action-semantic-pull-request@v6`로 PR 제목 검증 |

현재 GitHub Actions에는 macOS/Linux dotfiles 적용 테스트 workflow가 없다. PR에서 전체 적용 검증이 필요하면 로컬 `make check` 결과를 기준으로 판단한다.

## 로컬 vs 자동 검증

| 테스트 항목 | 로컬 `make check` | Husky | GitHub Actions |
|---|:---:|:---:|:---:|
| macOS 템플릿/설정 회귀 | O(macOS host) | pre-commit | - |
| Linux Docker 적용 검증 | O | pre-commit | - |
| ShellCheck | O | pre-commit | - |
| 커밋 메시지 | - | commit-msg | - |
| 브랜치명 | - | pre-push | O(PR) |
| PR 제목 | - | - | O(PR) |

## 향후 고려사항

- GitHub Actions에 전체 dotfiles 적용 workflow를 추가할 경우, 이 문서의 CI 섹션을 새 workflow 파일명과 job 구조에 맞춰 갱신한다.
- macOS runner 검증을 추가할 경우 비용과 runner 제공 기간을 별도 확인한다.
- `dotfiles-doctor` 항목이 늘어나면 별도 테스트로 전환해 문서와 진단 스크립트의 drift를 줄인다.
