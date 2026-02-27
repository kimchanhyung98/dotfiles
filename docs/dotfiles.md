# Dotfiles

macOS / Linux 개발 환경 자동화를 위한 chezmoi 기반 dotfiles.

## 범위

- macOS 중심 환경에 시스템, Claude, Codex, Gemini, Copilot, OpenCode, OpenClaw 스택을 통합한다.
- Linux는 기초 셸/패키지/AI 최소 구성으로 유지한다.
- 지정된 저장소 14개를 실제 원격 기준으로 검증하고, 유지 가능한 항목만 선별 적용한다.
- 저장소 원본 전체를 복제하지 않고 유지 가능한 구성만 채택한다.

## 검토 완료 레포

| 카테고리     | 저장소                                                                                                                                                 |
|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| System   | lucasgelfond/zerobrew, ghostty-org/ghostty                                                                                                          |
| Claude   | PeonPing/peon-ping, obra/superpowers, jarrodwatts/claude-hud, blader/humanizer, VoltAgent/awesome-agent-skills, forrestchang/andrej-karpathy-skills |
| Codex    | Yeachan-Heo/oh-my-codex                                                                                                                             |
| Gemini   | (SuperGemini — pipx 패키지)                                                                                                                            |
| OpenCode | anomalyco/opencode, code-yeongyu/oh-my-opencode                                                                                                     |
| OpenClaw | openclaw/openclaw, thedotmack/claude-mem                                                                                                            |

## 검증 스냅샷

- 기준일: 2026-02-16
- 기준: 공식 문서 + 각 레포 최신 원격 main/dev 브랜치

| 저장소                                 | 검증 커밋     |
|-------------------------------------|-----------|
| lucasgelfond/zerobrew               | `a15119f` |
| ghostty-org/ghostty                 | `e94c905` |
| PeonPing/peon-ping                  | `e8d9502` |
| obra/superpowers                    | `e16d611` |
| jarrodwatts/claude-hud              | `10193cc` |
| blader/humanizer                    | `c78047b` |
| VoltAgent/awesome-agent-skills      | `feb81d6` |
| forrestchang/andrej-karpathy-skills | `aa4467f` |
| anomalyco/opencode                  | `ef979cc` |
| code-yeongyu/oh-my-opencode         | `7d2c798` |
| Yeachan-Heo/oh-my-codex             | `c25edb0` |
| openclaw/openclaw                   | `a177f7b` |
| thedotmack/claude-mem               | `e975555` |

## 설계 원칙

- **선언적 관리**: 무엇을 설치할지는 선언 파일(Brewfile, .chezmoiexternal.toml)에 정의하고, 어떻게 설치할지는 실행 스크립트에 분리한다. 패키지 목록과 설치 로직이 섞이지 않아 각각
  독립적으로 변경할 수 있다.
- **멱등성**: 모든 스크립트는 여러 번 실행해도 동일한 결과를 보장한다. 이미 설치된 도구는 건너뛰고, 이미 적용된 설정은 재적용하지 않는다. `chezmoi apply`를 반복 실행해도 시스템 상태가 일관되게
  유지된다.
- **순서 보장**: chezmoi 네이밍 컨벤션(`run_` + `once_`/`onchange_` + `before_`/`after_` + 이름)으로 실행 순서를 제어한다. 번호
  접두사(01, 02, ...)로 같은 타입 내 순서를 추가로 고정한다. `macos-settings`는 파일 배포 이후 적용이 필요하므로 `run_onchange_after_`를 사용한다.
- **OS 분기**: 실행 스크립트는 OS별 하위 디렉토리(`darwin/`, `linux/`)로 물리적 분리하고, 설정 파일은 `.tmpl` 템플릿 조건문으로 분기한다. 하나의 소스에서 두 OS 환경을 모두
  관리할 수 있다.
- **설치와 설정 분리**: 도구의 바이너리 설치는 스크립트가 담당하고, 사용자 설정은 chezmoi가 배포하는 설정 파일(`.tmpl`)이 담당한다. 설치 방식이 바뀌어도 설정은 그대로 유지되고, 설정을 변경해도
  재설치가 필요 없다.
- **실패 격리**: 각 AI 도구의 설치를 독립 스크립트로 분리하여, 한 도구의 설치 실패가 다른 도구에 영향을 주지 않는다. Claude 설치가 실패해도 Codex, OpenCode는 정상적으로 설치된다.
- **스킬 공유**: AI 도구 공통 스킬(humanizer, karpathy 지침 등)을 도구별 글로벌 스킬 경로에 각각 배포하여, 어떤 도구를 사용하든 동일한 개발 지침이 적용된다.
- **사용자 설정 우선**: 도구의 기본 동작보다 사용자가 선언한 설정을 우선 적용한다. 도구 업데이트로 기본값이 변경되어도 사용자 설정은 유지된다.
- **검증 가능한 근거 유지**: 모든 경로, 설정 파일명, 도구 동작은 공식 문서 또는 실제 저장소 기준으로 검증한다. 문서에 기재된 정보는 검증 스냅샷의 커밋 해시로 추적할 수 있어야 한다.

## 디렉토리 구조

```
dotfiles/
├── .chezmoiroot
├── .chezmoiversion
├── install.sh
├── docs/
│
└── home/
    ├── .chezmoi.toml.tmpl
    ├── .chezmoiignore
    ├── .chezmoiexternal.toml
    ├── .chezmoiremove
    │
    ├── .chezmoiscripts/
    │   ├── darwin/
    │   │   ├── run_once_before_01-prerequisites.sh.tmpl
    │   │   ├── run_onchange_after_02-macos-settings.sh
    │   │   ├── run_onchange_03-brew-packages.sh.tmpl
    │   │   ├── run_once_04-runtime.sh.tmpl
    │   │   ├── run_once_10-ai-core.sh.tmpl
    │   │   ├── run_once_11-ai-claude.sh.tmpl
    │   │   ├── run_once_12-ai-codex.sh.tmpl
    │   │   ├── run_once_13-ai-gemini.sh.tmpl
    │   │   ├── run_once_14-ai-copilot.sh.tmpl
    │   │   ├── run_once_20-ai-opencode.sh.tmpl
    │   │   ├── run_once_21-ai-openclaw.sh.tmpl
    │   │   └── run_once_after_99-manual-install.sh
    │   │
    │   └── linux/
    │       ├── run_once_before_01-install-packages.sh.tmpl
    │       ├── run_onchange_02-shell-baseline.sh.tmpl
    │       ├── run_onchange_03-git-baseline.sh.tmpl
    │       ├── run_once_04-ai-tools.sh.tmpl
    │       └── run_onchange_05-system-baseline.sh.tmpl
    │
    ├── Brewfile
    ├── dot_zshrc.tmpl
    ├── dot_gitconfig.tmpl
    ├── dot_gitignore_global
    ├── dot_vimrc
    ├── AGENTS.md.tmpl
    ├── dot_claude.json.tmpl
    │
    ├── dot_config/
    │   ├── ghostty/
    │   │   └── config.tmpl
    │   └── opencode/
    │       ├── opencode.json.tmpl
    │       ├── oh-my-opencode.jsonc.tmpl
    │       ├── plugins/
    │       └── skills/
    │
    ├── dot_claude/
    │   ├── settings.json.tmpl
    │   └── hooks/
    │       └── peon-ping/
    │           └── config.json.tmpl
    │
    ├── dot_codex/
    │   ├── config.toml.tmpl
    │   ├── AGENTS.md.tmpl
    │   └── prompts/
    │
    ├── dot_agents/
    │   └── skills/
    │
    ├── dot_copilot/
    │   └── skills/
    │
    ├── dot_openclaw/
    │   ├── openclaw.json.tmpl
    │   └── workspace/
    │       ├── AGENTS.md.tmpl
    │       ├── SOUL.md.tmpl
    │       └── TOOLS.md.tmpl
    │
    └── dot_local/bin/
        └── executable_dotfiles-doctor
```

**디렉토리 배포 매핑**

| 소스 (chezmoi)           | 배포 대상                 | 용도                              |
|------------------------|-----------------------|---------------------------------|
| `dot_claude.json.tmpl` | `~/.claude.json`      | MCP 서버 설정 (홈 루트, `.chezmoiignore`로 제외 — Claude Code 런타임 관리) |
| `AGENTS.md.tmpl`       | `~/AGENTS.md`         | 공통 에이전트 지침 (홈 루트)               |
| `dot_config/ghostty/`  | `~/.config/ghostty/`  | Ghostty 터미널 설정                  |
| `dot_config/opencode/` | `~/.config/opencode/` | OpenCode + oh-my-opencode 설정    |
| `dot_claude/`          | `~/.claude/`          | Claude Code 설정, 훅               |
| `dot_codex/`           | `~/.codex/`           | Codex CLI 설정, 프롬프트, 글로벌 에이전트 지침 |
| `dot_agents/skills/`   | `~/.agents/skills/`   | Codex 글로벌 스킬                    |
| `dot_copilot/skills/`  | `~/.copilot/skills/`  | Copilot 글로벌 스킬                  |
| `dot_gemini/`          | `~/.gemini/`          | Gemini CLI 설정 (MCP 서버)          |
| `dot_openclaw/`        | `~/.openclaw/`        | OpenClaw 설정, 워크스페이스             |
| `dot_local/bin/`       | `~/.local/bin/`       | 사용자 스크립트 (dotfiles-doctor)      |

## chezmoi special 파일

| 파일                      | 역할                         | 상세                                                                                                 |
|-------------------------|----------------------------|----------------------------------------------------------------------------------------------------|
| `.chezmoiroot`          | source root 경로 고정 (`home`) | chezmoi가 `home/` 디렉토리를 소스 루트로 인식하게 하여, 저장소 루트의 docs/, install.sh 등이 홈 디렉토리에 배포되지 않도록 격리            |
| `.chezmoiversion`       | 최소 chezmoi 실행 버전 고정        | 이 dotfiles가 요구하는 chezmoi 최소 버전을 명시하여, 이전 버전의 호환성 문제를 사전 차단                                         |
| `.chezmoiignore`        | OS별·런타임 경로 제외              | 템플릿 조건문으로 현재 OS에 해당하지 않는 설정 파일을 배포 대상에서 제외. 저장소 메타 파일(README, LICENSE 등)과 Claude Code 런타임 데이터(`.claude.json`)도 공통 제외 |
| `.chezmoiexternal.toml` | 외부 리소스 선언적 동기화             | Oh My Zsh, zsh 플러그인, humanizer 등 외부 Git 저장소를 선언하여 `chezmoi apply` 시 자동 다운로드/갱신. 갱신 주기를 리소스별로 개별 설정 |
| `.chezmoiremove`        | 더 이상 필요 없는 파일 제거 대상 관리     | dotfiles에서 관리를 중단한 파일을 나열하여 다음 apply 시 자동 삭제. 설정 파일 이름이 변경되었거나 도구를 제거한 경우 잔여 파일 정리에 활용             |

## 스크립트

### macOS (darwin/)

| 순서 | 스크립트           | 역할                                           | 실행 조건             | 상세                                                                                                                                                                                                               |
|:--:|----------------|----------------------------------------------|-------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 01 | prerequisites  | Xcode CLI, Homebrew, zerobrew                | 최초 1회, dotfiles 전 | Xcode Command Line Tools가 없으면 설치하고, Homebrew를 설치한 뒤 zerobrew(Rust 기반 Homebrew 대안 클라이언트)를 설치하여 `zb` 명령을 기본 패키지 관리자로 설정. Homebrew는 공식 bootstrap(`curl ... \| bash`) 방식을 예외로 사용한다. Apple Silicon이면 Rosetta 2도 함께 설치 |
| 02 | macos-settings | Dock, Finder, Keyboard, Trackpad, Screenshot | 설정 변경 시           | defaults 명령으로 macOS 시스템 설정을 일괄 적용. `run_onchange_`이므로 스크립트 내용이 변경될 때만 재실행되어 불필요한 재적용을 방지                                                                                                                         |
| 03 | brew-packages  | Brewfile 기반 패키지 설치                           | Brewfile 변경 시     | Brewfile의 체크섬을 감시하여 패키지 목록이 변경되면 `brew bundle`로 전체 패키지를 동기화. 새 패키지 추가, 기존 패키지 제거를 한 번에 처리                                                                                                                        |
| 04 | runtime        | Bun                                          | 최초 1회             | JavaScript/TypeScript 런타임으로 Bun을 설치. Node.js는 Brewfile에서 관리하고, Bun은 공식 설치 스크립트로 별도 설치                                                                                                                            |

**AI 스크립트 (darwin/)**

| 순서 | 스크립트        | 역할                                                           | 실행 조건 | 상세                                                                                                                                |
|:--:|-------------|--------------------------------------------------------------|-------|-----------------------------------------------------------------------------------------------------------------------------------|
| 10 | ai-core     | Claude Code, Codex CLI, Gemini CLI, Copilot CLI, Auggie CLI, superpowers | 최초 1회 | 공식 AI CLI 도구 4종 + Auggie CLI 설치 + superpowers를 ~/superpowers에 clone. Claude Code는 공식 설치 스크립트(curl), 나머지는 npm. 확장 환경 구성은 개별 스크립트(11~14)에서 처리 |
| 11 | ai-claude   | SuperClaude, peon-ping, Augment MCP 등록                      | 최초 1회 | SuperClaude 프레임워크(pipx), peon-ping 알림 사운드, `claude mcp add-json`으로 Augment Context Engine MCP 등록. 플러그인은 settings.json에서 선언적 관리    |
| 12 | ai-codex    | oh-my-codex, superpowers (copy), 프로필 초기화                     | 최초 1회 | oh-my-codex(npm), ~/superpowers에서 ~/.agents/skills/superpowers로 복사, 프로필 초기화                                                       |
| 13 | ai-gemini   | SuperGemini, superpowers (copy)                              | 최초 1회 | SuperGemini 확장 프레임워크(pipx), ~/superpowers에서 ~/.gemini/skills/superpowers로 복사. MCP는 settings.json에서 선언적 관리                         |
| 14 | ai-copilot  | superpowers (copy)                                           | 최초 1회 | ~/superpowers에서 ~/.copilot/skills/superpowers로 복사. MCP는 mcp-config.json에서 선언적 관리                                                  |
| 20 | ai-opencode | OpenCode, oh-my-opencode, superpowers (copy)                 | 최초 1회 | OpenCode(npm), oh-my-opencode(npm), ~/superpowers에서 ~/.config/opencode/plugins/superpowers로 복사. MCP는 opencode.json에서 선언적 관리       |
| 21 | ai-openclaw | OpenClaw, 데몬 등록, claude-mem 연동                               | 최초 1회 | OpenClaw(npm), macOS launchd 데몬 등록, claude-mem 연동(별도 설치 스크립트). 로그: `~/Library/Logs/openclaw.log`                                  |

| 순서 | 스크립트           | 역할          | 실행 조건             |
|:--:|----------------|-------------|-------------------|
| 99 | manual-install | 수동 설치 안내 출력 | 최초 1회, dotfiles 후 |

**AI 스크립트 설계 원칙**:

- 코어 설치(10)와 프로바이더별 확장 설치(11~14, 20~21)를 분리하여 책임 경계를 명확히 유지
- 각 프로바이더가 MCP 서버, 스킬, 플러그인을 독립적으로 관리하여 한 도구의 실패가 다른 도구에 영향을 주지 않음
- 공식 AI CLI(10번대)와 외부 오픈소스 도구(20번대)를 번호 대역으로 구분
- superpowers는 ai-core(10)에서 ~/superpowers에 한 번 clone하고, 각 프로바이더 스크립트에서 도구별 스킬 경로로 복사하여 개별 커스텀 가능
- humanizer 스킬은 Claude/Codex는 `.chezmoiexternal.toml`로 자동 배포

### Linux (linux/)

| 순서 | 스크립트             | 역할                                                                     | 실행 조건             | 상세                                                               |
|:--:|------------------|------------------------------------------------------------------------|-------------------|------------------------------------------------------------------|
| 01 | install-packages | curl, git, vim, zsh, ghostty                                           | 최초 1회, dotfiles 전 | 패키지 관리자를 자동 감지(apt-get → dnf → yum)하여 기초 도구를 설치. 이미 설치된 패키지는 건너뜀 |
| 02 | shell-baseline   | 기본 셸, 로케일, 타임존                                                         | 설정 변경 시           | zsh를 기본 셸로 전환하고 히스토리, 키바인딩 기본값을 설정. 로케일과 타임존 정책도 함께 적용           |
| 03 | git-baseline     | Git 사용자 설정, SSH 기초                                                     | 설정 변경 시           | 템플릿 변수(name, email)로 Git 사용자 정보를 설정하고 SSH 키 생성 기초 환경을 구성         |
| 04 | ai-tools         | claude, codex, oh-my-codex, opencode, oh-my-opencode, openclaw, gemini | 최초 1회             | macOS와 동일한 AI 스택을 최소 구성으로 설치. OpenClaw는 systemd 데몬으로 등록          |
| 05 | system-baseline  | 시스템 기초 설정                                                              | 설정 변경 시           | 기본 에디터, 시스템 경로, 기초 보안 설정 등 OS 수준 기본값 적용                          |

## 설치 흐름

### macOS

```
chezmoi init --apply
│
├─ 01 prerequisites
│   Xcode CLI Tools → Homebrew → zerobrew → Rosetta 2 (Apple Silicon)
│   시스템 패키지 관리 기반 구성. zerobrew가 Homebrew 생태계의 대안 클라이언트로 `zb` 명령 제공
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
├─ 04 runtime
│   Bun (JavaScript/TypeScript 런타임)
│
├─ 10 ai-core
│   Claude Code, Codex CLI, Gemini CLI, Copilot CLI, Auggie CLI, superpowers
│   Claude Code(curl 스크립트), Codex·Gemini·Copilot·Auggie(npm) 설치, superpowers를 ~/superpowers에 clone
│
├─ 11 ai-claude
│   SuperClaude, peon-ping, Augment MCP 등록 (claude mcp add-json)
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
├─ 21 ai-openclaw
│   OpenClaw → launchd 데몬 등록 → claude-mem 연동 (별도 스크립트)
│
├─ dotfiles 배포
│   ~/.zshrc, ~/.gitconfig, ~/.gitignore_global, ~/.vimrc
│   ~/AGENTS.md (공통 에이전트 지침)
│   ~/.config/ghostty/config, ~/.config/opencode/*
│   ~/.claude/settings.json, ~/.claude/hooks/peon-ping/*
│   ~/.codex/config.toml, ~/.codex/AGENTS.md, ~/.codex/prompts/*
│   ~/.agents/skills/*, ~/.copilot/skills/*
│   ~/.openclaw/openclaw.json, ~/.openclaw/workspace/*
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
│   openclaw (systemd 데몬), gemini
│
├─ 05 system-baseline
│   시스템 기초 설정
│
└─ dotfiles 배포
    ~/.zshrc, ~/.gitconfig, ~/.gitignore_global
    ~/AGENTS.md
    ~/.config/ghostty/config, ~/.config/opencode/*
    ~/.claude/*, ~/.codex/*, ~/.agents/*, ~/.copilot/*
    ~/.openclaw/*
```

## 템플릿 변수

`.chezmoi.toml.tmpl`에서 감지 또는 입력받아 모든 `.tmpl` 파일에서 참조한다. 최초 `chezmoi init` 실행 시 대화형으로 수집되며, 이후
`~/.config/chezmoi/chezmoi.toml`에 저장되어 재사용된다.

**사용자 입력 (최초 1회)**

| 변수    | 용도          | 사용처                     |
|-------|-------------|-------------------------|
| name  | Git 사용자 이름  | `.gitconfig`, 커밋 서명     |
| email | Git 사용자 이메일 | `.gitconfig`, SSH 키 코멘트 |

**자동 감지**

| 변수               | Intel Mac    | Apple Silicon Mac | Linux   | 용도                         | 감지 방법                                                 |
|------------------|--------------|-------------------|---------|----------------------------|-------------------------------------------------------|
| `.chezmoi.os`    | `darwin`     | `darwin`          | `linux` | OS 분기                      | chezmoi 내장                                            |
| `.chezmoi.arch`  | `amd64`      | `arm64`           | 다양      | 아키텍처 분기                    | chezmoi 내장                                            |
| `isAppleSilicon` | `false`      | `true`            | `false` | Rosetta 설치, Homebrew 경로 분기 | `arch == arm64 && os == darwin`                       |
| `homebrewPrefix` | `/usr/local` | `/opt/homebrew`   | -       | brew shellenv 경로           | `isAppleSilicon` 기반                                   |
| `hostname`       | scutil 기반    | scutil 기반         | 시스템 기본  | 머신 식별                      | macOS: `scutil --get ComputerName`, Linux: `hostname` |

## Brewfile 패키지

Brewfile은 `zb bundle`(zerobrew) 명령으로 동기화한다. zerobrew 실패 시 `brew bundle`로 폴백한다. 패키지 추가/제거는 Brewfile만 수정하면 다음
`chezmoi apply`에서 자동 반영된다.
AI CLI(Claude Code, Codex, Gemini, Copilot)는 공식 설치 채널 정책에 따라 AI 스크립트에서 각 공식 채널(curl/npm)로 관리하고, Brewfile은 Homebrew 직접 관리
대상만 유지한다.

| 대주제    | 소주제         | 상세 패키지                                                                                                         |
|--------|-------------|----------------------------------------------------------------------------------------------------------------|
| 시스템    | 기본 CLI      | bash, zsh, curl, wget, git, git-lfs, gh, grep, jq, gnupg, pkg-config, shellcheck, terminal-notifier, tree, vim |
| 시스템    | 개발 보조 CLI   | act, awscli, direnv, fswatch, fzf, ripgrep, tmux, watchman                                                     |
| 런타임    | 언어 런타임      | dotnet, go, kotlin, node, openjdk, php, python, ruby, rust                                                     |
| 런타임    | 패키지/가상환경    | composer, npm, pipx, rbenv, uv, xcodes, yarn                                                                   |
| 데이터/도구 | 데이터/유틸      | sqlite                                                                                                         |
| 터미널/앱  | 폰트          | font-jetbrains-mono                                                                                            |
| 터미널/앱  | 터미널         | ghostty                                                                                                        |
| 터미널/앱  | 개발 앱 (cask) | docker, figma, flutter, gcloud-cli, github, iterm2, postman, proxyman, visual-studio-code                      |
| 터미널/앱  | 일반 앱 (cask) | appcleaner, google-chrome, iina, keka, rectangle, slack, stats, zoom                                           |

**AI CLI 설치 채널 (공식 문서 확인 기준)**

| 도구       | 분류 | 공식 설치 채널                                                    | 기본 운영 채널 |
|----------|----|-------------------------------------------------------------|----------|
| Claude   | 공식 | 공식 스크립트 (`curl -fsSL https://claude.ai/install.sh \| bash`) | curl     |
| Codex    | 공식 | npm (`npm install -g @openai/codex`)                        | npm      |
| Gemini   | 공식 | npm (`npm install -g @google/gemini-cli`)                   | npm      |
| Copilot  | 공식 | npm (`npm install -g @github/copilot`)                      | npm      |
| OpenCode | 외부 | npm (`npm install -g opencode-ai`)                          | npm      |
| OpenClaw | 외부 | npm (`npm install -g openclaw@latest`)                      | npm      |

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

## macOS 시스템 설정

`run_onchange_`로 관리하여, 스크립트 내용을 수정하면 다음 `chezmoi apply`에서 자동 재적용된다. 모든 설정은 `defaults write` 명령으로 적용하며, 일부 설정은 관련 프로세스
재시작(`killall`)이 필요하다.

| 영역         | 설정                                           | 효과                          |
|------------|----------------------------------------------|-----------------------------|
| Dock       | 자동 숨김, 확대 효과, 아이콘 크기 48, 최근 항목 숨김            | 화면 공간 확보, 일관된 Dock 크기 유지    |
| Finder     | 경로 바, 상태 바, 확장자 항상 표시, 확장자 변경 경고 끔           | 파일 위치와 종류를 항상 확인 가능         |
| Keyboard   | 빠른 키 반복, 짧은 반복 지연, press-and-hold 끔, 자동 교정 끔 | 개발 환경에 최적화된 키 입력 속도와 정확성    |
| Trackpad   | 탭으로 클릭                                       | 물리적 클릭 없이 탭으로 클릭 동작         |
| Screenshot | 저장 위치 Desktop, PNG 형식, 창 그림자 제거              | 스크린샷 파일 관리 일관성, 불필요한 그림자 제거 |

## Linux 기초 설정

| 영역  | 설정                           | 상세                                                        |
|-----|------------------------------|-----------------------------------------------------------|
| 패키지 | curl, git, vim, zsh, ghostty | 패키지 관리자를 자동 감지(apt-get → dnf → yum)하여 설치. 이미 설치된 패키지는 건너뜀 |
| 셸   | 기본 셸 zsh 전환, 히스토리, 키바인딩      | `chsh`로 기본 셸을 zsh로 변경하고 히스토리 크기, 키바인딩 기본값 설정              |
| Git | 사용자 설정, SSH 기초 설정            | 템플릿 변수(name, email) 기반 Git 사용자 설정과 SSH 키 생성 환경 구성         |
| 로케일 | 기본 로케일, 타임존 정책               | 시스템 로케일과 타임존을 일관된 기본값으로 설정                                |

## 터미널

Ghostty 설정은 `dot_config/ghostty/config.tmpl`로 관리한다. XDG 경로(`~/.config/ghostty/`)를 사용하며, 배포되는 파일명은 `config` (확장자 없음)이다.
Ghostty는 이 단일 파일에서 모든 설정을 읽는다.

설정 형식은 `key = value`이며, 주석은 `#`으로 시작한다(인라인 주석 불가, 별도 줄에서만 사용). Ghostty는 설정 파일 변경 시 수동 리로드를 지원한다(macOS: `Cmd+Shift+,`,
Linux: `Ctrl+Shift+,`). 자동 파일 감시는 제공하지 않으며, 일부 설정은 터미널 재시작이 필요하다.

| 영역    | 설정 항목                                                                   | 상세                                          |
|-------|-------------------------------------------------------------------------|---------------------------------------------|
| 폰트    | font-family, font-size                                                  | 코딩용 폰트와 크기. 시스템 폰트 목록에서 자동 탐색               |
| 테마    | theme, background, foreground, cursor-color                             | 전체 색상 테마. 내장 테마 이름 또는 개별 색상 지정              |
| 창     | window-padding-x, window-padding-y, background-opacity, background-blur | 텍스트와 창 테두리 사이 여백, 배경 투명도, 블러 효과             |
| 셸     | shell-integration, scrollback-limit                                     | 셸 통합(프롬프트 감지, 명령 완료 마커), 스크롤백 버퍼 크기         |
| 키바인딩  | keybind                                                                 | 커스텀 키 바인딩. Ghostty 고유 형식으로 정의               |
| macOS | macos-titlebar-style, macos-option-as-alt                               | macOS 전용 타이틀바 스타일(숨김/투명), Option 키를 Alt로 매핑 |

Ghostty는 macOS에서 Homebrew cask(`brew install --cask ghostty`), Linux에서 배포판 패키지 관리자로 설치한다.

## AI 도구 설정

### 공통 원칙

- **인증 정보 보안**: 인증 정보는 사용자 홈 범위의 보안 저장소(환경 변수, OS 키체인)에 유지한다. 설정 파일에 API 키나 토큰을 직접 기재하지 않는다.
- **기본 제한 정책**: 워크스페이스 권한은 기본 제한 정책에서 시작한다. 필요한 권한만 명시적으로 허용하여, 의도하지 않은 파일 수정이나 시스템 변경을 방지한다.
- **템플릿 관리**: 모든 설정 파일은 `.tmpl`로 관리하여 OS, 아키텍처, 사용자 정보에 따른 환경별 분기가 가능하다.
- **세션 간 컨텍스트**: claude-mem (`~/.claude-mem/`)을 통해 세션 간 메모리를 지속한다. 이전 세션의 중요한 결정, 패턴, 컨텍스트가 새 세션에서 자동으로 참조된다.
- **멀티 에이전트 알림**: peon-ping의 CESP 어댑터를 통해 Claude, Codex, OpenCode, OpenClaw 등 모든 AI 도구의 이벤트 알림을 하나의 사운드 팩으로 통합한다.

### 모듈화 기준

- 코어 설치(10)에서 공식 AI CLI 4종을 설치하고, 프로바이더별 확장 스크립트(11~14)에서 MCP, 스킬, 플러그인을 독립 관리한다.
- 공식 AI CLI(10번대)와 외부 오픈소스 도구(20번대)를 번호 대역으로 구분한다.
- 서비스별 설정 파일(`settings.json`, `config.toml` 등)과 실행 스크립트(`ai-claude.sh`, `ai-codex.sh` 등)를 분리한다.
- 인증, 프로필, 권한, 확장(플러그인/스킬) 항목을 독립적으로 관리하여, 하나의 변경이 다른 항목에 영향을 주지 않는다.
- AI 설정 변경이 단일 모듈에 국한되도록 구성하여, 변경 범위를 예측할 수 있다.

### 스킬 배포

공통 스킬을 각 도구의 글로벌 스킬 경로에 배포한다. 스킬 형식은 SKILL.md 기반으로 도구에 무관하게 동일하다.

| 도구             | 글로벌 스킬 경로                                                              | 프로젝트 스킬 경로                                                | 배포 방식                                     |
|----------------|------------------------------------------------------------------------|-----------------------------------------------------------|-------------------------------------------|
| Claude Code    | `~/.claude/skills/`                                                    | `.claude/skills/`                                         | `.chezmoiexternal.toml`로 humanizer 자동 동기화 |
| Codex          | `~/.agents/skills/`                                                    | `.agents/skills/`                                         | `.chezmoiexternal.toml`로 humanizer 자동 동기화 |
| Gemini         | `~/.gemini/skills/`                                                    | -                                                         | ai-gemini 스크립트에서 superpowers copy         |
| GitHub Copilot | `~/.copilot/skills/`                                                   | `.github/skills/`, `.claude/skills/`                      | ai-copilot 스크립트에서 superpowers copy        |
| OpenCode       | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` | ai-opencode 스크립트에서 superpowers copy       |

**스킬 소스**:

- **humanizer**: AI 글쓰기 패턴 제거 스킬. AI 특유의 과도한 수식어, 반복 구조, 형식적 표현을 자연스러운 문장으로 교정한다. Claude와 Codex는 `.chezmoiexternal.toml`
  로 자동 배포된다.
- **superpowers**: 브레인스토밍, TDD, 코드 리뷰, 서브에이전트 기반 개발 등 12종+ 스킬. ai-core(10)에서 ~/superpowers에 한 번 clone하고,
  Codex/Gemini/Copilot/OpenCode 각 프로바이더 스크립트에서 도구별 스킬 경로로 복사하여 개별 커스텀 가능. Claude는 플러그인 마켓플레이스로 설치.
- **andrej-karpathy-skills**: 코딩 행동 지침 4대 원칙. Claude에서는 플러그인 마켓플레이스로 설치하고, Codex에서는 config.toml의 모델 지침으로 적용한다.

### AGENTS.md

`AGENTS.md.tmpl`은 두 곳에 배포된다:

| 배포 위치     | 대상 경로                | 참조 도구                     | 적용 범위                    |
|-----------|----------------------|---------------------------|--------------------------|
| 홈 루트      | `~/AGENTS.md`        | Codex, OpenCode, OpenClaw | 프로젝트(홈 디렉토리) 수준 공통 지침    |
| Codex 글로벌 | `~/.codex/AGENTS.md` | Codex                     | 모든 Codex 세션에 적용되는 글로벌 지침 |

**계층 우선순위**: 하위 경로의 AGENTS.md가 상위를 override한다. Codex와 OpenCode가 실제로 따르는 탐색 순서:

| 우선순위 | 범위      | 경로 예시                | 역할                          |
|:----:|---------|----------------------|-----------------------------|
|  1   | 하위 디렉토리 | `src/api/AGENTS.md`  | 특정 도메인 전용 지침 (최우선 override) |
|  2   | 저장소 루트  | `./AGENTS.md`        | 프로젝트 공통 지침                  |
|  3   | 사용자 홈   | `~/AGENTS.md`        | 사용자 전역 기본 지침                |
|  4   | 도구 글로벌  | `~/.codex/AGENTS.md` | 도구 전용 글로벌 지침 (Codex만 해당)    |

**포함 내용**:

| 항목                    | 출처                                 | 상세                               |
|-----------------------|------------------------------------|----------------------------------|
| Think Before Coding   | andrej-karpathy-skills (CLAUDE.md) | 코드를 작성하기 전에 전체 맥락을 이해하고 계획을 수립   |
| Simplicity First      | andrej-karpathy-skills (CLAUDE.md) | 가장 단순한 해결책을 우선 선택하고 불필요한 복잡성을 회피 |
| Surgical Changes      | andrej-karpathy-skills (CLAUDE.md) | 변경 범위를 최소화하고 관련 없는 코드를 수정하지 않음   |
| Goal-Driven Execution | andrej-karpathy-skills (CLAUDE.md) | 사용자의 목표에 집중하여 불필요한 확장을 방지        |
| 도구 공통 운영 규칙           | 프로젝트 공통 정의                         | 각 AI 도구에서 공유하는 작업 규칙과 출력 형식      |

### Claude Code

**설치 (스크립트)**

| 스크립트         | 내용                                      | 설치 대상                 |
|--------------|-----------------------------------------|-----------------------|
| 10-ai-core   | Claude Code (공식 설치 스크립트)                | Claude Code CLI 바이너리  |
| 11-ai-claude | SuperClaude (pipx), peon-ping (설치 스크립트) | CLI 확장 프레임워크 + 알림 사운드 |

**설정 (dot_claude/ → ~/.claude/)**

| 파일                               | 배포 경로                                   | 역할               | 상세                                                                                                    |
|----------------------------------|-----------------------------------------|------------------|-------------------------------------------------------------------------------------------------------|
| settings.json.tmpl               | `~/.claude/settings.json`               | 핵심 설정            | 권한 정책(승인 기반 실행), 기본 모델 설정, 훅 등록, 활성화된 플러그인 목록(`enabledPlugins` 필드). Claude Code의 모든 동작을 제어하는 단일 설정 파일 |
| hooks/peon-ping/config.json.tmpl | `~/.claude/hooks/peon-ping/config.json` | peon-ping 사운드 설정 | 사용할 사운드 팩, CESP 카테고리별 사운드 매핑, 볼륨 설정. Claude Code 훅 디렉토리 내에 위치하여 Claude가 직접 관리                         |

**추가 사용자 경로** (chezmoi 관리 대상이 아닌 Claude Code 네이티브 경로):

| 경로                    | 역할              | 상세                                                         |
|-----------------------|-----------------|------------------------------------------------------------|
| `~/.claude/commands/` | 글로벌 커스텀 슬래시 커맨드 | 마크다운 파일로 정의하는 사용자 커스텀 슬래시 커맨드. `/help`에서 목록 확인 가능          |
| `~/.claude/agents/`   | 글로벌 커스텀 서브에이전트  | YAML frontmatter가 포함된 마크다운 파일로 정의하는 서브에이전트. 오케스트레이터가 자동 생성 |

**MCP 설정 위치**: 사용자 범위는 `~/.claude.json`, 프로젝트 범위는 `.mcp.json`을 사용한다. `~/.claude/` 디렉토리 내부가 아닌 **홈 디렉토리 루트**에 위치하는 점에
주의. `~/.claude.json`은 Claude Code가 런타임에 직접 관리하며(`.chezmoiignore`로 chezmoi 배포 제외), `.mcp.json`은 프로젝트별 MCP 서버를 선언한다.

**플러그인**

Claude Code 플러그인은 `settings.json`의 `enabledPlugins` 필드에 등록된다. 플러그인 전용 `plugins.json`/`hud.json` 파일은 사용하지 않으며, MCP는
`~/.claude.json`(사용자)과 `.mcp.json`(프로젝트)으로 관리한다.

| 플러그인                   | 역할            | 설치 방식       | 상세                                                                                                                                                                                 |
|------------------------|---------------|-------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| superpowers            | 구조화된 워크플로우    | 플러그인 마켓플레이스 | 브레인스토밍, TDD, 코드 리뷰, 서브에이전트 기반 개발 등 12종+ 스킬을 제공. 코드 작성 전 계획 수립, 검증 후 완료 선언 등 체계적 개발 프로세스를 강제                                                                                        |
| claude-hud             | 상태 표시줄        | 플러그인 마켓플레이스 | 컨텍스트 사용량, 현재 모델, Git 상태, 활성 도구, 에이전트, 진행률을 터미널 하단에 실시간 표시. 기본 statusline으로 설정. 설정은 자동 생성됨 (`~/.claude/plugins/claude-hud/config.json`)                                             |
| peon-ping              | 멀티 에이전트 음성 알림 | 설치 스크립트     | CESP(Coding Event Sound Pack Specification) 표준 기반. `sc_marine`, `sc_scv` 사운드 팩을 기본 설치. 작업 완료, 권한 요청, 오류 발생 등 이벤트를 음성으로 알려주어 멀티태스킹 효율 향상. Claude Code 네이티브 훅 + 8종 어댑터로 다양한 AI 도구 지원 |
| andrej-karpathy-skills | 코딩 행동 지침      | 플러그인 마켓플레이스 | Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution 4대 원칙을 Claude Code 세션에 자동 주입하여 코드 품질 기준선 유지                                                         |
| claude-mem             | 세션 간 메모리 지속   | 플러그인 마켓플레이스 | 데이터를 `~/.claude-mem/`에 저장하고, AI 기반 압축으로 컨텍스트 효율을 유지. MCP 검색 5종을 지원하여 과거 세션의 결정사항, 패턴, 컨텍스트를 현재 세션에서 참조 가능                                                                          |

**훅**

peon-ping과 claude-mem이 제공하는 훅은 settings.json에 등록되어 Claude Code의 생명주기 이벤트에 반응한다.

| 제공         | 이벤트                | 동작          | 상세                                                      |
|------------|--------------------|-------------|---------------------------------------------------------|
| peon-ping  | SessionStart       | 인사 음성 재생    | Claude Code 세션 시작 시 사운드 팩의 인사 사운드를 재생하여 세션 시작을 청각적으로 알림 |
| peon-ping  | UserPromptSubmit   | 과다 입력 감지    | 사용자 프롬프트 제출 시 입력 길이를 확인하여 과도하게 긴 입력에 대한 경고 사운드 재생       |
| peon-ping  | Stop               | 작업 완료 음성 재생 | 에이전트가 작업을 완료하면 완료 사운드를 재생하여 결과를 확인하도록 유도                |
| peon-ping  | PermissionRequest  | 권한 요청 음성 재생 | 에이전트가 사용자 승인이 필요한 작업을 요청할 때 사운드로 알림                     |
| peon-ping  | Notification       | 데스크톱 알림     | 데스크톱 알림과 터미널 탭 타이틀 업데이트를 통해 백그라운드에서도 이벤트 감지 가능          |
| peon-ping  | SessionEnd         | 세션 종료 알림    | 세션 종료 시 종료 사운드를 재생                                      |
| peon-ping  | PostToolUseFailure | 도구 실패 알림    | Bash 도구 실행 실패 시 오류 사운드를 재생하여 즉시 인지 가능                   |
| peon-ping  | PreCompact         | 컨텍스트 압축 알림  | 컨텍스트 압축 직전에 알림 사운드를 재생                                  |
| claude-mem | Setup              | 초기 설정 확인    | 플러그인 초기 설정 상태를 확인하고 필요한 디렉토리와 설정 파일을 자동 생성              |
| claude-mem | SessionStart       | 관련 컨텍스트 주입  | 세션 시작 시 과거 세션의 관련 메모리를 검색하여 현재 작업 컨텍스트에 자동 주입           |
| claude-mem | UserPromptSubmit   | 사용자 입력 관찰   | 사용자의 프롬프트를 관찰하여 중요한 의도와 패턴을 메모리에 기록할 후보로 식별             |
| claude-mem | PostToolUse        | 도구 사용 관찰 기록 | 도구 사용 결과를 관찰하여 중요한 결정사항과 변경 이력을 메모리에 기록                 |
| claude-mem | Stop               | 메모리 처리      | 세션 중 수집된 관찰 데이터를 처리하여 영구 메모리로 저장                        |

**MCP 서버**

`~/.claude.json`은 Claude Code가 런타임에 직접 관리하며, `claude mcp add-json` 명령으로 MCP 서버를 등록한다. ai-claude(11) 스크립트가 초기 설정 시 자동 등록.

| 서버                      | 역할             | 상세                                                                                              |
|-------------------------|----------------|-------------------------------------------------------------------------------------------------|
| context7                | 라이브러리 공식 문서 조회 | resolve-library-id로 라이브러리를 식별한 뒤 get-library-docs로 공식 문서와 코드 예제를 검색. 외부 라이브러리 사용 시 최신 공식 패턴을 참조 |
| sequential-thinking     | 체계적 다단계 분석     | 복잡한 문제를 구조화된 사고 단계로 분해하여 분석. 디버깅, 아키텍처 설계, 코드 리뷰 등 다단계 추론이 필요한 작업에 활용                           |
| augment-context-engine  | 코드베이스 전체 컨텍스트  | Augment Context Engine MCP. 코드베이스의 아키텍처, 의존성, 변경 이력을 포함한 심층 시맨틱 이해를 제공. `auggie --mcp --mcp-auto-workspace`로 실행 |

### Codex

**설치 (스크립트)**

| 스크립트        | 내용                                                             | 설치 대상             |
|-------------|----------------------------------------------------------------|-------------------|
| 10-ai-core  | Codex CLI (npm)                                                | Codex CLI 바이너리    |
| 12-ai-codex | oh-my-codex (npm), superpowers (~/superpowers에서 copy), 프로필 초기화 | Codex 확장 환경 전체 구성 |

**설정 (dot_codex/ → ~/.codex/)**

| 파일               | 배포 경로                  | 역할               | 상세                                                                                                                                                     |
|------------------|------------------------|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------|
| config.toml.tmpl | `~/.codex/config.toml` | 핵심 설정            | 기본 모델, 프로필 정의(`[profiles.<name>]` 섹션), 기본 프롬프트, MCP 서버 설정을 단일 파일에서 관리. 프로필과 권한 설정도 이 파일 내에서 처리하며, 별도의 `permissions.toml`이나 `profiles.toml` 파일은 존재하지 않음 |
| AGENTS.md.tmpl   | `~/.codex/AGENTS.md`   | 글로벌 에이전트 지침      | 모든 Codex 세션에 적용되는 글로벌 에이전트 지침. `~/AGENTS.md`와 별도로, Codex 전용 글로벌 규칙을 정의                                                                                 |
| prompts/         | `~/.codex/prompts/`    | oh-my-codex 프롬프트 | oh-my-codex가 제공하는 에이전트별 프롬프트 파일을 배포                                                                                                                    |

**oh-my-codex 주요 기능**

| 기능        | 내용                                           | 상세                                                              |
|-----------|----------------------------------------------|-----------------------------------------------------------------|
| 에이전트 프롬프트 | architect, planner, executor, debugger 등 30종 | 작업 유형별로 최적화된 시스템 프롬프트를 제공하여 에이전트의 역할과 행동을 정의                    |
| 워크플로우 스킬  | plan, team, autopilot, ultrawork 등 40종       | 복잡한 작업을 단계별로 처리하는 사전 정의된 워크플로우. 자동화 수준과 사용자 개입 정도를 선택 가능        |
| 팀 모드      | tmux 기반 병렬 워커 세션                             | 하나의 터미널에서 여러 Codex 워커를 tmux 세션으로 병렬 실행하여 대규모 작업을 분산 처리          |
| MCP 서버    | 상태, 메모리, 코드 인텔리전스, 트레이싱 4종                   | oh-my-codex가 자체 제공하는 MCP 서버로 작업 상태 추적, 메모리 관리, 코드 분석, 실행 추적을 지원 |

superpowers도 Codex에 설치된다 (~/superpowers에서 copy). karpathy 지침은 config.toml의 모델 지침으로 적용한다.

**MCP 서버** (`~/.codex/config.toml`의 `[mcp_servers.*]`에서 선언적 관리)

| 서버                      | 역할               | 상세                                                                                              |
|-------------------------|------------------|-------------------------------------------------------------------------------------------------|
| openai_developer_docs   | OpenAI 공식 문서 조회  | MCP Remote를 통해 OpenAI 개발자 문서에 접근                                                                |
| context7                | 라이브러리 공식 문서 조회   | resolve-library-id로 라이브러리를 식별한 뒤 get-library-docs로 공식 문서와 코드 예제를 검색                               |
| augment-context-engine  | 코드베이스 전체 컨텍스트    | Augment Context Engine MCP. `auggie --mcp --mcp-auto-workspace`로 실행                             |

### OpenCode

**설치 (스크립트)**

| 스크립트           | 내용                                                                       | 설치 대상                |
|----------------|--------------------------------------------------------------------------|----------------------|
| 20-ai-opencode | OpenCode (npm), oh-my-opencode (npm), superpowers (~/superpowers에서 copy) | OpenCode 바이너리와 확장 기능 |

**설정 (dot_config/opencode/ → ~/.config/opencode/)**

| 파일                        | 배포 경로                                     | 역할    | 상세                                                           |
|---------------------------|-------------------------------------------|-------|--------------------------------------------------------------|
| opencode.json.tmpl        | `~/.config/opencode/opencode.json`        | 핵심 설정 | AI 프로바이더, 권한 정책, 에이전트 설정, MCP 서버 목록을 정의                      |
| oh-my-opencode.jsonc.tmpl | `~/.config/opencode/oh-my-opencode.jsonc` | 확장 설정 | oh-my-opencode의 에이전트 오버라이드, 훅, 카테고리 설정. JSONC(주석 허용 JSON) 형식 |
| plugins/                  | `~/.config/opencode/plugins/`             | 플러그인  | superpowers 등 OpenCode 플러그인 배포                               |
| skills/                   | `~/.config/opencode/skills/`              | 스킬    | OpenCode 전용 스킬과 공유 스킬을 이 경로에 배포                              |

**oh-my-opencode 주요 기능**

| 기능           | 내용                         | 상세                                                                                                 |
|--------------|----------------------------|----------------------------------------------------------------------------------------------------|
| 멀티 모델 에이전트   | 작업별 최적 모델 자동 배정 (11종 에이전트) | 코드 작성, 리뷰, 디버깅, 문서화 등 작업 유형에 따라 최적의 AI 모델을 자동으로 선택하여 배정                                            |
| 백그라운드 에이전트   | 병렬 에이전트 동시 실행              | 여러 에이전트를 동시에 실행하여 독립적인 작업을 병렬로 처리. 복잡한 프로젝트에서 처리 속도를 향상                                            |
| 내장 훅         | Todo 강제 완료, 주석 검사 등 41종    | 코드 품질을 자동으로 검증하는 훅(32 core + 7 continuation + 2 skill). Todo 항목 완료 강제, 코드 주석 품질 검사, 보안 패턴 감지 등을 수행 |
| MCP          | Context7, exa, grep.app    | 외부 문서 검색(Context7), 웹 검색(exa), 코드 검색(grep.app)을 MCP 서버로 통합                                         |
| LSP/AST-Grep | 결정론적 리팩토링 도구               | 언어 서버 프로토콜(LSP)과 AST 기반 코드 검색(AST-Grep)을 활용하여 정확한 코드 리팩토링을 수행. AI 추론이 아닌 구문 분석 기반으로 동작             |

superpowers도 OpenCode에 설치된다 (~/superpowers에서 copy).

**MCP 서버** (`~/.config/opencode/opencode.json`에서 선언적 관리)

| 서버                      | 설정 키         | 역할             | 상세                                                                                              |
|-------------------------|--------------|----------------|-------------------------------------------------------------------------------------------------|
| context7                | `mcpServers` | 라이브러리 공식 문서 조회 | resolve-library-id로 라이브러리를 식별한 뒤 get-library-docs로 공식 문서와 코드 예제를 검색                               |
| augment-context-engine  | `mcp`        | 코드베이스 전체 컨텍스트  | Augment Context Engine MCP. `type: "local"`, `command: ["auggie", "--mcp", "--mcp-auto-workspace"]`로 설정 |

OpenCode는 프로젝트/글로벌 모두에서 `.opencode/skills/` 외에 `.claude/skills/`와 `.agents/skills/`도 자동 탐색한다. 별도 설정 없이 Claude, Codex와
동일한 스킬을 자동으로 인식한다.

### OpenClaw

**설치 (스크립트)**

| 스크립트           | 내용                                                     | 설치 대상                     |
|----------------|--------------------------------------------------------|---------------------------|
| 21-ai-openclaw | OpenClaw (npm), 데몬 등록 (launchd/systemd), claude-mem 연동 | OpenClaw 바이너리, 데몬, 메모리 연동 |

**설정 (dot_openclaw/ → ~/.openclaw/)**

| 파일                 | 배포 경로                       | 역할          | 상세                                                                                                                             |
|--------------------|-----------------------------|-------------|--------------------------------------------------------------------------------------------------------------------------------|
| openclaw.json.tmpl | `~/.openclaw/openclaw.json` | 핵심 설정       | AI 모델, 메시징 채널, 게이트웨이, 보안 정책을 정의                                                                                                |
| extensions/        | `~/.openclaw/extensions/`   | 플러그인 확장     | `openclaw plugins install`로 설치한 플러그인이 저장되는 경로. 각 플러그인은 `openclaw.plugin.json` manifest를 포함                                     |
| workspace/         | `~/.openclaw/workspace/`    | 행동/성격/도구 정의 | AGENTS.md(행동 지침), SOUL.md(성격 정의), TOOLS.md(도구 접근 정책)를 chezmoi로 관리. USER.md, IDENTITY.md, HEARTBEAT.md는 OpenClaw가 초기 실행 시 자동 생성 |

OpenClaw는 코딩 도구가 아닌 **개인 AI 어시스턴트 플랫폼**이다. 메시징 채널(WhatsApp, Telegram, Slack, Discord 등)을 통해 AI 에이전트와 대화하며, 음성 인식과 Talk
Mode(ElevenLabs)도 지원한다. macOS에서는 launchd, Linux에서는 systemd 데몬으로 상시 실행된다.

claude-mem 연동은 별도 설치 스크립트(`thedotmack/claude-mem/install/openclaw.sh`)로 처리한다. OpenClaw는 플러그인 시스템을 지원하며, 설치된 플러그인은
`~/.openclaw/extensions/<plugin-id>/`에 위치하고 `openclaw.plugin.json` manifest를 사용한다. 스킬은 ClawHub 기반으로 별도 확장할 수 있다.
OpenClaw는 업데이트가 빠른 편이므로 적용 전에 반드시 `https://docs.openclaw.ai`의 최신 설치/설정 문서를 재확인한다.

**주요 기능**

| 기능         | 내용                                   | 상세                                               |
|------------|--------------------------------------|--------------------------------------------------|
| 멀티 채널      | WhatsApp, Telegram, Slack, Discord 등 | 다양한 메시징 플랫폼에서 동일한 AI 에이전트에 접근                    |
| 음성         | 음성 인식, Talk Mode (ElevenLabs)        | 텍스트 외에 음성으로도 AI와 대화. ElevenLabs TTS로 자연스러운 음성 응답 |
| claude-mem | 세션 간 메모리 지속                          | Claude Code와 동일한 claude-mem을 연동하여 크로스 플랫폼 메모리 공유 |
| 데몬         | macOS launchd, Linux systemd 자동 등록   | 사용자가 명시적으로 실행하지 않아도 항상 백그라운드에서 동작                |

### Gemini

**설치 (스크립트)**

| 스크립트         | 내용                                                     | 설치 대상               |
|--------------|--------------------------------------------------------|---------------------|
| 10-ai-core   | Gemini CLI (npm)                                       | Gemini CLI 바이너리     |
| 13-ai-gemini | SuperGemini (pipx), superpowers (~/superpowers에서 copy) | Gemini CLI 확장 프레임워크 |

SuperGemini는 Gemini CLI의 확장 프레임워크로, 슬래시 명령어와 AI 에이전트 페르소나를 제공한다. superpowers는 ~/superpowers에서 ~
/.gemini/skills/superpowers로 복사된다.

**MCP 서버** (`~/.gemini/settings.json`의 `mcpServers`에서 선언적 관리)

| 서버                      | 역할             | 상세                                                                                              |
|-------------------------|----------------|-------------------------------------------------------------------------------------------------|
| context7                | 라이브러리 공식 문서 조회 | resolve-library-id로 라이브러리를 식별한 뒤 get-library-docs로 공식 문서와 코드 예제를 검색                               |
| sequential-thinking     | 체계적 다단계 분석     | 복잡한 문제를 구조화된 사고 단계로 분해하여 분석                                                                     |
| augment-context-engine  | 코드베이스 전체 컨텍스트  | Augment Context Engine MCP. `auggie --mcp --mcp-auto-workspace`로 실행                             |

### Copilot

**설치 (스크립트)**

| 스크립트          | 내용                                 | 설치 대상            |
|---------------|------------------------------------|------------------|
| 10-ai-core    | Copilot CLI (npm)                  | Copilot CLI 바이너리 |
| 14-ai-copilot | superpowers (~/superpowers에서 copy) | Copilot 확장 환경 구성 |

**설정 (dot_copilot/ → ~/.copilot/)**

| 파일                    | 배포 경로                         | 역할      | 상세                                                       |
|-----------------------|-------------------------------|---------|----------------------------------------------------------|
| mcp-config.json.tmpl  | `~/.copilot/mcp-config.json`  | MCP 설정  | MCP 서버 목록을 선언적으로 관리                                       |
| skills/               | `~/.copilot/skills/`          | 글로벌 스킬  | superpowers 스킬을 배포. 각 스킬은 `<skill-name>/SKILL.md` 형태로 구성 |

**MCP 서버** (`~/.copilot/mcp-config.json`의 `mcpServers`에서 선언적 관리)

| 서버                      | 역할             | 상세                                                                                              |
|-------------------------|----------------|-------------------------------------------------------------------------------------------------|
| context7                | 라이브러리 공식 문서 조회 | resolve-library-id로 라이브러리를 식별한 뒤 get-library-docs로 공식 문서와 코드 예제를 검색                               |
| sequential-thinking     | 체계적 다단계 분석     | 복잡한 문제를 구조화된 사고 단계로 분해하여 분석                                                                     |
| augment-context-engine  | 코드베이스 전체 컨텍스트  | Augment Context Engine MCP. `auggie --mcp --mcp-auto-workspace`로 실행                             |

Copilot 스킬 경로:

- **글로벌**: `~/.copilot/skills/<skill-name>/SKILL.md` — 모든 프로젝트에서 참조
- **프로젝트**: `.github/skills/<skill-name>/SKILL.md` 또는 `.claude/skills/<skill-name>/SKILL.md` — 해당 프로젝트에서만 참조

## peon-ping 연동

peon-ping은 CESP(Coding Event Sound Pack Specification) 표준을 기반으로 하는 멀티 에이전트 음성 알림 시스템이다. Claude Code는 네이티브 훅으로 직접 통합되고,
나머지 도구는 어댑터 스크립트가 도구별 이벤트를 CESP 표준 이벤트로 변환한다.

| 도구          | 설정 경로                                      | 연동 방식                                         |
|-------------|--------------------------------------------|-----------------------------------------------|
| Claude Code | `~/.claude/hooks/peon-ping/config.json`    | 네이티브 훅으로 직접 통합 (`peon.sh`를 settings.json에 등록) |
| Codex       | 어댑터 스크립트 (`adapters/codex.sh`)             | Codex 이벤트를 셸 스크립트로 캡처하여 peon-ping에 전달         |
| OpenCode    | `~/.config/opencode/peon-ping/config.json` | OpenCode 설정에 직접 통합                            |
| OpenClaw    | 어댑터 스크립트 (`adapters/openclaw.sh`)          | OpenClaw 이벤트를 셸 스크립트로 캡처                      |
| Cursor      | 어댑터 스크립트 (`adapters/cursor.sh`)            | Cursor IDE 이벤트를 셸 스크립트로 캡처                    |
| Kilo CLI    | `~/.config/kilo/peon-ping/config.json`     | Kilo 설정에 직접 통합                                |
| Kiro        | 어댑터 스크립트 (`adapters/kiro.sh`)              | Kiro IDE 이벤트를 셸 스크립트로 캡처                      |
| Windsurf    | 어댑터 스크립트 (`adapters/windsurf.sh`)          | Windsurf IDE 이벤트를 셸 스크립트로 캡처                  |
| Antigravity | 어댑터 스크립트 (`adapters/antigravity.sh`)       | Antigravity IDE 이벤트를 셸 스크립트로 캡처               |

## dotfiles-doctor

설치 완료 후 헬스체크 스크립트. `~/.local/bin/dotfiles-doctor`로 배포되어 `dotfiles-doctor` 명령으로 실행한다. 각 항목의 설치 여부를 확인하고 누락된 항목을 보고한다.

| 검사 카테고리          | 대상                                                                          | 검사 내용                           |
|------------------|-----------------------------------------------------------------------------|---------------------------------|
| System           | macOS/Linux 버전, 아키텍처                                                        | OS 버전과 아키텍처 정보를 표시하여 환경 식별      |
| Shell            | zsh, git, vim, tmux                                                         | 기초 셸 도구의 설치 여부와 버전 확인           |
| Terminal         | ghostty                                                                     | Ghostty 터미널의 설치 여부 확인           |
| Languages        | node, python3, go, rustc, php, ruby                                         | 프로그래밍 언어 런타임의 설치 여부와 버전 확인      |
| Package Managers | brew, zb, pipx, bun                                                         | 패키지 관리자의 설치 여부 확인. zb는 zerobrew |
| AI CLI           | claude, codex, gemini, copilot, opencode, openclaw, auggie                  | AI 도구 CLI의 설치 여부와 버전 확인         |
| AI 플러그인          | superpowers, claude-hud, peon-ping, claude-mem, oh-my-codex, oh-my-opencode | 각 AI 도구의 확장 기능 설치 상태 확인         |
| 스킬 디렉토리          | Claude, Codex, Gemini, Copilot, OpenCode 5개 경로                              | 글로벌 스킬 디렉토리 존재 여부와 내용물 확인       |
| AGENTS.md        | `~/AGENTS.md` 존재 여부                                                         | 공통 에이전트 지침 파일 배포 상태 확인          |
| claude-mem       | `~/.claude-mem/` 디렉토리, `settings.json`                                      | 세션 메모리 데이터 디렉토리와 설정 파일 존재 확인    |
| Dotfiles         | ~/.zshrc, ~/.gitconfig, ~/.vimrc, ~/.oh-my-zsh                              | 핵심 dotfiles의 배포 상태 확인           |
| Config           | ghostty, opencode, claude, codex, copilot, openclaw                         | 각 도구의 설정 디렉토리 존재 여부 확인          |
| MCP              | ~/.claude.json, ~/.codex/config.toml, ~/.gemini/settings.json, ~/.copilot/mcp-config.json, ~/.config/opencode/opencode.json | MCP 서버 설정 파일 존재 여부 확인           |

## 요구사항 요약

| 카테고리           | 항목                                                                                             |
|----------------|------------------------------------------------------------------------------------------------|
| Prerequisites  | Xcode CLI, Homebrew, zerobrew, Rosetta 2 (Apple Silicon)                                       |
| macOS Settings | Dock, Finder, Keyboard, Trackpad, Screenshot                                                   |
| System Tools   | bash, zsh, curl, wget, gh, git, git-lfs, grep, gnupg, shellcheck, terminal-notifier, tree, vim |
| Dev Tools      | act, awscli, direnv, fswatch, fzf, ripgrep, tmux, watchman                                     |
| Terminal       | Ghostty                                                                                        |
| Languages      | dotnet, go, kotlin, node, openjdk, php, python, ruby, rust                                     |
| Pkg Managers   | composer, npm, pipx, rbenv, uv, xcodes, yarn                                                   |
| Runtime        | Bun                                                                                            |
| AI Core        | Claude Code, Codex CLI, Gemini CLI, Copilot CLI, Auggie CLI                                    |
| Claude         | SuperClaude, superpowers, claude-hud, peon-ping, karpathy-skills, claude-mem, MCP 4종           |
| Codex          | oh-my-codex, superpowers (copy), MCP 3종                                                       |
| Gemini         | SuperGemini, superpowers (copy), MCP 3종                                                        |
| Copilot        | superpowers (copy), MCP 3종                                                                     |
| OpenCode       | OpenCode, oh-my-opencode, superpowers (copy), MCP 2종                                          |
| OpenClaw       | OpenClaw, claude-mem 연동                                                                        |
| Skills         | humanizer (Claude, Codex), superpowers (Claude 플러그인 + Codex/Gemini/Copilot/OpenCode copy)      |
| Apps           | ghostty, docker, iterm2, chrome, rectangle, slack, figma 등                                     |
| Shell          | Oh My Zsh + autosuggestions + syntax-highlighting                                              |
| Linux          | curl, git, vim, zsh, ghostty, 셸/Git baseline, claude, codex, opencode, openclaw, gemini, auggie |

## 운영 체크리스트

| 항목                  | 확인 포인트                                                                           |
|---------------------|----------------------------------------------------------------------------------|
| 템플릿 데이터 키 일관성       | `.chezmoi.toml.tmpl`에 정의된 변수가 모든 `.tmpl` 파일에서 동일한 이름으로 참조되는지 확인                  |
| 스크립트 번호 체계 일관성      | darwin/(01~04, 10~14, 20~21, 99), linux/(01~05) 번호가 중복 없이 순서대로 유지되는지 확인          |
| 외부 리소스 선언 파일 최신화    | `.chezmoiexternal.toml`의 URL, 브랜치, 해시가 최신 원격 저장소와 일치하는지 확인                       |
| AI 모듈 경계 준수         | 설치 스크립트는 바이너리 설치만, 설정 파일은 사용자 설정만 담당하는 분리 원칙이 유지되는지 확인                           |
| 스킬 디렉토리 동기화 상태      | Claude, Codex, Gemini, Copilot, OpenCode 5개 글로벌 스킬 경로에 humanizer 스킬이 배포되어 있는지 확인 |
| AGENTS.md 공통 지침 최신화 | `~/AGENTS.md`와 `~/.codex/AGENTS.md`의 4대 원칙과 공통 규칙이 최신 상태인지 확인                    |
| peon-ping 어댑터 등록 상태 | 사용 중인 AI 도구의 peon-ping 어댑터가 올바르게 연결되어 이벤트 알림이 동작하는지 확인                           |
| 플러그인 버전 호환성         | Claude Code, Codex, OpenCode의 플러그인이 현재 도구 버전과 호환되는지 확인                           |
| OpenClaw 데몬 상태      | macOS launchd / Linux systemd에 OpenClaw 데몬이 올바르게 등록되어 동작하는지 확인                   |
| claude-mem 데이터 상태   | `~/.claude-mem/` 디렉토리와 `settings.json`이 존재하고 정상적으로 메모리를 기록하는지 확인                 |
| Linux 기초 설정 누락 여부   | macOS에 추가된 AI 도구가 Linux ai-tools 스크립트에도 반영되어 있는지 확인                              |
| 진단 스크립트 검사 대상 최신화   | dotfiles-doctor가 새로 추가된 도구, 설정 파일, 스킬 경로를 검사 대상에 포함하는지 확인                        |
| 검증 스냅샷 갱신           | 참조 저장소의 구조가 변경되었을 때 검증 커밋 해시를 최신으로 갱신했는지 확인                                      |

## 문서 규칙

- 구조 변경 시 파일 트리를 먼저 갱신하고, 디렉토리 배포 매핑 테이블도 함께 반영한다.
- AI 설정 추가 시 Claude, Codex, Gemini, Copilot, OpenCode, OpenClaw 6개 도구 섹션을 모두 검토한다.
- Linux 항목 추가 시 macOS 항목과 동일 수준으로 명시한다.
- 스킬 추가 시 지원 도구별 글로벌/프로젝트 경로를 함께 명시한다.
- 경로와 설정 파일명은 실제 도구 공식 문서 또는 저장소 기준으로 검증 후 기재한다.
- 검증 스냅샷의 커밋 해시와 기준일을 함께 갱신한다.

## 참고

**chezmoi**

- [chezmoi](https://www.chezmoi.io/)
- [chezmoi 스크립트](https://www.chezmoi.io/user-guide/use-scripts-to-perform-actions/)
- [chezmoi special 파일](https://www.chezmoi.io/reference/special-files/)
- [chezmoi 템플릿 변수](https://www.chezmoi.io/reference/templates/variables/)
- [.chezmoiexternal](https://www.chezmoi.io/user-guide/include-files-from-elsewhere/)
- [.chezmoiroot](https://www.chezmoi.io/user-guide/advanced/customize-your-source-directory/)
- [chezmoi Linux 가이드](https://www.chezmoi.io/user-guide/machines/linux/)
- [twpayne/dotfiles](https://github.com/twpayne/dotfiles)

**AI 도구 공식 문서**

- [Claude Code Settings](https://code.claude.com/docs/en/settings)
- [Claude Code Hooks](https://code.claude.com/docs/en/hooks)
- [Claude Code Skills](https://code.claude.com/docs/en/skills)
- [Claude Code Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)
- [Claude Code Setup](https://docs.claude.com/en/docs/claude-code/setup)
- [Codex Configuration](https://developers.openai.com/codex/config-reference/)
- [Codex Agent Skills](https://developers.openai.com/codex/skills/)
- [Codex AGENTS.md](https://developers.openai.com/codex/guides/agents-md/)
- [Gemini CLI](https://ai.google.dev/gemini-api/docs/gemini-cli)
- [Augment Context Engine MCP](https://docs.augmentcode.com/context-services/mcp/overview)
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line)
- [GitHub Copilot Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Ghostty Configuration](https://ghostty.org/docs/config)

**참조 저장소**

- [zerobrew](https://github.com/lucasgelfond/zerobrew)
- [Ghostty](https://github.com/ghostty-org/ghostty)
- [peon-ping](https://github.com/PeonPing/peon-ping)
- [superpowers](https://github.com/obra/superpowers)
- [claude-hud](https://github.com/jarrodwatts/claude-hud)
- [humanizer](https://github.com/blader/humanizer)
- [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- [OpenCode](https://github.com/anomalyco/opencode)
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
- [oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex)
- [OpenClaw](https://github.com/openclaw/openclaw)
- [claude-mem](https://github.com/thedotmack/claude-mem)
- [OpenClaw Docs](https://docs.openclaw.ai)
- [claude-mem Installation](https://docs.claude-mem.ai/installation)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
- [Augment Context Engine Plugin](https://github.com/augmentcode/context-engine-plugin)
