# 테스트

테스트는 빠른 공통 검사와 플랫폼별 통합 검사로 나눈다. 실행 환경과 Docker
준비는 `Makefile`이 담당하고, `tests/run.sh`는 지정된 환경의 테스트 파일만
실행한다.

## 명령과 실행 경로

| 명령 | 역할 |
|---|---|
| `make check` | macOS·Linux 공통의 빠른 정적·격리 검사 |
| `make test` | 현재 host에서 실행할 수 있는 전체 플랫폼 검사 |
| `make test-macos` | macOS 로컬 통합 검사 |
| `make test-linux` | Linux에서는 로컬, macOS에서는 Ubuntu 26.04 Docker 통합 검사 |

`make test`의 실행 순서는 현재 환경에 따라 달라진다.

| 현재 환경 | 실행 순서 |
|---|---|
| macOS | 공통 검사 → macOS 로컬 → Linux·Codespaces Docker |
| Ubuntu 26.04 non-root | 공통 검사 → macOS 생략 → Linux 로컬 |
| GitHub Codespaces | 공통 검사 → macOS 생략 → Codespaces 로컬 |

`make test-macos`는 macOS가 아니면 실패한다. `make test-linux`는 macOS에서만
Docker CLI와 daemon을 확인한다. 일반 Linux에서는 non-root Ubuntu 26.04와
chezmoi를 확인하고, Codespaces에서는 `CODESPACES=true`를 기준으로 별도 suite를
선택한다. 그 밖의 OS와 Linux 배포판은 지원하지 않는다.

## 빠른 공통 검사

```sh
make check
```

`make check`는 `tests/run.sh local`을 실행한다. Docker, network, 실제 credential을
사용하지 않으며 pre-commit hook도 같은 명령을 사용한다.

검사 범위:

- working tree와 staged diff의 whitespace 오류
- 일반 Bash·Zsh script와 JSON 문법
- ShellCheck가 설치된 경우 severity error 검사
- branch name validator의 허용·거부 동작
- 반복 가능한 dotfiles update와 dirty source 차단
- GitHub project bootstrap과 Doppler `.env` fixture
- skills migration과 pinned mattpocock skills 동기화

외부 API와 repository는 임시 fixture와 가짜 command로 대체하며 실제 사용자
HOME은 변경하지 않는다. `make init`은 npm dependency와 Husky를 준비하는 개발
환경 명령으로, 테스트 항목이 아니다.

## 테스트 구조

테스트 케이스는 다음 경로에 둔다.

```text
tests/{environment}/{function}/{name}.sh
```

지원 환경은 `local`, `macos`, `linux`, `codespaces`다. `tests/run.sh`는 선택한
환경의 파일을 경로순으로 각각 새 Bash process에서 실행한다. 모든 결과를 집계한
뒤 하나라도 실패하면 non-zero로 종료한다. 실패한 테스트는 경로, 행, 종료 상태와
실패한 명령을 함께 출력한다.

`tests/lib/`는 공통 helper, `tests/fixtures/`는 fixture를 제공하며 직접 실행되는
테스트 케이스가 아니다. 새 테스트는 내부 함수 호출 여부보다 command의 exit
status, 생성된 파일, 렌더링 결과처럼 사용자가 관찰할 수 있는 동작을 확인한다.
간단한 구조 규칙은 [`tests/README.md`](../tests/README.md)에 정리한다.

## macOS 통합 검사

```sh
make test-macos
```

macOS suite는 임시 HOME에서 다음을 확인한다.

- 최초 chezmoi config의 대화형 필수 입력과 headless 실행 거부
- `install.sh`의 controlling terminal 계약과 chezmoi 호출 인자
- managed template 렌더링과 apply dry-run
- Claude·Codex repository 설정과 managed template의 일치
- cmux, Rectangle, Stats와 Brewfile 관련 설정
- tokscale 3일마다 및 dotfiles 매월 1·16일 오후 2시 launchd 계약
- state/cache gate가 없는 예약 작업과 tokscale submit wrapper
- project bootstrap과 Doppler 실패가 dotfiles 실패로 전이되지 않는 계약
- 공통 skills·instruction symlink topology
- Zsh 설정과 렌더된 공통·macOS script의 Bash 문법·ShellCheck

설정 렌더와 command 동작은 fixture에서 검사하므로 실제 사용자 HOME이나 macOS
설정은 변경하지 않는다. Codex 검사는 버전이 아니라 렌더된 설정의 일치와 CLI의
strict config 로딩 성공 여부를 확인한다.

## Ubuntu 통합 검사

```sh
make test-linux
```

Linux host에서는 현재 checkout의 `home/`을 source로 사용하고 임시 HOME에 actual
apply와 verify를 수행한다. macOS에서는 `tests/linux/Dockerfile`로 Ubuntu 26.04
non-root image를 만들고 같은 검사를 container에서 실행한다.

검사 범위:

- Ubuntu 26.04와 non-root 실행 조건
- actual `chezmoi apply` 후 `chezmoi verify`
- macOS 전용 target 제외
- login shell, timezone과 기본 editor 설정
- Zsh 설정과 공통 skills topology
- 렌더된 공통·Linux script의 Bash 문법·ShellCheck

apply 단계의 외부 API와 AI CLI는 fixture command로 대체하므로, 이 suite는 외부
installer나 서비스 가용성을 검증하지 않는다.

Linux 로컬 경로는 HOME만 임시로 격리한다. 패키지, login shell, locale,
timezone 같은 system baseline은 실제 OS에 적용될 수 있으므로 준비된 Ubuntu
26.04 테스트 환경이나 CI에서 실행한다.

## Codespaces 통합 검사

macOS의 `make test-linux`는 같은 Ubuntu image의 새 container에
`CODESPACES=true`를 주입해 Codespaces suite도 실행한다. 실제 Codespaces에서는
Linux 로컬 경로로 실행한다.

검사 범위:

- GitHub 환경 변수 기반 non-interactive config 생성
- 필수 identity 값 누락 거부
- `install.sh`의 `--no-tty` chezmoi 호출
- actual apply와 verify
- login shell과 timezone 변경 제외
- SSH bootstrap, project clone과 Doppler 설정 제외
- macOS desktop target 제외
- 공통 skills·instruction symlink topology와 Zsh 설정

## Docker 격리

Docker build context는 `install.sh`, `home/`, `tests/` allowlist만 사용한다. Git
metadata, `.env` 계열 파일, credential과 private key 패턴은 image에 포함하지
않으며 테스트 image는 non-root `testuser`로 실행한다.

Linux와 Codespaces는 같은 image를 쓰지만 각각 새 container에서 실행하므로 한
suite의 HOME과 시스템 변경이 다른 suite에 남지 않는다. 로컬에는
`dotfiles-test` image와 build cache가 남아 다음 실행에서 재사용된다.

## GitHub Actions

`.github/workflows/test-dotfiles.yml`은 pull request와 `main` branch push에서
실행된다.

| job | 실행 범위 |
|---|---|
| macOS | `make check`, `make test-macos` |
| Ubuntu 26.04 | `make test`로 공통 검사와 Linux 로컬 통합 검사 |
| Ubuntu 26.04 container 단계 | Docker에서 Linux와 Codespaces suite |

두 job을 합쳐 공통 검사, macOS, Ubuntu 26.04 로컬·Docker, Codespaces 경로를
검증한다. 브랜치명과 PR 제목 workflow는 별도로 유지한다.

## 필요한 도구

공통 검사는 Bash, Git, Node.js, jq, Zsh를 사용하며 ShellCheck가 있으면 추가
검사를 수행한다. macOS 통합 검사는 chezmoi, jq, Zsh, ShellCheck, Codex CLI와
macOS 기본 도구인 `expect`, `perl`, `plutil`을 사용한다. macOS에서 Linux 통합
검사를 실행할 때는 실행 중인 Docker daemon이 필요하다. Linux 로컬 통합 검사는
non-root Ubuntu 26.04, chezmoi와 ShellCheck를 전제로 하며, 패키지나 system
baseline 적용이 필요하면 `sudo`를 사용한다.
