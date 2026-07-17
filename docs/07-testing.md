# 테스트

## 로컬 검사

`make check`와 pre-commit은 Docker나 network를 요구하지 않는 빠른 검사만 실행한다.

```sh
make check
```

검사 범위:

- staged/working tree whitespace 오류
- 일반 shell script 문법과 ShellCheck(설치된 경우)
- `make init`의 Docker 확인과 npm ci/Husky 설정
- 프로젝트 clone, 저장소명/`local` Doppler sync fixture
- stateless dotfiles update의 반복 실행과 dirty source 차단 fixture

`make test`는 빠른 검사 후 Docker CLI와 daemon을 확인한다. macOS host에서는 macOS 격리 테스트를 먼저 실행하고, 이후 Linux Docker와 Codespaces 테스트를 실행한다. Linux host에서는 Linux Docker와 Codespaces 테스트를 실행한다.

```sh
make test
make test-macos
make test-linux
```

OS와 Docker 같은 실행 환경 검사는 Make target이 담당한다. 테스트 스크립트는 준비된 환경에서 dotfiles 동작만 검증한다. `make test-linux`는 실행할 때마다 Docker CLI와 daemon 상태를 확인한다.

## macOS

`make test-macos`는 macOS host인지 확인한 뒤 `tests/macos.sh`를 실행한다. 스크립트는 임시 HOME에서 다음을 확인한다.

- 최초 config와 bootstrap의 대화형 입력 계약
- managed template render
- Codex, cmux, Rectangle, Stats, Brewfile 설정
- skills migration과 pinned mattpocock sync
- tokscale 3일마다, dotfiles 매월 1·16일 오후 2시 calendar와 state/cache 부재
- Zsh 회귀와 rendered script ShellCheck

실제 사용자 HOME은 변경하지 않는다.

## Ubuntu와 Codespaces

`make test-linux`가 Docker와 daemon을 확인하고 `tests/Dockerfile`로 두 container 경로를 실행한다. container의 기본 command인 `tests/linux.sh`는 준비된 Ubuntu 환경에서 dotfiles actual apply와 검증만 수행한다.

Docker image는 공식 `ubuntu:26.04`에서 non-root actual apply와 verify를 수행한다. Node/npm을 미리 제공하지 않으므로 npm 기반 선택 도구는 건너뛸 수 있고, 필수 Claude/Codex는 standalone installer 경로를 사용한다.

같은 image에서 `CODESPACES=true`를 별도로 주입해 다음 제한 경로도 확인한다.

- apt 기반 CLI package baseline
- system timezone·locale·login shell 변경 제외
- GitHub-managed repository 인증 유지
- desktop app 설치 제외

## GitHub Actions

`test-dotfiles.yml`은 다음 경우에만 전체 검사를 실행한다.

- pull request
- main branch push

각 job은 `make check` 후 플랫폼별 target을 실행한다. macOS job은 `make test-macos`, Ubuntu job은 `make test-linux`를 사용하며, 두 job의 합이 전체 플랫폼 범위를 구성한다. 로컬 Mac의 `make test`는 두 경로를 연속으로 실행한다. 브랜치명과 PR 제목 workflow는 별도로 유지한다.
