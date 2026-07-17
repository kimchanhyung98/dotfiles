# 운영

## `dotfiles-doctor`

`~/.local/bin/dotfiles-doctor`는 설치와 managed target 상태를 확인한다. AI CLI 중 Claude와 Codex만 required이며 누락 시 non-zero다. Copilot, CodeGraph, Antigravity, Hermes, 언어 runtime과 확장은 optional로 표시한다. zsh/git/vim과 Claude/Codex 설정·공통 skills 경로 같은 dotfiles 핵심 target은 계속 required다.

| 검사 카테고리          | 대상                                                          | 검사 내용                            |
|------------------|-------------------------------------------------------------|----------------------------------|
| System           | macOS/Linux 버전, 아키텍처                                        | OS 버전과 아키텍처 정보를 표시하여 환경 식별       |
| Shell            | zsh, git, vim, tmux                                         | 기초 셸 도구의 설치 여부와 버전 확인            |
| Terminal         | ghostty                                                     | Ghostty 터미널의 설치 여부 확인            |
| Languages        | node, python3, go, rustc, php, ruby                         | 프로그래밍 언어 런타임의 설치 여부와 버전 확인       |
| Package Managers | brew, zb, pipx, bun                                         | 패키지 관리자의 설치 여부 확인. zb는 zerobrew  |
| AI CLI           | claude, codex, copilot, codegraph, hermes, ollama, antigravity(agy) | 필수 Claude/Codex와 선택 AI CLI 상태 확인 |
| AI 확장            | Claude `enabledPlugins`, `codex@openai-codex`, `remember`, oh-my-codex | 설정 파일에 선언된 Claude 확장과 Codex 확장 프레임워크 확인 |
| 스킬 디렉토리          | `~/.skills` + 도구별 symlink 2개(claude·agents)                 | 단일 출처 존재 여부와 symlink·대상 존재 여부 확인 |
| AGENTS.md        | `~/AGENTS.md` 존재 여부                                         | 공통 에이전트 지침 파일 배포 상태 확인           |
| Dotfiles         | ~/.zshrc, ~/.gitconfig, ~/.vimrc, ~/.oh-my-zsh              | 핵심 dotfiles의 배포 상태 확인            |
| Config           | ghostty, claude, codex, copilot                             | 각 도구의 설정 디렉토리 존재 여부 확인           |
| MCP              | ~/.claude.json                                              | MCP 서버 설정 파일 존재 여부 확인            |

## 요구사항 요약

| 카테고리           | 항목                                                                                                       |
|----------------|----------------------------------------------------------------------------------------------------------|
| Prerequisites  | Xcode CLI, Homebrew, zerobrew, Rosetta 2 (Apple Silicon)                                                 |
| macOS Settings | Dock, Finder, Keyboard, Trackpad, Screenshot                                                             |
| System Tools   | bash, bat, zsh, curl, wget, gh, git, git-lfs, grep, gnupg, shellcheck, terminal-notifier, tree, vim      |
| Dev Tools      | act, awscli, direnv, fswatch, fzf, ripgrep, tmux, watchman, zoxide                                       |
| Terminal       | Ghostty                                                                                                  |
| Languages      | dotnet, go, kotlin, node, openjdk, php, python, ruby, rust                                               |
| Pkg Managers   | composer, mise, npm, pipx, uv, xcodes, yarn                                                              |
| Runtime        | Bun                                                                                                      |
| AI Core        | 필수 Claude Code/Codex CLI, 선택 Copilot/Antigravity/Hermes/CodeGraph                                    |
| Claude         | Claude official plugin toggles, CodeGraph MCP, repository `CLAUDE.md` 지침                               |
| Codex          | oh-my-codex, CodeGraph MCP, 스킬 ~/.skills 공유                                                              |
| Skills         | 단일 출처 `~/.skills` (Claude·Codex가 symlink 공유). 사용자 스킬·oh-my-codex 스킬을 한 곳에서 관리                            |
| Apps           | ghostty, docker, iterm2, chrome, rectangle, slack, figma 등                                               |
| Shell          | Oh My Zsh + autosuggestions + syntax-highlighting                                                        |
| Linux          | curl, git, vim, zsh, bat, zoxide, Ghostty 수동 설치 안내, 셸/Git baseline, claude, codex, codegraph, antigravity, hermes, oh-my-codex |

## 예약 작업과 update 계약

- 최초 config 생성은 대화형 전용이며 name/email/deviceName을 모두 입력해야 한다.
- macOS에서는 두 LaunchAgent가 독립적으로 실행된다.
  - tokscale: 3일마다 14:00
  - dotfiles: 매월 1일과 16일 14:00
- 평상시 update에는 `--init`을 붙이지 않는다. `.chezmoi.toml.tmpl`의 data key를 다시 생성해야 할 때만 대화형 터미널에서 `--init`을 사용한다.
- `chezmoi update`는 source pull 뒤 managed target을 apply하지만, source가 바뀌지 않은 `run_once_`/`run_onchange_` package와 OS 설정 drift를 지속 복구하지는 않는다.
- external의 `refreshPeriod = "168h"`는 scheduler가 아니다. chezmoi command가 external 상태를 읽는 시점에 cache age를 판단한다.
- 예약 작업은 실행·성공 timestamp나 별도 cache를 저장하지 않는다.

launchd는 예약 시각에 Mac이 잠들어 있으면 깨어난 뒤 누락된 실행을 한 번으로 합쳐 실행한다.

예약 시점과 무관하게 직접 검토·갱신하려면 다음 순서로 확인한다.

```sh
chezmoi diff
chezmoi update
chezmoi verify
```

source repository가 dirty하거나 target diff가 의도하지 않은 변경이면 먼저 내용을 검토하고 `--force`로 덮어쓰지 않는다.

## 운영 체크리스트

| 항목                  | 확인 포인트                                                                                   |
|---------------------|------------------------------------------------------------------------------------------|
| 템플릿 데이터 키 일관성       | `.chezmoi.toml.tmpl`에 정의된 변수가 모든 `.tmpl` 파일에서 동일한 이름으로 참조되는지 확인                          |
| 스크립트 phase·번호 일관성      | `before`/regular/`after` phase를 먼저 확인하고, 같은 phase 안에서 번호와 책임이 충돌하지 않는지 확인 |
| 외부 리소스 선언 검토          | rolling URL은 채널과 마지막 검증일을, pinned dependency는 exact ref와 upgrade 근거를 확인 |
| AI 모듈 경계 준수         | 설치 스크립트는 바이너리 설치만, 설정 파일은 사용자 설정만 담당하는 분리 원칙이 유지되는지 확인                                   |
| 스킬 디렉토리 동기화 상태      | 도구별 글로벌 스킬 경로 2개(claude·agents)가 symlink로 존재하고 대상이 존재하는지 확인 (`dotfiles-doctor`)    |
| 에이전트 공통 지침 최신화 | `~/AGENTS.md`, repository의 `CLAUDE.md → AGENTS.md`, `~/.codex/config.toml`의 `developer_instructions`가 4대 원칙을 반영하는지 확인 |
| 플러그인 버전 호환성         | Claude Code, Codex의 플러그인이 현재 도구 버전과 호환되는지 확인                                             |
| Linux 기초 설정 누락 여부   | macOS에 추가된 AI 도구가 Linux ai-tools 스크립트에도 반영되어 있는지 확인                                      |
| 진단 스크립트 검사 대상 최신화   | dotfiles-doctor가 새로 추가된 도구, 설정 파일, 스킬 경로를 검사 대상에 포함하는지 확인                                |
| 검증 스냅샷 갱신           | 참조 저장소의 구조가 변경되었을 때 검증 커밋 해시를 최신으로 갱신했는지 확인                                              |

## 문서 규칙

- 구조 변경 시 파일 트리를 먼저 갱신하고, 디렉토리 배포 매핑 테이블도 함께 반영한다.
- AI 설정 추가 시 Claude, Codex 2개 도구 섹션을 모두 검토한다.
- Linux 항목 추가 시 macOS 항목과 동일 수준으로 명시한다.
- 스킬 추가 시 지원 도구별 글로벌/프로젝트 경로를 함께 명시한다.
- 경로와 설정 파일명은 실제 도구 공식 문서 또는 저장소 기준으로 검증 후 기재한다.
- 검증 스냅샷의 커밋 해시와 기준일을 함께 갱신한다.
- 운영 문서 목차와 source of truth는 [docs/README.md](README.md)를 기준으로 유지한다.

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
- [Antigravity CLI](https://antigravity.google/docs/cli-getting-started)
- [Ghostty Configuration](https://ghostty.org/docs/config)

**참조 저장소**

- [zerobrew](https://github.com/lucasgelfond/zerobrew)
- [Ghostty](https://github.com/ghostty-org/ghostty)
- [claude-hud](https://github.com/jarrodwatts/claude-hud)
- [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- [CodeGraph](https://github.com/colbymchenry/codegraph)
- [oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex)
