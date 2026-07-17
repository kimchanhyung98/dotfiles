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
    │   ├── run_once_before_00-skills-ssot-migrate.sh.tmpl   # OS 공통: legacy 스킬 디렉토리 삭제 후 symlink 전환
    │   ├── run_onchange_after_06-mattpocock-skills.sh.tmpl  # OS 공통: mattpocock 스킬 런타임 동기화
    │   ├── run_once_after_90-projects-bootstrap.sh.tmpl     # OS 공통: 최초 적용 시 공개 GitHub 저장소 clone
    │   │
    │   ├── darwin/
    │   │   ├── run_once_before_01-prerequisites.sh.tmpl
    │   │   ├── run_onchange_after_02-macos-settings.sh.tmpl
    │   │   ├── run_onchange_03-brew-packages.sh.tmpl
    │   │   ├── run_onchange_after_05-app-settings.sh.tmpl
    │   │   ├── run_once_05-runtime.sh.tmpl
    │   │   ├── run_onchange_after_07-tokscale-launchd.sh.tmpl
    │   │   ├── run_onchange_after_08-dotfiles-update-launchd.sh.tmpl
    │   │   ├── run_once_10-ai-core.sh.tmpl
    │   │   ├── run_once_11-ai-claude.sh.tmpl
    │   │   ├── run_once_12-ai-codex.sh.tmpl
    │   │   └── run_once_after_99-manual-install.sh.tmpl
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
    │
    ├── dot_config/
    │   ├── bat/
    │   │   └── config
    │   ├── cmux/
    │   │   └── cmux.json.tmpl
    │   ├── ghostty/
    │   │   └── config.tmpl
    │   ├── rectangle/
    │   │   └── RectangleConfig.json
    │   ├── stats/
    │   │   └── Stats.plist
    │   ├── tokscale/
    │   │   └── executable_submit.sh.tmpl
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
    ├── dot_claude/
    │   ├── settings.json.tmpl
    │   └── symlink_skills             # → ~/.skills
    │
    ├── dot_codex/
    │   └── config.toml.tmpl
    │
    ├── dot_copilot/
    │   └── mcp-config.json.tmpl
    │
    ├── dot_agents/
    │   └── symlink_skills             # → ~/.skills
    │
    ├── Library/LaunchAgents/
    │   ├── ai.tokscale.submit.plist.tmpl
    │   └── dev.dotfiles.update.plist.tmpl
    │
    └── dot_local/bin/
        ├── executable_dotfiles-doctor
        ├── executable_dotfiles-update
        ├── executable_mattpocock-skills-sync
        ├── executable_projects-doppler-sync
        └── executable_projects-bootstrap
```

## 배포 매핑

| 소스 (chezmoi)                | 배포 대상                              | 용도                                                |
|-----------------------------|------------------------------------|---------------------------------------------------|
| `AGENTS.md.tmpl`            | `~/AGENTS.md`                      | 공통 에이전트 지침 (홈 루트)                                 |
| `dot_config/bat/`           | `~/.config/bat/`                   | bat(cat 대체 뷰어) 설정                                 |
| `dot_config/cmux/`          | `~/.config/cmux/`                  | cmux 설정 (`cmux.json`, `socketControlMode=allowAll` 자동화 기본값) |
| `dot_config/ghostty/`       | `~/.config/ghostty/`               | Ghostty 터미널 설정                                    |
| `dot_config/rectangle/`     | `~/.config/rectangle/`             | Rectangle 설정 원본. macOS app-settings 스크립트가 앱 import 경로로 복사 |
| `dot_config/stats/`         | `~/.config/stats/`                 | Stats 설정 원본. app-settings 스크립트가 민감한 토큰을 보존하며 import |
| `dot_config/tokscale/`      | `~/.config/tokscale/`              | tokscale submit 래퍼                                  |
| `dot_config/zsh/`           | `~/.config/zsh/`                   | `.zshrc`에서 순차 로드하는 모듈형 Zsh 설정                     |
| `dot_claude/`               | `~/.claude/`                       | Claude Code 설정                                    |
| `dot_codex/`                | `~/.codex/`                        | Codex CLI 설정                                      |
| `dot_copilot/`              | `~/.copilot/`                      | Copilot CLI 사용자 MCP 설정                           |
| `dot_<tool>/symlink_skills` | `~/.<tool>/skills/` → `~/.skills/` | 지원 스킬 경로를 단일 출처로 잇는 symlink (claude·agents)       |
| `Library/LaunchAgents/`     | `~/Library/LaunchAgents/`          | tokscale 3일·dotfiles 매월 1·16일 calendar schedule    |
| `dot_local/bin/`            | `~/.local/bin/`                    | 사용자 스크립트 (doctor, dotfiles update, mattpocock 스킬 동기화) |

## chezmoi special 파일

| 파일                      | 역할                         | 상세                                                                                                                   |
|-------------------------|----------------------------|----------------------------------------------------------------------------------------------------------------------|
| `.chezmoiroot`          | source root 경로 고정 (`home`) | chezmoi가 `home/` 디렉토리를 소스 루트로 인식하게 하여, 저장소 루트의 docs/, install.sh 등이 홈 디렉토리에 배포되지 않도록 격리                              |
| `.chezmoiversion`       | 최소 chezmoi 실행 버전 고정        | 이 dotfiles가 요구하는 chezmoi 최소 버전을 명시하여, 이전 버전의 호환성 문제를 사전 차단                                                           |
| `.chezmoiignore`        | OS별·런타임 경로 제외              | 템플릿 조건문으로 현재 OS에 해당하지 않는 설정 파일을 배포 대상에서 제외. 저장소 메타 파일(README, LICENSE 등)과 Claude Code 런타임 데이터(`.claude.json`)도 공통 제외 |
| `.chezmoiexternal.toml` | 외부 리소스 선언적 동기화             | Oh My Zsh, zsh 플러그인 등을 선언한다. chezmoi가 상태를 읽을 때 cache age가 `refreshPeriod`를 넘으면 다시 받을 수 있으며, 자체 예약 작업은 아니다. |
| `.chezmoiremove`        | 제거 상태를 지속 관리                 | 나열된 target이 없는 상태를 매 apply에서 유지한다. 일회성 삭제 기록이 아니라 계속 제거할 경로에만 사용한다. |

## 템플릿 변수

`.chezmoi.toml.tmpl`에서 감지 또는 입력받아 모든 `.tmpl` 파일에서 참조한다. 최초 `chezmoi init` 실행 시 대화형으로 수집되며, 이후
`~/.config/chezmoi/chezmoi.toml`에 저장되어 재사용된다.

**사용자 입력 (최초 1회, 모두 필수)**

| 변수 | 용도 | 사용처 |
|---|---|---|
| `name` | Git 사용자 이름 | `.gitconfig` |
| `email` | Git 사용자 이메일 | `.gitconfig`, SSH 키 생성 안내 |
| `deviceName` | 머신 식별 이름 | tokscale submit 식별자 |

새 config는 대화형 터미널에서만 만들 수 있고 공백만 입력한 값도 거부한다. 이미 세 값이 저장된 config는 이후 비대화형 `--init`에서도 재사용한다.

**자동 감지**

| 변수               | Intel Mac    | Apple Silicon Mac | Linux   | 용도                         | 감지 방법                                                  |
|------------------|--------------|-------------------|---------|----------------------------|--------------------------------------------------------|
| `.chezmoi.os`    | `darwin`     | `darwin`          | `linux` | OS 분기                      | chezmoi 내장                                             |
| `.chezmoi.arch`  | `amd64`      | `arm64`           | 다양      | 아키텍처 분기                    | chezmoi 내장                                             |
| `isAppleSilicon` | `false`      | `true`            | `false` | Rosetta 설치, Homebrew 경로 분기 | `arch == arm64 && os == darwin`                        |
| `homebrewPrefix` | `/usr/local` | `/opt/homebrew`   | `/usr/local`(미사용) | brew shellenv 경로 | macOS에서 설치된 `brew`가 있으면 `brew --prefix`, 없으면 아키텍처 기본값 |
| `hostname`       | scutil/fallback | scutil/fallback | chezmoi 기본값 | 머신 식별 | macOS에서 `scutil --get LocalHostName` 성공값을 쓰고, 실패하면 `.chezmoi.hostname` |
