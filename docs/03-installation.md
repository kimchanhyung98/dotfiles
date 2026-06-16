# 설치

> **실행 조건 표기**: `최초 1회`는 chezmoi `run_once_` 스크립트로, 최초 적용 시 1회 실행되며 스크립트 내용(템플릿 렌더 결과)이 바뀌면 다음 `chezmoi apply`에서 다시
> 실행된다(각 설치 블록은 `command -v` 가드로 멱등성을 보장). `설정 변경 시`는 `run_onchange_`로, 내용이 변경될 때만 재실행된다.

## OS 공통 스크립트

| 스크립트                | 역할                          | 실행 조건       | 상세                                                                                                                                                                                                                                                                                                                 |
|---------------------|-----------------------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| skills-ssot-migrate | 기존 스킬 디렉토리 제거 | 최초 1회, 배포 전 | `run_once_before_`로 dotfiles 배포 전에 실행. Claude Code와 Codex의 skills 경로가 symlink 전환 이전의 실제 디렉토리면 삭제하여, dotfiles 배포 단계에서 `~/.skills` symlink로 교체될 수 있게 한다. 모든 경로가 이미 symlink면 아무 일도 하지 않음(멱등) |
| mattpocock-skills | 외부 스킬 동기화 | 최초 적용 및 스크립트 변경 시, 배포 후 | `run_onchange_after_`로 dotfiles 배포 후 실행. `~/.local/bin/mattpocock-skills-sync`가 `mattpocock/skills`에서 선택한 스킬만 `~/.skills`로 동기화한다. 수동 재실행 시 선택 목록에 포함된 동명 스킬 디렉토리는 upstream 내용으로 교체하고, 선택 목록 밖의 사용자 스킬은 건드리지 않는다. |

## macOS 스크립트 (darwin/)

| 순서 | 스크립트           | 역할                                           | 실행 조건             | 상세                                                                                                                                                                                                         |
|:--:|----------------|----------------------------------------------|-------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 01 | prerequisites  | Xcode CLI, Homebrew, zerobrew                | 최초 1회, dotfiles 전 | Xcode Command Line Tools가 없으면 설치하고, Homebrew를 설치한 뒤 zerobrew(Rust 기반 Homebrew 대안 클라이언트)를 설치하여 `zb` 명령을 기본 패키지 설치 경로로 준비한다. Homebrew와 zerobrew 모두 공식 `curl \| bash` 방식으로 설치한다. Apple Silicon이면 Rosetta 2도 함께 설치 |
| 02 | macos-settings | Dock, Finder, Keyboard, Trackpad, Screenshot | 설정 변경 시           | defaults 명령으로 macOS 시스템 설정을 일괄 적용. `run_onchange_`이므로 스크립트 내용이 변경될 때만 재실행되어 불필요한 재적용을 방지                                                                                                                   |
| 03 | brew-packages  | Brewfile 기반 패키지 설치                           | Brewfile 변경 시     | Brewfile의 체크섬을 감시하여 패키지 목록이 변경되면 `brew bundle`로 전체 패키지를 동기화. 새 패키지 추가, 기존 패키지 제거를 한 번에 처리                                                                                                                  |
| 04 | cmux-settings  | cmux 외부 제어 기본 활성화                            | 설정 변경 시           | `~/.config/cmux/settings.json`을 배포하고 `defaults write com.cmuxterm.app socketControlMode -string automation`을 적용해 신규 macOS 시스템에서 cmux 외부 자동화 제어를 기본 활성화                                                     |
| 05 | runtime        | Bun                                          | 최초 1회             | JavaScript/TypeScript 런타임으로 Bun을 설치. Node.js는 Brewfile에서 관리하고, Bun은 공식 설치 스크립트로 별도 설치                                                                                                                      |

### AI 스크립트 (darwin/)

| 순서 | 스크립트      | 역할                                                               | 실행 조건 | 상세                                                                                                                                 |
|:--:|-----------|------------------------------------------------------------------|-------|------------------------------------------------------------------------------------------------------------------------------------|
| 10 | ai-core   | Claude Code, Codex CLI, Antigravity CLI, Hermes Agent, CodeGraph | 최초 1회 | AI CLI 도구 4종과 CodeGraph 설치. Claude Code·Antigravity·Hermes는 공식 설치 스크립트(curl), Codex·CodeGraph는 npm. 확장 환경 구성은 개별 스크립트(11~12)에서 처리  |
| 11 | ai-claude | SuperClaude, CodeGraph MCP                                       | 최초 1회 | SuperClaude 프레임워크(pipx). CodeGraph MCP를 등록하고, 플러그인·MCP는 settings.json·claude.json에서 선언적 관리                                         |
| 12 | ai-codex  | oh-my-codex, 프로필 초기화                                             | 최초 1회 | oh-my-codex(npm), 프로필 초기화. Codex 스킬은 ~/.agents/skills → ~/.skills symlink로 공유. CodeGraph MCP는 config.toml에서 선언적 관리 |

| 순서 | 스크립트           | 역할          | 실행 조건             |
|:--:|----------------|-------------|-------------------|
| 99 | manual-install | 수동 설치 안내 출력 | 최초 1회, dotfiles 후 |

**AI 스크립트 설계 원칙**:

- 코어 설치(10)와 프로바이더별 확장 설치(11~12)를 분리하여 책임 경계를 명확히 유지
- 각 프로바이더가 MCP 서버, 플러그인을 독립적으로 관리하여 한 도구의 실패가 다른 도구에 영향을 주지 않음
- 스킬은 단일 출처 `~/.skills`에 두고 Claude Code와 Codex의 글로벌 skills 경로를 symlink로 연결하여 공유 (상세는 05-ai-tools.md 참고)

### Linux 스크립트 (linux/)

| 순서 | 스크립트             | 역할                                                         | 실행 조건             | 상세                                                                       |
|:--:|------------------|------------------------------------------------------------|-------------------|--------------------------------------------------------------------------|
| 01 | install-packages | curl, git, vim, zsh, ghostty                               | 최초 1회, dotfiles 전 | 패키지 관리자를 자동 감지(apt-get → dnf → yum)하여 기초 도구를 설치. 이미 설치된 패키지는 건너뜀         |
| 02 | shell-baseline   | 기본 셸, 로케일, 타임존                                             | 설정 변경 시           | zsh를 기본 셸로 전환하고 히스토리, 키바인딩 기본값을 설정. 로케일과 타임존 정책도 함께 적용                   |
| 03 | git-baseline     | Git 사용자 설정, SSH 기초                                         | 설정 변경 시           | 템플릿 변수(name, email)로 Git 사용자 정보를 설정하고 SSH 키 생성 기초 환경을 구성                 |
| 04 | ai-tools         | claude, codex, codegraph, antigravity, hermes, oh-my-codex | 최초 1회             | macOS와 동일한 AI 도구를 Linux용 구성으로 설치. Hermes는 자체 의존성을 함께 준비하므로 설치 시간이 길 수 있음 |
| 05 | system-baseline  | 시스템 기초 설정                                                  | 설정 변경 시           | 기본 에디터, 시스템 경로, 기초 보안 설정 등 OS 수준 기본값 적용                                  |

## 설치 흐름

### macOS

```
chezmoi init --apply
│
├─ skills-ssot-migrate (run_once_before, OS 공통)
│   기존 실제 skills 디렉토리를 삭제해 symlink 교체 준비
│
├─ 01 prerequisites
│   Xcode CLI Tools → Homebrew → zerobrew → Rosetta 2 (Apple Silicon)
│   시스템 패키지 관리 기반 구성. Homebrew와 zerobrew 모두 공식 curl | bash 방식으로 설치
│
├─ .chezmoiexternal.toml
│   Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting
│   외부 Git 리소스를 선언적으로 다운로드. 168시간(1주) 주기로 자동 갱신
│
├─ 02 macos-settings
│   Dock, Finder, Keyboard, Trackpad, Screenshot
│   defaults 명령 기반 시스템 UI/입력 설정 일괄 적용
│
├─ 03 brew-packages
│   시스템 CLI, 런타임, 데이터/도구, 터미널/앱
│   Brewfile 기반 전체 패키지 동기화 (zerobrew 우선, Homebrew 폴백)
│
├─ 04 cmux-settings
│   ~/.config/cmux/settings.json + socketControlMode=automation
│   cmux 외부 자동화 제어 기본 활성화
│
├─ 05 runtime
│   Bun (JavaScript/TypeScript 런타임)
│
├─ 10 ai-core
│   Claude Code, Codex CLI, Antigravity CLI, Hermes Agent, CodeGraph
│   Claude Code·Antigravity·Hermes(curl 스크립트), Codex·CodeGraph(npm) 설치
│
├─ 11 ai-claude
│   SuperClaude (플러그인·MCP는 설정 파일로 관리)
│
├─ 12 ai-codex
│   oh-my-codex → 프로필 초기화 (스킬은 ~/.skills 공유, CodeGraph MCP는 config.toml로 관리)
│
├─ dotfiles 배포
│   ~/.zshrc, ~/.gitconfig, ~/.gitignore_global, ~/.vimrc
│   ~/AGENTS.md (공통 에이전트 지침)
│   ~/.config/cmux/settings.json, ~/.config/ghostty/config
│   ~/.claude/settings.json
│   ~/.codex/config.toml
│   ~/.skills/* (공통 스킬 단일 출처), 지원 스킬 경로(~/.claude/skills, ~/.agents/skills) → ~/.skills symlink
│   ~/.local/bin/dotfiles-doctor, ~/.local/bin/mattpocock-skills-sync
│
├─ mattpocock-skills (run_onchange_after, OS 공통)
│   mattpocock/skills에서 선택한 스킬을 ~/.skills로 동기화
│
└─ 99 manual-install
    JetBrains Toolbox, Raycast (자동 설치 불가 항목 안내)
```

### Linux

```
chezmoi init --apply
│
├─ skills-ssot-migrate (run_once_before, OS 공통)
│   기존 실제 skills 디렉토리를 삭제해 symlink 교체 준비
│
├─ 01 install-packages
│   curl, git, vim, zsh, ghostty
│   패키지 관리자 자동 감지 (apt-get → dnf → yum)
│
├─ .chezmoiexternal.toml
│   Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting
│
├─ 02 shell-baseline
│   기본 셸 zsh 전환, 히스토리, 키바인딩, 로케일, 타임존
│
├─ 03 git-baseline
│   Git 사용자 설정, SSH 기초 설정
│
├─ 04 ai-tools
│   claude, codex, codegraph, antigravity, hermes,
│   oh-my-codex
│
├─ 05 system-baseline
│   시스템 기초 설정
│
├─ dotfiles 배포
│   ~/.zshrc, ~/.gitconfig, ~/.gitignore_global
│   ~/AGENTS.md
│   ~/.config/ghostty/config
│   ~/.claude/*, ~/.codex/*, ~/.agents/*
│   ~/.skills/* (공통 스킬 단일 출처), 지원 스킬 경로(~/.claude/skills, ~/.agents/skills) → ~/.skills symlink
│   ~/.local/bin/mattpocock-skills-sync
│
└─ mattpocock-skills (run_onchange_after, OS 공통)
    mattpocock/skills에서 선택한 스킬을 ~/.skills로 동기화
```

## Brewfile 패키지

Brewfile은 `zb bundle install -f Brewfile`(zerobrew)로 먼저 동기화한다. zerobrew가 처리하지 못하는 항목이 있거나 실패하면 `brew bundle`로 폴백한다.
Doppler tap이 신뢰되지 않은 상태에서 Homebrew 폴백이 실행되면 `dopplerhq/cli/doppler`만 건너뛰며, 신뢰 여부는 사용자가 `brew trust --formula dopplerhq/cli/doppler`로 명시한다.
AI 도구(Claude Code, Codex, Antigravity, Hermes, CodeGraph)는 설치 채널 정책에 따라 AI 스크립트에서 각 채널(curl/npm)로 관리하고, Brewfile은
Homebrew 직접 관리
대상만 유지한다.

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

`.chezmoiexternal.toml`로 선언적 관리한다. `chezmoi apply` 실행 시 갱신 주기가 지난 리소스는 자동으로 최신 버전을 다운로드한다. Git 아카이브 형태로 가져오므로 `.git`
디렉토리 없이 파일만 배포된다.

| 리소스                     | 대상 경로                     | 역할                                      | 갱신 주기     | 가져오기 방식 |
|-------------------------|---------------------------|-----------------------------------------|-----------|---------|
| Oh My Zsh               | `~/.oh-my-zsh`            | Zsh 프레임워크. 테마, 플러그인 관리 기반               | 168h (1주) | archive |
| zsh-autosuggestions     | Oh My Zsh custom/plugins/ | 히스토리 기반 입력 자동완성. 타이핑 중 이전 명령을 흐린 글씨로 제안 | 168h      | archive |
| zsh-syntax-highlighting | Oh My Zsh custom/plugins/ | 명령어 구문 강조. 유효한 명령은 녹색, 잘못된 명령은 빨간색으로 표시 | 168h      | archive |
