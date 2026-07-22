# 설치

> **실행 조건 표기**: `최초 1회`는 chezmoi `run_once_` 스크립트로, 최초 적용 시 1회 실행되며 스크립트 내용(템플릿 렌더 결과)이 바뀌면 다음 `chezmoi apply`에서 다시
> 실행된다(각 설치 블록은 `command -v` 가드로 멱등성을 보장). `설정 변경 시`는 `run_onchange_`로, 내용이 변경될 때만 재실행된다.

## 최초 설치 입력 계약

native macOS/Ubuntu에서는 `chezmoi init --apply kimchanhyung98` 또는 repository의 `install.sh`를 대화형 터미널에서 실행한다. bootstrap script를 `curl | bash`로 실행해도 `install.sh`가 `/dev/tty`를 chezmoi 입력으로 연결한다. GitHub Codespaces의 자동 dotfiles 설치는 예외로, `install.sh`가 `--no-tty`를 사용한다.

최초 config에는 다음 세 값을 모두 직접 입력해야 한다.

- 이름(`name`, GitHub username 및 Git 작성자명)
- 이메일(`email`)
- 기기명(`deviceName`)

native 경로에는 기본값과 placeholder가 없다. 제어 터미널이 없거나 공백을 포함해 값이 비어 있으면 config 생성과 apply 전에 실패한다. Codespaces 최초 설치는 `GITHUB_USER`, `GIT_COMMITTER_EMAIL`, `CODESPACE_NAME`에서 세 값을 가져오며 누락 시 명시적으로 실패한다. 이미 세 값이 저장된 config는 이후 `--init`에서 재사용한다.

native 첫 chezmoi 적용 시 apply가 끝난 뒤 `name`의 GitHub 개인 계정에서 공개·비보관 저장소를 최대 100개 조회하여 `~/Documents/GitHub`에 clone한다. clone 성공 후 Doppler 로그인이 없으면 대화형 `doppler login`을 한 번 실행한다. 각 Git 저장소에 대해 저장소명과 같은 Doppler project의 `local` config를 조회하고, 값이 있으며 기존 `.env`가 없을 때만 mode 0600의 `.env`를 생성한다. 일치하는 project/config가 없는 저장소와 기존 `.env`는 건너뛴다. Codespaces에서는 이 로컬 프로젝트 bootstrap 전체를 건너뛴다. `run_once_after_` 접두사로 같은 렌더 결과를 다시 실행하지 않으며, 예약 dotfiles 동기화에는 별도 호출 로직이 없다.

script phase는 파일명의 `before_`/`after_`가 우선한다. 번호는 같은 source 디렉터리 안의 읽기 순서를 설명할 뿐이며, 공통 루트와 OS 하위 디렉터리 사이의 전역 순서를 보장하지 않는다.

## OS 공통 스크립트

| 스크립트                | 역할                          | 실행 조건       | 상세                                                                                                                                                                                                                                                                                                                 |
|---------------------|-----------------------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| skills-ssot-migrate | 기존 스킬 디렉토리 제거 | 최초 1회, 배포 전 | `run_once_before_`로 dotfiles 배포 전에 실행. Claude Code와 Codex의 skills 경로가 symlink 전환 이전의 실제 디렉토리면 백업 없이 삭제한다. 배포 단계에서 각 지원 경로가 `~/.skills`를 가리키는 symlink로 교체되며, migration 스크립트는 `~/.skills` 본체를 건드리지 않는다. 모든 경로가 이미 symlink면 아무 일도 하지 않음(멱등) |
| mattpocock-skills | 외부 스킬 동기화 | 최초 적용 및 스크립트 변경 시, 배포 후 | `run_onchange_after_`로 dotfiles 배포 후 실행. helper가 pinned `v1.0.1`에서 선택한 15개 스킬만 `~/.skills`로 동기화한다. 수동 재실행 시 선택 목록의 동명 디렉토리는 같은 snapshot으로 교체하고, 선택 목록 밖 사용자 스킬은 건드리지 않는다. |
| projects-bootstrap | 공개 GitHub clone·Doppler `.env` 준비 | native 최초 적용, 배포 후 | `run_once_after_` 템플릿이 clone helper 후 Doppler helper를 순차 호출한다. optional best-effort 단계이므로 helper 누락·실패는 warning과 수동 재시도 명령만 남기고 dotfiles apply를 실패시키지 않는다. Codespaces에서는 전체를 건너뛴다. |

## macOS 스크립트 (darwin/)

| 순서 | 스크립트 | phase | 역할 | 실행 조건 | 상세 |
|:--:|---|---|---|---|---|
| 01 | prerequisites | before | Xcode CLI, Homebrew, zerobrew, Rosetta, GitHub SSH host keys | 최초 1회 | Xcode Command Line Tools와 Homebrew를 준비하고 zerobrew installer를 실행한다. Apple Silicon이면 Rosetta 2를 설치하고 GitHub SSH host key를 검증해 등록한다. |
| 02 | macos-settings | after | Dock, Finder, Keyboard, Trackpad, Screenshot | 설정 변경 시 | managed target 배포 뒤 `defaults` 명령으로 macOS 설정을 적용한다. |
| 03 | brew-packages | regular | Brewfile 기반 패키지 설치·upgrade | Brewfile 변경 시 | `zb bundle install --auto-init`을 먼저 실행한다. Brewfile 전체 check가 실패하거나 zerobrew가 실패하면 `brew bundle`로 폴백하며, 최종 check 실패는 non-zero다. 자동 cleanup은 하지 않는다. |
| 05 | app-settings | after | Rectangle, Stats 설정 import | 설정 변경 시 | Rectangle import 파일을 앱 지원 경로에 복사하고, Stats plist는 remote credential을 보존한 뒤 import한다. |
| 05 | runtime | regular | Bun | 최초 1회 | Node.js는 Brewfile에서 관리하고 Bun은 공식 installer로 별도 설치한다. |
| 07 | tokscale-launchd | after | tokscale LaunchAgent 등록·갱신 | 설정 변경 시 | 3일마다 로컬 14:00에 실행한다. |
| 08 | dotfiles-update-launchd | after | dotfiles update LaunchAgent 등록·갱신 | 설정 변경 시 | 매월 1일과 16일 로컬 14:00에 실행한다. |

> cmux 외부 자동화 제어는 별도 스크립트 없이 `~/.config/cmux/cmux.json`(`automation.socketControlMode=allowAll`)을 선언적으로 배포하여 기본 활성화한다. cmux 0.64+는 이 파일을 정식 설정 경로로 읽으며, 과거 `defaults write com.cmuxterm.app socketControlMode` 방식은 폐기되었다.

### AI 스크립트 (darwin/)

| 순서 | 스크립트 | phase | 역할 | 실행 조건 | 상세 |
|:--:|---|---|---|---|---|
| 10 | ai-core | regular | 필수 Claude Code/Codex CLI, 선택 Antigravity/Hermes/CodeGraph | 최초 1회 | Claude와 Codex는 공식 standalone installer를 사용하며 실패 시 non-zero다. npm이 있으면 CodeGraph를 설치하고 나머지 선택 도구 실패는 warning이다. |
| 11 | ai-claude | regular | CodeGraph MCP | 최초 1회 | Claude CLI 명령으로 사용자 범위 CodeGraph MCP를 `~/.claude.json`에 등록한다. 이 runtime 파일은 chezmoi가 직접 소유하지 않는다. |
| 12 | ai-codex | regular | oh-my-codex, 사용자 프로필 초기화 | 최초 1회 | oh-my-codex를 설치하고 `omx setup --scope user`로 초기화한다. 스킬은 symlink로 공유하며 CodeGraph MCP는 `config.toml`에서 관리한다. |

| 순서 | 스크립트 | phase | 역할 | 실행 조건 |
|:--:|---|---|---|---|
| 99 | manual-install | after | 수동 설치 안내 출력 | 최초 1회 |

**AI 스크립트 설계 원칙**:

- 코어 설치(10)와 프로바이더별 확장 설치(11~12)를 분리하여 책임 경계를 명확히 유지
- Claude/Codex는 required라서 설치·command 확인 실패 시 apply가 실패한다. 확장과 나머지 AI 도구는 optional warning으로 분리한다.
- 스킬은 단일 출처 `~/.skills`에 두고 Claude Code와 Codex의 글로벌 skills 경로를 symlink로 연결하여 공유 (상세는 05-ai-tools.md 참고)

### Linux 스크립트 (linux/)

| 순서 | 스크립트 | phase | 역할 | 실행 조건 | 상세 |
|:--:|---|---|---|---|---|
| 01 | install-packages | before | Ubuntu CLI baseline | 최초 1회 | native는 Ubuntu 26.04 LTS만 허용하고 apt로 패키지를 설치한다. Codespaces는 `CODESPACES=true`로 감지한다. |
| 02 | shell-baseline | regular | 기본 셸, 로케일, 타임존 | 설정 변경 시 | native Ubuntu만 zsh 기본 셸, en_US.UTF-8, Asia/Seoul 설정을 시도한다. Codespaces에서는 건너뛴다. |
| 03 | git-baseline | regular | Git 사용자 설정, SSH 기초 | 설정 변경 시 | native Ubuntu는 GitHub known_hosts를 준비한다. Codespaces는 GitHub가 제공하는 repository 인증을 사용한다. |
| 04 | ai-tools | regular | 필수 claude/codex, 선택 copilot/codegraph/antigravity/hermes/oh-my-codex | 최초 1회 | Claude/Codex는 standalone installer를 사용한다. npm이 없으면 npm 기반 선택 확장만 건너뛴다. Copilot은 공식 installer를 사용한다. |
| 05 | system-baseline | regular | 시스템 기초 설정 | 설정 변경 시 | `~/.profile`에 기본 editor와 `~/.local/bin` PATH를 중복 없이 추가한다. |

## 설치 phase

### macOS

```text
1. before scripts
   - skills-ssot-migrate
   - macOS prerequisites

2. managed targets + regular scripts(application order)
   - dotfiles와 external archive 배포
   - brew-packages, runtime, ai-core, ai-claude, ai-codex

3. after scripts
   - mattpocock-skills
   - projects-bootstrap
   - macos-settings, app-settings
   - tokscale-launchd, dotfiles-update-launchd, manual-install
```

`app-settings`와 두 LaunchAgent 등록 스크립트는 앞 phase에서 배포된 target을 사용한다. 예약 작업은 성공 시각이나 cache를 기록하지 않으며 calendar가 다음 실행 시각을 결정한다. external의 `168h`는 예약 주기가 아니라 chezmoi command가 상태를 읽을 때 refresh 여부를 판단하는 cache 최소 age다.

### Linux

native Linux의 지원 범위는 Ubuntu 26.04 LTS다. GitHub Codespaces는 underlying Ubuntu version과 무관하게 `CODESPACES=true`인 경우 CLI·설정·AI 경로만 지원하고, 시스템 timezone·로그인 셸·SSH bootstrap·데스크톱 앱은 변경하지 않는다.

```text
1. before scripts
   - skills-ssot-migrate
   - install-packages

2. managed targets + regular scripts(application order)
   - 공통/Linux dotfiles와 external archive 배포
   - shell-baseline, git-baseline, ai-tools, system-baseline

3. after scripts
   - mattpocock-skills
   - projects-bootstrap (native만, Codespaces는 건너뜀)
```

## Brewfile 패키지

Brewfile은 `zb bundle install --auto-init -f Brewfile`로 먼저 처리한다. zerobrew가 실패하거나 이후 `brew bundle check --no-upgrade`가 설치되지 않은 의존성을 발견하면 `brew bundle --file=Brewfile`로 폴백한다. 이때 이미 설치된 `xcodes`만 `HOMEBREW_BUNDLE_BREW_SKIP`으로 제외해 bottle 없는 release로의 upgrade 실패를 피하고, 나머지 package는 평소처럼 설치·upgrade한다. 사후 검증은 보류 중인 upgrade가 아니라 설치 여부만 확인한다. Brewfile에서 빠진 package 제거는 별도 cleanup 명령 없이는 수행하지 않는다.
Homebrew 폴백은 `brew trust --formula dopplerhq/cli/doppler`로 Doppler formula를 신뢰한 뒤 bundle을 실행한다. Doppler는 최초 프로젝트 `.env` 동기화에 필요하므로 설치 검사에서 제외하지 않는다.
AI 도구는 설치 채널 정책에 따라 AI 스크립트에서 관리한다. 단, macOS Copilot CLI는 공식 Homebrew cask를 사용한다. Claude/Codex만 필수 baseline이며 나머지는 선택 도구다.

| 대주제    | 소주제         | 상세 패키지                                                                                                              |
|--------|-------------|---------------------------------------------------------------------------------------------------------------------|
| 시스템    | 기본 CLI      | bash, bat, zsh, curl, wget, git, git-lfs, gh, grep, jq, gnupg, pkgconf(pkg-config), shellcheck, terminal-notifier, tree, vim |
| 시스템    | 개발 보조 CLI   | act, awscli, direnv, doppler, fswatch, fzf, ripgrep, tmux, watchman, zoxide                                         |
| 런타임    | 언어 런타임      | dotnet, go, kotlin, node, openjdk, php, python, ruby, rust                                                          |
| 런타임    | 패키지/가상환경    | composer, mise, npm, pipx, uv, xcodes, yarn                                                                         |
| 데이터/도구 | 데이터/유틸      | sqlite                                                                                                              |
| 터미널/앱  | 폰트          | font-d2coding                                                                                                       |
| 터미널/앱  | 터미널         | cmux, ghostty                                                                                                       |
| 터미널/앱  | 개발 앱 (cask) | copilot-cli, docker-desktop, figma, flutter, gcloud-cli, github, iterm2, postman, proxyman, visual-studio-code      |
| 터미널/앱  | 일반 앱 (cask) | appcleaner, google-chrome, iina, keka, rectangle, slack, stats                                                      |

**AI CLI 설치 채널 (공식 문서 확인 기준)**

| 도구          | 분류 | 공식 설치 채널                                                                        | 기본 운영 채널 |
|-------------|----|---------------------------------------------------------------------------------|----------|
| Claude      | 공식 | 공식 standalone installer (`https://claude.ai/install.sh`)                      | 임시 파일 다운로드 후 실행 |
| Codex       | 공식 | 공식 standalone installer (`https://chatgpt.com/codex/install.sh`)               | 임시 파일 다운로드 후 실행 |
| Copilot     | 공식 | Homebrew cask(macOS), 공식 installer(Linux)                                     | OS별 공식 채널 |
| CodeGraph   | 외부 | shell installer 또는 npm (`npm install -g @colbymchenry/codegraph`)               | npm      |
| Antigravity | 공식 | 공식 스크립트 (`curl -fsSL https://antigravity.google/cli/install.sh \| bash`)        | curl     |
| Hermes      | 공식 | 공식 스크립트 (`curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash`) | curl     |

## 외부 리소스

`.chezmoiexternal.toml`로 선언적 관리한다. chezmoi command가 해당 상태를 읽을 때 cache age가 갱신 주기를 넘으면 다시 다운로드할 수 있다. `refreshPeriod` 자체가 주기적으로 실행되는 scheduler는 아니다. Git 아카이브 형태로 가져오므로 `.git` 디렉토리 없이 파일만 배포된다.

| 리소스                     | 대상 경로                     | 역할                                      | 갱신 주기     | 가져오기 방식 |
|-------------------------|---------------------------|-----------------------------------------|-----------|---------|
| Oh My Zsh               | `~/.oh-my-zsh`            | Zsh 프레임워크. 테마, 플러그인 관리 기반               | 168h (1주) | archive |
| zsh-autosuggestions     | Oh My Zsh custom/plugins/ | 히스토리 기반 입력 자동완성. 타이핑 중 이전 명령을 흐린 글씨로 제안 | 168h      | archive |
| zsh-syntax-highlighting | Oh My Zsh custom/plugins/ | 명령어 구문 강조. 유효한 명령은 녹색, 잘못된 명령은 빨간색으로 표시 | 168h      | archive |
