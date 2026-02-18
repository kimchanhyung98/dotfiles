# Chezmoi Dotfiles Testing Plan

> 이 문서는 **구현 계획**이다. Makefile `check` 타겟과 GitHub Actions workflow는 아직 구현되지 않았으며, 이 문서를 기반으로 구현할 예정이다.

## 배경

- chezmoi로 관리되는 dotfiles의 정상 동작을 검증하기 위한 테스트 전략
- macOS와 Linux 환경 모두 지원 필요
- 템플릿 33개, 스크립트 17개(darwin 12, linux 5)를 대상으로 함

---

## 1. 로컬 테스트 (`make check`)

Makefile의 `check` 타겟을 구현하여, macOS/Linux 테스트를 모두 수행한다.

```
make check
├── check-macos   (읽기 전용, 로컬에서 직접 실행)
└── check-linux   (Docker Ubuntu 컨테이너)
```

### 1.1 macOS 로컬 테스트 (읽기 전용)

로컬 유저 설정에 **절대 영향을 주지 않는** 읽기 전용 명령어만 사용한다.

| 단계         | 명령어                                 | 설명                            |
|------------|-------------------------------------|-------------------------------|
| 템플릿 검증     | `chezmoi execute-template`          | 모든 `.tmpl` 파일을 순회하며 렌더링 확인    |
| Diff 확인    | `chezmoi diff`                      | 현재 상태와 source의 차이를 출력 (변경 없음) |
| Dry-run    | `chezmoi apply --dry-run --verbose` | 적용 시뮬레이션만 수행 (실제 변경 없음)       |
| 상태 검증      | `chezmoi verify`                    | 배포된 파일이 source와 일치하는지 확인      |
| 진단         | `chezmoi doctor`                    | 환경 진단                         |
| ShellCheck | `shellcheck`                        | darwin 스크립트 정적 분석             |

> 템플릿 검증은 `find home -name '*.tmpl' | while read f; do chezmoi execute-template < "$f"; done` 등의 방식으로 전체 파일을 순회해야 한다. (
`-exec`에서는 쉘 리다이렉션(`<`)을 직접 사용할 수 없으므로 파이프라인 또는 `sh -c` 래퍼를 사용한다.)

**안전성 보장:**

- `chezmoi execute-template`: stdout 출력만, 파일 시스템 변경 없음
- `chezmoi diff`: 읽기 전용 비교
- `chezmoi apply --dry-run`: `-n` 플래그로 실제 적용 차단
- `chezmoi verify`: 파일 비교만 수행, 변경 없음 (exit code로 일치/불일치 판별)
- `chezmoi doctor`: 진단만 수행
- `chezmoi apply`, `chezmoi init --apply` 등 **쓰기 명령어는 사용하지 않는다**

**주의: ShellCheck + chezmoi 템플릿**

`.chezmoiscripts/` 하위 스크립트는 `.sh.tmpl` 형식이므로, 템플릿 구문(`{{ }}`)이 ShellCheck와 충돌할 수 있다.

- **방법 A (권장)**: `chezmoi execute-template`로 렌더링 후 ShellCheck 실행 — 템플릿 구문이 완전히 제거되어 정확한 분석 가능
- 방법 B: `.shellcheckrc`로 관련 경고 예외 처리 — 간편하지만 실제 문제도 예외 처리될 수 있음

### 1.2 Linux Docker 테스트

`ubuntu:24.04` 컨테이너에서 격리된 환경으로 테스트한다.

**이미지:** `ubuntu:24.04` (가장 일반적인 서버 환경)

**컨테이너 내 실행 순서:**

| 단계                     | 설명                                                                   |
|------------------------|----------------------------------------------------------------------|
| 1. 기본 패키지 설치           | curl, git, zsh 등                                                     |
| 2. 비root 사용자 생성        | `testuser` (sudo NOPASSWD:ALL — 스크립트가 sudo를 직접 호출하므로 필수)             |
| 3. chezmoi 설치          | `get.chezmoi.io` 스크립트                                                |
| 4. 버전 확인               | `chezmoi --version` (디버깅용 기록)                                        |
| 5. 비대화형 설정 주입          | chezmoi config에 테스트용 데이터 사전 생성 (아래 참고)                               |
| 6. source directory 복사 | `home/` → chezmoi source path                                        |
| 7. 템플릿 검증              | `chezmoi execute-template` (전체 순회)                                   |
| 8. 진단                  | `chezmoi doctor --no-network`                                        |
| 9. Dry-run 적용          | `chezmoi apply --dry-run --verbose`                                  |
| 10. 실제 적용              | `chezmoi apply --force --verbose 2>&1 \| tee /tmp/chezmoi-apply.log` |
| 11. 배포 검증              | `chezmoi managed`로 전체 관리 대상 목록 확인 + `chezmoi verify`로 상태 일치 검증       |
| 12. ShellCheck         | linux 스크립트 정적 분석                                                     |

**비대화형 설정 주입:**

`.chezmoi.toml.tmpl`은 `stdinIsATTY` 체크로 대화형/비대화형을 구분한다. CI/Docker 환경에서는 TTY가 없으므로 프롬프트를 건너뛰지만, 기본값(`YOUR_NAME`,
`YOUR_EMAIL`)이 사용된다. 의미 있는 테스트를 위해 `chezmoi init` 전에 config를 사전 생성한다:

```sh
mkdir -p ~/.config/chezmoi
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
[data]
    name = "Test User"
    email = "test@example.com"
EOF
```

이렇게 하면 `promptStringOnce`가 이미 저장된 값을 사용하여, 프롬프트 없이 올바른 데이터로 초기화된다.

**로그 기록:**

`chezmoi apply` 실행 시 `--verbose` 출력을 로그 파일로 저장한다. 실패 시 로그를 통해 어떤 단계에서 문제가 발생했는지 추적할 수 있다.

```sh
chezmoi apply --force --verbose 2>&1 | tee /tmp/chezmoi-apply.log
```

CI 환경에서는 이 로그 파일을 artifact로 업로드하여 실패 원인 분석에 활용한다.

**외부 의존성 (네트워크 필요):**

`.chezmoiexternal.toml`에 정의된 외부 리소스(oh-my-zsh, zsh 플러그인 등)는 `chezmoi apply` 시 GitHub에서 다운로드된다. Docker/CI 환경에서 네트워크 접근이
필수이며, GitHub rate limiting이나 네트워크 장애 시 apply가 실패할 수 있다. `schedule` 트리거(주 1회)가 이런 외부 의존성 깨짐을 감지하는 역할을 한다.

**macOS와의 차이점:**

- Docker 컨테이너이므로 **실제 적용(`chezmoi apply`)까지 테스트 가능**
- 매 실행마다 클린 환경이 보장됨
- 스크립트 실행(`run_once_before_01`, `run_onchange_02`, `run_onchange_03`, `run_once_04`, `run_onchange_05`)도 안전하게 검증 가능

### 1.3 Makefile `check` 타겟 구조

현재 Makefile의 `check` 타겟은 placeholder 상태이며, 아래 구조로 구현한다.

```
make check
├── [macOS] 템플릿 렌더링 검증 (모든 .tmpl 순회)
├── [macOS] chezmoi diff
├── [macOS] chezmoi apply --dry-run --verbose
├── [macOS] chezmoi verify
├── [macOS] chezmoi doctor
├── [macOS] ShellCheck (darwin 스크립트, 렌더링 후 실행)
├── [Linux] Docker Ubuntu 컨테이너 빌드 & 실행
│   ├── 템플릿 검증
│   ├── chezmoi doctor
│   ├── chezmoi apply (실제 적용, 로그 기록)
│   ├── chezmoi managed + chezmoi verify (전체 파일 검증)
│   └── ShellCheck (linux 스크립트, 렌더링 후 실행)
└── 결과 요약 출력
```

> macOS에서 `make check` 실행 시 macOS + Linux(Docker) 모두 테스트.
> Linux에서 실행 시 Linux 테스트만 수행 (macOS 단계 스킵).

---

## 2. CI/CD (GitHub Actions)

현재 저장소에는 PR 제목/브랜치명 검사 workflow만 존재한다. 아래 `test-dotfiles.yml`을 새로 추가한다.

### Workflow 구조

```
test-dotfiles.yml (신규)
├── validate (ubuntu-latest)
│   ├── 모든 .tmpl 파일 렌더링 검증
│   ├── chezmoi doctor
│   └── ShellCheck 정적 분석
├── test-macos (matrix: 4개)
│   ├── macos-15       (Sequoia, ARM64)
│   ├── macos-15-intel (Sequoia, Intel)
│   ├── macos-26       (Tahoe, ARM64)
│   ├── macos-26-large (Tahoe, Intel) ← 유료 플랜 필요
│   └── 각 runner에서:
│       ├── chezmoi --version (버전 기록)
│       ├── 비대화형 설정 주입 (chezmoi config 사전 생성)
│       ├── chezmoi init --source "$GITHUB_WORKSPACE/home" (source 경로 명시)
│       ├── chezmoi apply --force --verbose (실제 적용, 로그 기록)
│       ├── chezmoi managed (전체 관리 대상 목록 확인)
│       ├── chezmoi verify (전체 파일 상태 검증)
│       └── 실패 시 로그 artifact 업로드
└── test-linux (ubuntu-latest, Docker)
    ├── chezmoi --version (버전 기록)
    ├── 비대화형 설정 주입 (chezmoi config 사전 생성)
    ├── chezmoi init --source "$GITHUB_WORKSPACE/home" (source 경로 명시)
    ├── chezmoi apply --force --verbose (실제 적용, 로그 기록)
    ├── chezmoi managed (전체 관리 대상 목록 확인)
    ├── chezmoi verify (전체 파일 상태 검증)
    └── 실패 시 로그 artifact 업로드
```

### 트리거 조건

| 이벤트               | 목적                               |
|-------------------|----------------------------------|
| `push` (main)     | 메인 브랜치 변경 시 전체 검증                |
| `pull_request`    | PR 머지 전 검증                       |
| `schedule` (주 1회) | 외부 의존성 깨짐 감지 (Oh My Zsh, 플러그인 등) |

### Job 의존성

- `validate`는 독립 실행 (빠른 피드백)
- `test-macos`와 `test-linux`는 `validate` 성공 후 실행

### macOS Runner 매트릭스 (as of 2026-02-18)

| Runner           | macOS 버전   | 아키텍처                  | 상태                 | 비용                       |
|------------------|------------|-----------------------|--------------------|--------------------------|
| `macos-15`       | Sequoia 15 | ARM64 (Apple Silicon) | GA, `macos-latest` | 무료                       |
| `macos-15-intel` | Sequoia 15 | Intel x64             | GA                 | 무료                       |
| `macos-26`       | Tahoe 26   | ARM64 (Apple Silicon) | Beta               | 무료                       |
| `macos-26-large` | Tahoe 26   | Intel x64             | Beta               | **유료** (Team/Enterprise) |

> `macos-15` + `macos-15-intel` + `macos-26` = 무료 3개, `macos-26-large` = 유료 1개.
> 유료 플랜이 없으면 무료 3개로 먼저 운영하고, `macos-26-large`는 추후 추가한다.
> `macos-15-intel`은 2027년 8월까지만 제공되며, GitHub Actions의 마지막 Intel 이미지다. (as of 2026-02-18)

---

## 3. 로컬 vs CI 테스트 범위 비교

| 테스트 항목                  | 로컬 macOS | 로컬 Linux (Docker) | CI macOS | CI Linux |
|-------------------------|:--------:|:-----------------:|:--------:|:--------:|
| 템플릿 렌더링                 |    O     |         O         |    O     |    O     |
| ShellCheck              |    O     |         O         |    O     |    O     |
| chezmoi doctor          |    O     |         O         |    O     |    O     |
| chezmoi diff            |    O     |         -         |    -     |    -     |
| chezmoi apply (dry-run) |    O     |         O         |    -     |    -     |
| chezmoi apply (실제 적용)   |  **X**   |         O         |    O     |    O     |
| chezmoi verify          |    O     |         O         |    O     |    O     |
| 스크립트 실행                 |  **X**   |         O         |    O     |    O     |
| 전체 파일 배포 검증             |  **X**   |         O         |    O     |    O     |
| 클린 환경 보장                |  **X**   |         O         |    O     |    O     |

---

## 4. 향후 고려사항

### Bats (Bash Automated Testing System)

- 쉘 스크립트의 동작을 단위 테스트할 수 있는 프레임워크
- `dotfiles-doctor`의 각 검증 항목을 Bats 테스트로 전환 가능
- 참고: [shunk031/dotfiles](https://github.com/shunk031/dotfiles) - Bats + kcov(coverage)를 활용한 사례

### 추가 Linux 배포판

현재는 `ubuntu:24.04`만 테스트하지만, 필요 시 확장 가능:

| 이미지               | 패키지 매니저 | 비고                   |
|-------------------|---------|----------------------|
| `debian:bookworm` | apt-get | 안정성 테스트              |
| `alpine:latest`   | apk     | 최소 환경 (musl libc 주의) |
| `fedora:latest`   | dnf     | RPM 기반 테스트           |

---

## 참고 자료

- [chezmoi: verify command](https://www.chezmoi.io/reference/commands/verify/)
- [chezmoi: Containers and VMs](https://www.chezmoi.io/user-guide/machines/containers-and-vms/)
- [chezmoi: docker command](https://www.chezmoi.io/reference/commands/docker/)
- [chezmoi: Testing (Developer Guide)](https://www.chezmoi.io/developer-guide/testing/)
- [GitHub Actions runners reference](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [macOS 15 Intel runner (macos-15-intel)](https://github.com/actions/runner-images/issues/13045)
- [macOS 26 Intel runner (macos-26-large)](https://github.com/actions/runner-images/issues/13637)
- [shunk031/dotfiles](https://github.com/shunk031/dotfiles) - Bats + Docker + GitHub Actions 사례
- [felipecrs/dotfiles](https://github.com/felipecrs/dotfiles) - Docker + chezmoi one-shot 사례
