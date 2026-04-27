# 디렉토리 구조와 chezmoi

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
    │   │   ├── run_onchange_after_02-macos-settings.sh.tmpl
    │   │   ├── run_onchange_03-brew-packages.sh.tmpl
    │   │   ├── run_onchange_after_04-cmux-settings.sh.tmpl
    │   │   ├── run_once_05-runtime.sh.tmpl
    │   │   ├── run_once_10-ai-core.sh.tmpl
    │   │   ├── run_once_11-ai-claude.sh.tmpl
    │   │   ├── run_once_12-ai-codex.sh.tmpl
    │   │   ├── run_once_13-ai-gemini.sh.tmpl
    │   │   ├── run_once_14-ai-copilot.sh.tmpl
    │   │   ├── run_onchange_15-ai-humanizer-ko.sh.tmpl
    │   │   ├── run_once_20-ai-opencode.sh.tmpl
    │   │   └── run_once_after_99-manual-install.sh.tmpl
    │   │
    │   └── linux/
    │       ├── run_once_before_01-install-packages.sh.tmpl
    │       ├── run_onchange_02-shell-baseline.sh.tmpl
    │       ├── run_onchange_03-git-baseline.sh.tmpl
    │       ├── run_once_04-ai-tools.sh.tmpl
    │       ├── run_onchange_05-system-baseline.sh.tmpl
    │       └── run_onchange_15-ai-humanizer-ko.sh.tmpl
    │
    ├── Brewfile
    ├── dot_zshrc.tmpl
    ├── dot_gitconfig.tmpl
    ├── dot_gitignore_global
    ├── dot_vimrc
    ├── AGENTS.md.tmpl
    │
    ├── dot_config/
    │   ├── bat/
    │   │   └── config
    │   ├── cmux/
    │   │   └── settings.json.tmpl
    │   ├── ghostty/
    │   │   └── config.tmpl
    │   ├── zsh/
    │   │   ├── 00-core.zsh
    │   │   ├── 10-env.zsh
    │   │   ├── 20-path.zsh.tmpl
    │   │   ├── 30-functions.zsh.tmpl
    │   │   ├── 40-completion.zsh
    │   │   ├── 50-plugins.zsh
    │   │   ├── 60-tools.zsh
    │   │   ├── 70-aliases.zsh
    │   │   └── 80-secrets.zsh
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
    │   └── config.toml.tmpl
    │
    ├── dot_agents/
    │   └── skills/
    │
    ├── dot_copilot/
    │   ├── mcp-config.json.tmpl
    │   └── skills/
    │
    ├── dot_gemini/
    │   └── settings.json.tmpl
    │
    └── dot_local/bin/
        └── executable_dotfiles-doctor
```

## 배포 매핑

| 소스 (chezmoi)           | 배포 대상                 | 용도                                      |
|------------------------|-----------------------|-----------------------------------------|
| `AGENTS.md.tmpl`       | `~/AGENTS.md`         | 공통 에이전트 지침 (홈 루트)                       |
| `dot_config/bat/`      | `~/.config/bat/`      | bat(cat 대체 뷰어) 설정                       |
| `dot_config/cmux/`     | `~/.config/cmux/`     | cmux 설정 (`socketControlMode` 등 자동화 기본값) |
| `dot_config/ghostty/`  | `~/.config/ghostty/`  | Ghostty 터미널 설정                          |
| `dot_config/zsh/`      | `~/.config/zsh/`      | `.zshrc`에서 순차 로드하는 모듈형 Zsh 설정           |
| `dot_config/opencode/` | `~/.config/opencode/` | OpenCode + oh-my-opencode 설정            |
| `dot_claude/`          | `~/.claude/`          | Claude Code 설정, 훅                       |
| `dot_codex/`           | `~/.codex/`           | Codex CLI 설정                            |
| `dot_agents/skills/`   | `~/.agents/skills/`   | Codex 글로벌 스킬                            |
| `dot_copilot/`         | `~/.copilot/`         | Copilot MCP 설정, 글로벌 스킬                  |
| `dot_gemini/`          | `~/.gemini/`          | Gemini CLI 설정 (승인 모드, 알림/UI, 훅, MCP 서버) |
| `dot_local/bin/`       | `~/.local/bin/`       | 사용자 스크립트 (dotfiles-doctor)              |

## chezmoi special 파일

| 파일                      | 역할                         | 상세                                                                                                                   |
|-------------------------|----------------------------|----------------------------------------------------------------------------------------------------------------------|
| `.chezmoiroot`          | source root 경로 고정 (`home`) | chezmoi가 `home/` 디렉토리를 소스 루트로 인식하게 하여, 저장소 루트의 docs/, install.sh 등이 홈 디렉토리에 배포되지 않도록 격리                              |
| `.chezmoiversion`       | 최소 chezmoi 실행 버전 고정        | 이 dotfiles가 요구하는 chezmoi 최소 버전을 명시하여, 이전 버전의 호환성 문제를 사전 차단                                                           |
| `.chezmoiignore`        | OS별·런타임 경로 제외              | 템플릿 조건문으로 현재 OS에 해당하지 않는 설정 파일을 배포 대상에서 제외. 저장소 메타 파일(README, LICENSE 등)과 Claude Code 런타임 데이터(`.claude.json`)도 공통 제외 |
| `.chezmoiexternal.toml` | 외부 리소스 선언적 동기화             | Oh My Zsh, zsh 플러그인, humanizer 등 외부 Git 저장소를 선언하여 `chezmoi apply` 시 자동 다운로드/갱신. 갱신 주기를 리소스별로 개별 설정                   |
| `.chezmoiremove`        | 더 이상 필요 없는 파일 제거 대상 관리     | dotfiles에서 관리를 중단한 파일을 나열하여 다음 apply 시 자동 삭제. 설정 파일 이름이 변경되었거나 도구를 제거한 경우 잔여 파일 정리에 활용                               |

## 템플릿 변수

`.chezmoi.toml.tmpl`에서 감지 또는 입력받아 모든 `.tmpl` 파일에서 참조한다. 최초 `chezmoi init` 실행 시 대화형으로 수집되며, 이후
`~/.config/chezmoi/chezmoi.toml`에 저장되어 재사용된다.

**사용자 입력 (최초 1회)**

| 변수    | 용도          | 사용처                     |
|-------|-------------|-------------------------|
| name  | Git 사용자 이름  | `.gitconfig`, 커밋 서명     |
| email | Git 사용자 이메일 | `.gitconfig`, SSH 키 코멘트 |

**자동 감지**

| 변수               | Intel Mac    | Apple Silicon Mac | Linux   | 용도                         | 감지 방법                                                  |
|------------------|--------------|-------------------|---------|----------------------------|--------------------------------------------------------|
| `.chezmoi.os`    | `darwin`     | `darwin`          | `linux` | OS 분기                      | chezmoi 내장                                             |
| `.chezmoi.arch`  | `amd64`      | `arm64`           | 다양      | 아키텍처 분기                    | chezmoi 내장                                             |
| `isAppleSilicon` | `false`      | `true`            | `false` | Rosetta 설치, Homebrew 경로 분기 | `arch == arm64 && os == darwin`                        |
| `homebrewPrefix` | `/usr/local` | `/opt/homebrew`   | -       | brew shellenv 경로           | `isAppleSilicon` 기반                                    |
| `hostname`       | scutil 기반    | scutil 기반         | 시스템 기본  | 머신 식별                      | macOS: `scutil --get LocalHostName`, Linux: `hostname` |
