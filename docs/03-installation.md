# 설치

## macOS 스크립트 (darwin/)

| 순서  | 스크립트           | 역할                                           | 실행 조건             | 상세                                                                                                                                                                                                         |
|:---:|----------------|----------------------------------------------|-------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 01  | prerequisites  | Xcode CLI, Homebrew, zerobrew                | 최초 1회, dotfiles 전 | Xcode Command Line Tools가 없으면 설치하고, Homebrew를 설치한 뒤 zerobrew(Rust 기반 Homebrew 대안 클라이언트)를 설치하여 `zb` 명령을 기본 패키지 관리자로 설정. Homebrew와 zerobrew 모두 공식 `curl \| bash` 방식으로 설치한다. Apple Silicon이면 Rosetta 2도 함께 설치 |
| 02  | macos-settings | Dock, Finder, Keyboard, Trackpad, Screenshot | 설정 변경 시           | defaults 명령으로 macOS 시스템 설정을 일괄 적용. `run_onchange_`이므로 스크립트 내용이 변경될 때만 재실행되어 불필요한 재적용을 방지                                                                                                                   |
| 03  | brew-packages  | Brewfile 기반 패키지 설치                           | Brewfile 변경 시     | Brewfile의 체크섬을 감시하여 패키지 목록이 변경되면 `brew bundle`로 전체 패키지를 동기화. 새 패키지 추가, 기존 패키지 제거를 한 번에 처리                                                                                                                  |
| 04  | cmux-settings  | cmux 외부 제어 기본 활성화                            | 설정 변경 시           | `~/.config/cmux/settings.json`을 배포하고 `defaults write com.cmuxterm.app socketControlMode -string automation`을 적용해 신규 macOS 시스템에서 cmux 외부 자동화 제어를 기본 활성화                                                     |
| 05  | runtime        | Bun                                          | 최초 1회             | JavaScript/TypeScript 런타임으로 Bun을 설치. Node.js는 Brewfile에서 관리하고, Bun은 공식 설치 스크립트로 별도 설치                                                                                                                      |

### AI 스크립트 (darwin/)

| 순서 | 스크립트        | 역할                                                           | 실행 조건 | 상세                                                                                                                                |
|:--:|-------------|--------------------------------------------------------------|-------|-----------------------------------------------------------------------------------------------------------------------------------|
| 10 | ai-core     | Claude Code, Codex CLI, Gemini CLI, Copilot CLI, superpowers | 최초 1회 | 공식 AI CLI 도구 4종 설치 + superpowers를 ~/superpowers에 clone. Claude Code는 공식 설치 스크립트(curl), 나머지 3종은 npm. 확장 환경 구성은 개별 스크립트(11~14)에서 처리 |
| 11 | ai-claude   | SuperClaude, peon-ping                                       | 최초 1회 | SuperClaude 프레임워크(pipx), peon-ping 알림 사운드. 플러그인·MCP는 settings.json·claude.json에서 선언적 관리                                           |
| 12 | ai-codex    | oh-my-codex, superpowers (copy), 프로필 초기화                     | 최초 1회 | oh-my-codex(npm), ~/superpowers에서 ~/.agents/skills/superpowers로 복사, 프로필 초기화                                                       |
| 13 | ai-gemini   | SuperGemini, superpowers (copy)                              | 최초 1회 | SuperGemini 확장 프레임워크(pipx), ~/superpowers에서 ~/.gemini/skills/superpowers로 복사. MCP는 settings.json에서 선언적 관리                         |
| 14 | ai-copilot  | superpowers (copy)                                           | 최초 1회 | ~/superpowers에서 ~/.copilot/skills/superpowers로 복사. MCP는 mcp-config.json에서 선언적 관리                                                  |
| 20 | ai-opencode | OpenCode, oh-my-opencode, superpowers (copy)                 | 최초 1회 | OpenCode(npm), oh-my-opencode(npm), ~/superpowers에서 ~/.config/opencode/plugins/superpowers로 복사. MCP는 opencode.json에서 선언적 관리       |

| 순서 | 스크립트           | 역할          | 실행 조건             |
|:--:|----------------|-------------|-------------------|
| 99 | manual-install | 수동 설치 안내 출력 | 최초 1회, dotfiles 후 |

**AI 스크립트 설계 원칙**:

- 코어 설치(10)와 프로바이더별 확장 설치(11~14, 20)를 분리하여 책임 경계를 명확히 유지
- 각 프로바이더가 MCP 서버, 스킬, 플러그인을 독립적으로 관리하여 한 도구의 실패가 다른 도구에 영향을 주지 않음
- 공식 AI CLI(10번대)와 외부 오픈소스 도구(20번대)를 번호 대역으로 구분
- superpowers는 ai-core(10)에서 ~/superpowers에 한 번 clone하고, 각 프로바이더 스크립트에서 도구별 스킬 경로로 복사하여 개별 커스텀 가능
- humanizer 스킬은 Claude/Codex는 `.chezmoiexternal.toml`로 자동 배포

### Linux 스크립트 (linux/)

| 순서 | 스크립트             | 역할                                                           | 실행 조건             | 상세                                                               |
|:--:|------------------|--------------------------------------------------------------|-------------------|------------------------------------------------------------------|
| 01 | install-packages | curl, git, vim, zsh, ghostty                                 | 최초 1회, dotfiles 전 | 패키지 관리자를 자동 감지(apt-get → dnf → yum)하여 기초 도구를 설치. 이미 설치된 패키지는 건너뜀 |
| 02 | shell-baseline   | 기본 셸, 로케일, 타임존                                               | 설정 변경 시           | zsh를 기본 셸로 전환하고 히스토리, 키바인딩 기본값을 설정. 로케일과 타임존 정책도 함께 적용           |
| 03 | git-baseline     | Git 사용자 설정, SSH 기초                                           | 설정 변경 시           | 템플릿 변수(name, email)로 Git 사용자 정보를 설정하고 SSH 키 생성 기초 환경을 구성         |
| 04 | ai-tools         | claude, codex, oh-my-codex, opencode, oh-my-opencode, gemini | 최초 1회             | macOS와 동일한 AI 스택을 최소 구성으로 설치                                     |
| 05 | system-baseline  | 시스템 기초 설정                                                    | 설정 변경 시           | 기본 에디터, 시스템 경로, 기초 보안 설정 등 OS 수준 기본값 적용                          |

## 설치 흐름

### macOS

```
chezmoi init --apply
│
├─ 01 prerequisites
│   Xcode CLI Tools → Homebrew → zerobrew → Rosetta 2 (Apple Silicon)
│   시스템 패키지 관리 기반 구성. Homebrew와 zerobrew 모두 공식 curl | bash 방식으로 설치
│
├─ .chezmoiexternal.toml
│   Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting, humanizer
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
│   Claude Code, Codex CLI, Gemini CLI, Copilot CLI, superpowers
│   Claude Code(curl 스크립트), Codex·Gemini·Copilot(npm) 설치, superpowers를 ~/superpowers에 clone
│
├─ 11 ai-claude
│   SuperClaude, peon-ping (플러그인·MCP는 설정 파일로 관리)
│
├─ 12 ai-codex
│   oh-my-codex → superpowers (copy) → 프로필 초기화
│
├─ 13 ai-gemini
│   SuperGemini, superpowers (copy) (MCP는 settings.json으로 관리)
│
├─ 14 ai-copilot
│   superpowers (copy) (MCP는 mcp-config.json으로 관리)
│
├─ 20 ai-opencode
│   OpenCode → oh-my-opencode → superpowers (copy)
│
├─ dotfiles 배포
│   ~/.zshrc, ~/.gitconfig, ~/.gitignore_global, ~/.vimrc
│   ~/AGENTS.md (공통 에이전트 지침)
│   ~/.config/cmux/settings.json, ~/.config/ghostty/config, ~/.config/opencode/*
│   ~/.claude/settings.json, ~/.claude/hooks/peon-ping/*
│   ~/.codex/config.toml
│   ~/.agents/skills/*, ~/.copilot/mcp-config.json, ~/.copilot/skills/*
│   ~/.gemini/settings.json
│   ~/.local/bin/dotfiles-doctor
│
└─ 99 manual-install
    JetBrains Toolbox, Raycast (자동 설치 불가 항목 안내)
```

### Linux

```
chezmoi init --apply
│
├─ 01 install-packages
│   curl, git, vim, zsh, ghostty
│   패키지 관리자 자동 감지 (apt-get → dnf → yum)
│
├─ .chezmoiexternal.toml
│   Oh My Zsh, zsh-autosuggestions, zsh-syntax-highlighting, humanizer
│
├─ 02 shell-baseline
│   기본 셸 zsh 전환, 히스토리, 키바인딩, 로케일, 타임존
│
├─ 03 git-baseline
│   Git 사용자 설정, SSH 기초 설정
│
├─ 04 ai-tools
│   claude, codex, oh-my-codex, opencode, oh-my-opencode,
│   gemini
│
├─ 05 system-baseline
│   시스템 기초 설정
│
└─ dotfiles 배포
    ~/.zshrc, ~/.gitconfig, ~/.gitignore_global
    ~/AGENTS.md
    ~/.config/ghostty/config, ~/.config/opencode/*
    ~/.claude/*, ~/.codex/*, ~/.agents/*, ~/.copilot/*
    ~/.gemini/*
```

## Brewfile 패키지

Brewfile은 `zb bundle`(zerobrew) 명령으로 동기화한다. zerobrew 실패 시 `brew bundle`로 폴백한다. 패키지 추가/제거는 Brewfile만 수정하면 다음
`chezmoi apply`에서 자동 반영된다.
AI CLI(Claude Code, Codex, Gemini, Copilot)는 공식 설치 채널 정책에 따라 AI 스크립트에서 각 공식 채널(curl/npm)로 관리하고, Brewfile은 Homebrew 직접 관리
대상만 유지한다.

| 대주제    | 소주제         | 상세 패키지                                                                                                              |
|--------|-------------|---------------------------------------------------------------------------------------------------------------------|
| 시스템    | 기본 CLI      | bash, bat, zsh, curl, wget, git, git-lfs, gh, grep, jq, gnupg, pkg-config, shellcheck, terminal-notifier, tree, vim |
| 시스템    | 개발 보조 CLI   | act, awscli, direnv, doppler, fswatch, fzf, ripgrep, tmux, watchman, zoxide                                         |
| 런타임    | 언어 런타임      | dotnet, go, kotlin, node, openjdk, php, python, ruby, rust                                                          |
| 런타임    | 패키지/가상환경    | composer, mise, npm, pipx, uv, xcodes, yarn                                                                         |
| 데이터/도구 | 데이터/유틸      | sqlite                                                                                                              |
| 터미널/앱  | 폰트          | font-d2coding                                                                                                       |
| 터미널/앱  | 터미널         | cmux, ghostty                                                                                                       |
| 터미널/앱  | 개발 앱 (cask) | docker, figma, flutter, gcloud-cli, github, iterm2, postman, proxyman, visual-studio-code                           |
| 터미널/앱  | 일반 앱 (cask) | appcleaner, google-chrome, iina, keka, rectangle, slack, stats                                                      |

**AI CLI 설치 채널 (공식 문서 확인 기준)**

| 도구       | 분류 | 공식 설치 채널                                                    | 기본 운영 채널 |
|----------|----|-------------------------------------------------------------|----------|
| Claude   | 공식 | 공식 스크립트 (`curl -fsSL https://claude.ai/install.sh \| bash`) | curl     |
| Codex    | 공식 | npm (`npm install -g @openai/codex`)                        | npm      |
| Gemini   | 공식 | npm (`npm install -g @google/gemini-cli`)                   | npm      |
| Copilot  | 공식 | npm (`npm install -g @github/copilot`)                      | npm      |
| OpenCode | 외부 | npm (`npm install -g opencode-ai`)                          | npm      |

## 외부 리소스

`.chezmoiexternal.toml`로 선언적 관리한다. `chezmoi apply` 실행 시 갱신 주기가 지난 리소스는 자동으로 최신 버전을 다운로드한다. Git 아카이브 형태로 가져오므로 `.git`
디렉토리 없이 파일만 배포된다.

| 리소스                     | 대상 경로                         | 역할                                                      | 갱신 주기     | 가져오기 방식 |
|-------------------------|-------------------------------|---------------------------------------------------------|-----------|---------|
| Oh My Zsh               | `~/.oh-my-zsh`                | Zsh 프레임워크. 테마, 플러그인 관리 기반                               | 168h (1주) | archive |
| zsh-autosuggestions     | Oh My Zsh custom/plugins/     | 히스토리 기반 입력 자동완성. 타이핑 중 이전 명령을 흐린 글씨로 제안                 | 168h      | archive |
| zsh-syntax-highlighting | Oh My Zsh custom/plugins/     | 명령어 구문 강조. 유효한 명령은 녹색, 잘못된 명령은 빨간색으로 표시                 | 168h      | archive |
| humanizer               | `~/.claude/skills/humanizer/` | AI 글쓰기 패턴 제거 스킬. SKILL.md 기반으로 AI 특유의 표현을 자연스러운 문장으로 교정 | 168h      | archive |
| humanizer (Codex)       | `~/.agents/skills/humanizer/` | 동일 humanizer 스킬을 Codex 글로벌 스킬 경로에 배포                    | 168h      | archive |
