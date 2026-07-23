# 프로젝트 개요

macOS / Linux 개발 환경 자동화를 위한 chezmoi 기반 dotfiles.

## 범위

- macOS 중심 환경에 시스템 도구와 AI CLI를 통합한다. Claude와 Codex가 필수 baseline이고 Copilot, Antigravity, Hermes, CodeGraph 등은 선택 도구다.
- Linux는 Ubuntu 26.04 LTS를 native 기준선으로 지원한다. GitHub Codespaces에서는 시스템 timezone, 로그인 셸, SSH bootstrap, 데스크톱 앱을 제외하고 공통 CLI·설정·AI 도구를 적용한다. 그 밖의 배포판은 지원하지 않는다.
- 지정된 저장소 6개를 실제 원격 기준으로 검증하고, 유지 가능한 항목만 선별 적용한다.
- 저장소 원본 전체를 복제하지 않고 유지 가능한 구성만 채택한다.

## 검토 완료 레포

| 카테고리   | 저장소                                                                                         |
|--------|---------------------------------------------------------------------------------------------|
| System | lucasgelfond/zerobrew, ghostty-org/ghostty                                                  |
| Claude | jarrodwatts/claude-hud, VoltAgent/awesome-agent-skills, forrestchang/andrej-karpathy-skills |

## 검증 스냅샷

- 기준일: 2026-02-16
- 기준: 공식 문서 + 각 레포 최신 원격 main/dev 브랜치

| 저장소                                 | 검증 커밋     |
|-------------------------------------|-----------|
| lucasgelfond/zerobrew               | `a15119f` |
| ghostty-org/ghostty                 | `e94c905` |
| jarrodwatts/claude-hud              | `10193cc` |
| VoltAgent/awesome-agent-skills      | `feb81d6` |
| forrestchang/andrej-karpathy-skills | `aa4467f` |

## 설계 원칙

- **선언적 관리**: 무엇을 설치할지는 선언 파일(Brewfile, .chezmoiexternal.toml)에 정의하고, 어떻게 설치할지는 실행 스크립트에 분리한다. 패키지 목록과 설치 로직이 섞이지 않아 각각
  독립적으로 변경할 수 있다.
- **반복 적용**: managed file은 `chezmoi apply`로 source 상태를 다시 적용한다. `run_once_`와 `run_onchange_`는 content trigger가 충족될 때만 실행되므로, source가 바뀌지 않은 package·OS 설정의 외부 drift까지 계속 복구하지는 않는다.
- **순서 보장**: chezmoi 네이밍 컨벤션(`run_` + `once_`/`onchange_` + `before_`/`after_` + 이름)으로 실행 phase를 제어한다. 번호
  접두사(01, 02, ...)는 같은 source 디렉터리와 phase 안의 순서를 고정하며, 공통 루트와 OS 하위 디렉터리 사이의 전역 순서는 보장하지 않는다. `macos-settings`는 파일 배포 이후 적용이 필요하므로 `run_onchange_after_`를 사용한다.
- **OS 분기**: 실행 스크립트는 OS별 하위 디렉토리(`darwin/`, `linux/`)로 물리적 분리하고, 설정 파일은 `.tmpl` 템플릿 조건문으로 분기한다. 하나의 소스에서 두 OS 환경을 모두
  관리할 수 있다.
- **설치와 설정 분리**: 도구의 바이너리 설치는 스크립트가 담당하고, 사용자 설정은 chezmoi가 배포하는 설정 파일(`.tmpl`)이 담당한다. 설치 방식이 바뀌어도 설정은 그대로 유지되고, 설정을 변경해도
  재설치가 필요 없다.
- **설치 경계**: AI core와 Claude/Codex 확장 단계를 분리한다. Claude/Codex 설치 실패는 전체 apply를 실패시키고, 선택 도구 실패는 warning으로 남긴다.
- **스킬 공유**: 공통 스킬을 단일 출처 `~/.skills`에 두고 Claude Code와 Codex의 글로벌 스킬 경로를 symlink로 연결하여, 두 도구에서 동일한 스킬이 적용된다.
- **사용자 설정 우선**: 도구의 기본 동작보다 사용자가 선언한 설정을 우선 적용한다. 도구 업데이트로 기본값이 변경되어도 사용자 설정은 유지된다.
- **검증 가능한 근거 유지**: 모든 경로, 설정 파일명, 도구 동작은 공식 문서 또는 실제 저장소 기준으로 검증한다. 문서에 기재된 정보는 검증 스냅샷의 커밋 해시로 추적할 수 있어야 한다.
