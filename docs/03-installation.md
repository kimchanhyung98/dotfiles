# 설치

> **실행 조건 표기**: `최초 1회`는 chezmoi `run_once_` 스크립트로, 최초 적용 시 1회 실행되며 스크립트 내용(템플릿 렌더 결과)이 바뀌면 다음 `chezmoi apply`에서 다시
> 실행된다(각 설치 블록은 `command -v` 가드로 멱등성을 보장). `설정 변경 시`는 `run_onchange_`로, 내용이 변경될 때만 재실행된다.

## 최초 설치 입력 계약

`chezmoi init --apply kimchanhyung98` 또는 repository의 `install.sh`를 대화형 터미널에서 실행한다. bootstrap script를 `curl | bash`로 실행해도 `install.sh`가 `/dev/tty`를 chezmoi 입력으로 연결한다.

최초 config에는 다음 세 값을 모두 직접 입력해야 한다.

- 이름(`name`)
- 이메일(`email`)
- 기기명(`deviceName`)

기본값과 placeholder는 없다. 제어 터미널이 없거나 공백을 포함해 값이 비어 있으면 config 생성과 apply 전에 실패한다. 이미 세 값이 저장된 config는 이후 `--init`에서 재사용한다.

script phase는 파일명의 `before_`/`after_`가 우선한다. 번호는 같은 phase 안의 읽기 순서를 나타낼 뿐, `after_02`가 일반 `run_once_10`보다 먼저 실행된다는 뜻은 아니다.

## OS 공통 스크립트

| 스크립트                | 역할                          | 실행 조건       | 상세                                                                                                                                                                                                                                                                                                                 |
|---------------------|-----------------------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| skills-ssot-migrate | 기존 스킬 디렉토리 제거 | 최초 1회, 배포 전 | `run_once_before_`로 dotfiles 배포 전에 실행. Claude Code와 Codex의 skills 경로가 symlink 전환 이전의 실제 디렉토리면 삭제하여, dotfiles 배포 단계에서 `~/.skills` symlink로 교체될 수 있게 한다. 모든 경로가 이미 symlink면 아무 일도 하지 않음(멱등) |
| mattpocock-skills | 외부 스킬 동기화 | 최초 적용 및 스크립트 변경 시, 배포 후 | `run_onchange_after_`로 dotfiles 배포 후 실행. helper가 pinned `v1.0.1`에서 선택한 15개 스킬만 `~/.skills`로 동기화한다. 수동 재실행 시 선택 목록의 동명 디렉토리는 같은 snapshot으로 교체하고, 선택 목록 밖 사용자 스킬은 건드리지 않는다. |

## macOS 스크립트 (darwin/)

| 순서 | 스크립트 | phase | 역할 | 실행 조건 | 상세 |
|:--:|---|---|---|---|---|
| 01 | prerequisites | before | Xcode CLI, Homebrew, zerobrew | 최초 1회 | Xcode Command Line Tools와 Homebrew를 준비하고 zerobrew installer를 실행한다. Apple Silicon이면 Rosetta 2도 설치한다. |
| 02 | macos-settings | after | Dock, Finder, Keyboard, Trackpad, Screenshot | 설정 변경 시 | managed target 배포 뒤 `defaults` 명령으로 macOS 설정을 적용한다. |
| 03 | brew-packages | regular | Brewfile 기반 패키지 설치·upgrade | Brewfile 변경 시 | `zb bundle install --auto-init`을 먼저 실행하고 실패 시 `brew bundle`로 폴백한다. Brewfile에서 빠진 package를 자동 삭제하지는 않는다. |
| 05 | app-settings | after | Rectangle, Stats 설정 import | 설정 변경 시 | Rectangle import 파일을 앱 지원 경로에 복사하고, Stats plist는 remote credential을 보존한 뒤 import한다. |
| 05 | runtime | regular | Bun | 최초 1회 | Node.js는 Brewfile에서 관리하고 Bun은 공식 installer로 별도 설치한다. |
| 07 | tokscale-launchd | after | tokscale LaunchAgent 등록·갱신 | 설정 변경 시 | wrapper와 plist를 검증한 뒤 launchd에 재등록한다. 시스템 timezone이 Asia/Seoul인 머신에서 로컬 14:00에 발화하고, 마지막 성공 후 4일 미만이면 건너뛴다. |

> cmux 외부 자동화 제어는 별도 스크립트 없이 `~/.config/cmux/cmux.json`(`automation.socketControlMode=allowAll`)을 선언적으로 배포하여 기본 활성화한다. cmux 0.64+는 이 파일을 정식 설정 경로로 읽으며, 과거 `defaults write com.cmuxterm.app socketControlMode` 방식은 폐기되었다.

### AI 스크립트 (darwin/)

| 순서 | 스크립트 | phase | 역할 | 실행 조건 | 상세 |
|:--:|---|---|---|---|---|
| 10 | ai-core | regular | 필수 Claude Code/Codex CLI, 선택 Antigravity/Hermes/CodeGraph | 최초 1회 | Claude와 Codex는 공식 standalone installer를 사용하며 실패 시 non-zero다. npm이 있으면 CodeGraph를 설치하고 나머지 선택 도구 실패는 warning이다. |
| 11 | ai-claude | regular | CodeGraph MCP | 최초 1회 | Claude CLI 명령으로 사용자 범위 CodeGraph MCP를 `~/.claude.json`에 등록한다. 이 runtime 파일은 chezmoi가 직접 소유하지 않는다. |
| 12 | ai-codex | regular | oh-my-codex, 프로필 초기화 | 최초 1회 | oh-my-codex를 설치하고 초기화한다. 스킬은 symlink로 공유하며 CodeGraph MCP는 `config.toml`에서 관리한다. |

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
| 01 | install-packages | before | curl, git, vim, zsh, bat, zoxide | 최초 1회 | apt-get → dnf → yum 순서로 패키지 관리자를 감지한다. Ghostty는 수동 설치 안내만 출력한다. |
| 02 | shell-baseline | regular | 기본 셸, 로케일, 타임존 | 설정 변경 시 | zsh 기본 셸, en_US.UTF-8, Asia/Seoul 설정을 시도한다. |
| 03 | git-baseline | regular | Git 사용자 설정, SSH 기초 | 설정 변경 시 | managed `.gitconfig`을 확인하고 SSH 디렉토리·GitHub known_hosts·키 생성 안내를 준비한다. |
| 04 | ai-tools | regular | claude, codex, codegraph, antigravity, hermes, oh-my-codex | 최초 1회 | npm이 이미 있어야 실행된다. 현재 Linux prerequisite는 Node/npm을 설치하지 않으므로 깨끗한 머신에서는 별도 준비가 필요하다. |
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
   - macos-settings, app-settings
   - mattpocock-skills
   - tokscale-launchd, manual-install
```

`app-settings`와 `tokscale-launchd`는 앞 phase에서 배포된 target을 사용한다. external의 `168h`는 예약 주기가 아니라 chezmoi command가 상태를 읽을 때 refresh 여부를 판단하는 cache 최소 age다.

### Linux

```text
1. before scripts
   - skills-ssot-migrate
   - install-packages

2. managed targets + regular scripts(application order)
   - 공통/Linux dotfiles와 external archive 배포
   - shell-baseline, git-baseline, ai-tools, system-baseline

3. after scripts
   - mattpocock-skills
```

## Brewfile 패키지

Brewfile은 `zb bundle install --auto-init -f Brewfile`로 먼저 처리한다. zerobrew가 실패하면 `brew bundle --file=Brewfile`로 폴백한다. 두 경로 모두 package 설치·upgrade를 담당하며, Brewfile에서 빠진 package 제거는 별도 cleanup 명령 없이는 수행하지 않는다.
Doppler tap이 신뢰되지 않은 상태에서 Homebrew 폴백이 실행되면 `dopplerhq/cli/doppler`만 건너뛰며, 신뢰 여부는 사용자가 `brew trust --formula dopplerhq/cli/doppler`로 명시한다.
AI 도구(Claude Code, Codex, Antigravity, Hermes, CodeGraph)는 설치 채널 정책에 따라 AI 스크립트에서 각 채널(curl/npm)로 관리한다. Brewfile은 Homebrew가 직접 관리하는 대상만 유지한다.

| 대주제    | 소주제         | 상세 패키지                                                                                                              |
|--------|-------------|---------------------------------------------------------------------------------------------------------------------|
| 시스템    | 기본 CLI      | bash, bat, zsh, curl, wget, git, git-lfs, gh, grep, jq, gnupg, pkgconf(pkg-config), shellcheck, terminal-notifier, tree, vim |
| 시스템    | 개발 보조 CLI   | act, awscli, direnv, doppler, fswatch, fzf, ripgrep, tmux, watchman, zoxide                                         |
| 런타임    | 언어 런타임      | dotnet, go, kotlin, node, openjdk, php, python, ruby, rust                                                          |
| 런타임    | 패키지/가상환경    | composer, mise, npm, pipx, uv, xcodes, yarn                                                                         |
| 데이터/도구 | 데이터/유틸      | sqlite                                                                                                              |
| 터미널/앱  | 폰트          | font-d2coding                                                                                                       |
| 터미널/앱  | 터미널         | cmux, ghostty                                                                                                       |
| 터미널/앱  | 개발 앱 (cask) | docker-desktop, figma, flutter, gcloud-cli, github, iterm2, postman, proxyman, visual-studio-code                   |
| 터미널/앱  | 일반 앱 (cask) | appcleaner, google-chrome, iina, keka, rectangle, slack, stats                                                      |

**AI CLI 설치 채널 (공식 문서 확인 기준)**

| 도구          | 분류 | 공식 설치 채널                                                                        | 기본 운영 채널 |
|-------------|----|---------------------------------------------------------------------------------|----------|
| Claude      | 공식 | 공식 스크립트 (`curl -fsSL https://claude.ai/install.sh \| bash`)                     | curl     |
| Codex       | 공식 | npm (`npm install -g @openai/codex`)                                            | npm      |
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
