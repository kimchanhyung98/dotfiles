# 프로젝트 개요

macOS / Linux 개발 환경 자동화를 위한 chezmoi 기반 dotfiles.

## 범위

- macOS 중심 환경에 시스템, Claude, Codex, Gemini, Copilot, OpenCode 스택을 통합한다.
- Linux는 기초 셸/패키지/AI 최소 구성으로 유지한다.
- 지정된 저장소 10개를 실제 원격 기준으로 검증하고, 유지 가능한 항목만 선별 적용한다.
- 저장소 원본 전체를 복제하지 않고 유지 가능한 구성만 채택한다.

## 검토 완료 레포

| 카테고리     | 저장소                                                                                                                                                 |
|----------|-----------------------------------------------------------------------------------------------------------------------------------------------------|
| System   | lucasgelfond/zerobrew, ghostty-org/ghostty                                                                                                          |
| Claude   | obra/superpowers, jarrodwatts/claude-hud, blader/humanizer, VoltAgent/awesome-agent-skills, forrestchang/andrej-karpathy-skills                     |
| Codex    | Yeachan-Heo/oh-my-codex                                                                                                                             |
| Gemini   | (SuperGemini — pipx 패키지)                                                                                                                            |
| OpenCode | anomalyco/opencode, code-yeongyu/oh-my-opencode                                                                                                     |

## 검증 스냅샷

- 기준일: 2026-02-16
- 기준: 공식 문서 + 각 레포 최신 원격 main/dev 브랜치

| 저장소                                 | 검증 커밋     |
|-------------------------------------|-----------|
| lucasgelfond/zerobrew               | `a15119f` |
| ghostty-org/ghostty                 | `e94c905` |
| obra/superpowers                    | `e16d611` |
| jarrodwatts/claude-hud              | `10193cc` |
| blader/humanizer                    | `c78047b` |
| VoltAgent/awesome-agent-skills      | `feb81d6` |
| forrestchang/andrej-karpathy-skills | `aa4467f` |
| anomalyco/opencode                  | `ef979cc` |
| code-yeongyu/oh-my-opencode         | `7d2c798` |
| Yeachan-Heo/oh-my-codex             | `c25edb0` |

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
