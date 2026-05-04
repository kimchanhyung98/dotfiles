# 운영

## dotfiles-doctor

설치 완료 후 헬스체크 스크립트. `~/.local/bin/dotfiles-doctor`로 배포되어 `dotfiles-doctor` 명령으로 실행한다. 각 항목의 설치 여부를 확인하고 누락된 항목을 보고한다.

| 검사 카테고리          | 대상                                                                                                  | 검사 내용                           |
|------------------|-----------------------------------------------------------------------------------------------------|---------------------------------|
| System           | macOS/Linux 버전, 아키텍처                                                                                | OS 버전과 아키텍처 정보를 표시하여 환경 식별      |
| Shell            | zsh, git, vim, tmux                                                                                 | 기초 셸 도구의 설치 여부와 버전 확인           |
| Terminal         | ghostty                                                                                             | Ghostty 터미널의 설치 여부 확인           |
| Languages        | node, python3, go, rustc, php, ruby                                                                 | 프로그래밍 언어 런타임의 설치 여부와 버전 확인      |
| Package Managers | brew, zb, pipx, bun                                                                                 | 패키지 관리자의 설치 여부 확인. zb는 zerobrew |
| AI CLI           | claude, codex, opencode, ollama, gemini                                                             | AI 도구 CLI의 설치 여부 확인             |
| AI 플러그인          | superpowers, everything-claude-code, claude-hud, claude-mem, oh-my-codex, oh-my-opencode            | 각 AI 도구의 확장 기능 설치 상태 확인         |
| 스킬 디렉토리          | Claude, Codex, Copilot, OpenCode 4개 경로                                                              | 글로벌 스킬 디렉토리 존재 여부와 내용물 확인       |
| AGENTS.md        | `~/AGENTS.md` 존재 여부                                                                                 | 공통 에이전트 지침 파일 배포 상태 확인          |
| claude-mem       | `~/.claude-mem/`, `settings.json`                                                                   | claude-mem 디렉토리와 설정 파일 존재 여부 확인 |
| Dotfiles         | ~/.zshrc, ~/.gitconfig, ~/.vimrc, ~/.oh-my-zsh                                                      | 핵심 dotfiles의 배포 상태 확인           |
| Config           | ghostty, opencode, claude, codex, copilot                                                           | 각 도구의 설정 디렉토리 존재 여부 확인          |
| MCP              | ~/.claude.json                                                                                      | MCP 서버 설정 파일 존재 여부 확인           |

## 요구사항 요약

| 카테고리           | 항목                                                                                                  |
|----------------|-----------------------------------------------------------------------------------------------------|
| Prerequisites  | Xcode CLI, Homebrew, zerobrew, Rosetta 2 (Apple Silicon)                                            |
| macOS Settings | Dock, Finder, Keyboard, Trackpad, Screenshot                                                        |
| System Tools   | bash, bat, zsh, curl, wget, gh, git, git-lfs, grep, gnupg, shellcheck, terminal-notifier, tree, vim |
| Dev Tools      | act, awscli, direnv, fswatch, fzf, ripgrep, tmux, watchman, zoxide                                  |
| Terminal       | Ghostty                                                                                             |
| Languages      | dotnet, go, kotlin, node, openjdk, php, python, ruby, rust                                          |
| Pkg Managers   | composer, mise, npm, pipx, uv, xcodes, yarn                                                         |
| Runtime        | Bun                                                                                                 |
| AI Core        | Claude Code, Codex CLI, Gemini CLI, Copilot CLI                                                     |
| Claude         | SuperClaude, superpowers, claude-hud, karpathy-skills, MCP 4종                                       |
| Codex          | oh-my-codex, superpowers (copy)                                                                     |
| Gemini         | SuperGemini, superpowers (copy), MCP 3종                                                             |
| Copilot        | superpowers (copy), MCP 2종                                                                          |
| OpenCode       | OpenCode, oh-my-opencode, superpowers (copy)                                                        |
| Skills         | humanizer (Claude, Codex), superpowers (Claude 플러그인 + Codex/Gemini/Copilot/OpenCode copy)           |
| Apps           | ghostty, docker, iterm2, chrome, rectangle, slack, figma 등                                          |
| Shell          | Oh My Zsh + autosuggestions + syntax-highlighting                                                   |
| Linux          | curl, git, vim, zsh, ghostty, 셸/Git baseline, claude, codex, opencode, gemini                       |

## 운영 체크리스트

| 항목                  | 확인 포인트                                                                           |
|---------------------|----------------------------------------------------------------------------------|
| 템플릿 데이터 키 일관성       | `.chezmoi.toml.tmpl`에 정의된 변수가 모든 `.tmpl` 파일에서 동일한 이름으로 참조되는지 확인                  |
| 스크립트 번호 체계 일관성      | darwin/(01~04, 10~14, 20, 99), linux/(01~05) 번호가 중복 없이 순서대로 유지되는지 확인             |
| 외부 리소스 선언 파일 최신화    | `.chezmoiexternal.toml`의 URL, 브랜치, 해시가 최신 원격 저장소와 일치하는지 확인                       |
| AI 모듈 경계 준수         | 설치 스크립트는 바이너리 설치만, 설정 파일은 사용자 설정만 담당하는 분리 원칙이 유지되는지 확인                           |
| 스킬 디렉토리 동기화 상태      | Claude, Codex, Gemini, Copilot, OpenCode 5개 글로벌 스킬 경로에 humanizer 스킬이 배포되어 있는지 확인 |
| AGENTS.md 공통 지침 최신화 | `~/AGENTS.md`와 `~/.codex/AGENTS.md`의 4대 원칙과 공통 규칙이 최신 상태인지 확인                    |
| 플러그인 버전 호환성         | Claude Code, Codex, OpenCode의 플러그인이 현재 도구 버전과 호환되는지 확인                           |
| Linux 기초 설정 누락 여부   | macOS에 추가된 AI 도구가 Linux ai-tools 스크립트에도 반영되어 있는지 확인                              |
| 진단 스크립트 검사 대상 최신화   | dotfiles-doctor가 새로 추가된 도구, 설정 파일, 스킬 경로를 검사 대상에 포함하는지 확인                        |
| 검증 스냅샷 갱신           | 참조 저장소의 구조가 변경되었을 때 검증 커밋 해시를 최신으로 갱신했는지 확인                                      |

## 문서 규칙

- 구조 변경 시 파일 트리를 먼저 갱신하고, 디렉토리 배포 매핑 테이블도 함께 반영한다.
- AI 설정 추가 시 Claude, Codex, Gemini, Copilot, OpenCode 5개 도구 섹션을 모두 검토한다.
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
- [GitHub Copilot CLI](https://docs.github.com/en/copilot/using-github-copilot/using-github-copilot-in-the-command-line)
- [GitHub Copilot Skills](https://docs.github.com/en/copilot/concepts/agents/about-agent-skills)
- [Ghostty Configuration](https://ghostty.org/docs/config)

**참조 저장소**

- [zerobrew](https://github.com/lucasgelfond/zerobrew)
- [Ghostty](https://github.com/ghostty-org/ghostty)
- [superpowers](https://github.com/obra/superpowers)
- [claude-hud](https://github.com/jarrodwatts/claude-hud)
- [humanizer](https://github.com/blader/humanizer)
- [awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills)
- [andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills)
- [OpenCode](https://github.com/anomalyco/opencode)
- [oh-my-opencode](https://github.com/code-yeongyu/oh-my-opencode)
- [oh-my-codex](https://github.com/Yeachan-Heo/oh-my-codex)
- [Gemini CLI](https://github.com/google-gemini/gemini-cli)
