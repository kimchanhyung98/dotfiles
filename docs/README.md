# 문서 안내

`docs/01`~`08`은 현재 저장소의 동작과 운영 방법을 설명한다.

## 현재 지원 범위

| 환경 | 보장 수준 | 현재 검증 |
|---|---|---|
| 개인 macOS | 주 사용 환경 | 격리 HOME의 템플릿·bootstrap·설정 회귀 테스트 |
| Ubuntu 26.04 LTS non-root | Linux 기준선 | Docker actual apply·verify |
| GitHub Codespaces | 제한 지원 | `CODESPACES=true`에서 시스템 설정과 데스크톱 앱을 제외한 CLI 경로 |

native 최초 설정은 대화형 터미널에서 실행해야 한다. 이름, 이메일, 기기명에는 기본값이 없으며 세 값 중 하나라도 비어 있으면 config 생성이 중단된다. Codespaces 자동 설치는 공식 identity 환경 변수를 사용해 비대화형으로 같은 값을 만든다.

## 운영 문서

| 문서 | 내용 |
|---|---|
| [01-overview.md](01-overview.md) | 범위와 설계 원칙, 외부 검증 snapshot |
| [02-architecture.md](02-architecture.md) | 디렉토리 구조, 배포 매핑, chezmoi data |
| [03-installation.md](03-installation.md) | bootstrap 입력 계약, script phase, 패키지·외부 리소스 |
| [04-environment.md](04-environment.md) | macOS/Linux와 터미널 설정 |
| [05-ai-tools.md](05-ai-tools.md) | Claude, Codex, 공통 스킬과 권한 경계 |
| [06-operations.md](06-operations.md) | doctor, 수동 update, 운영 checklist |
| [07-testing.md](07-testing.md) | macOS/Linux 테스트와 Git hook/Actions 범위 |
| [08-cmux.md](08-cmux.md) | cmux와 Ghostty 설정 소유권 |

## Source of truth

| 사실 | 기준 파일 |
|---|---|
| 최초 설치와 필수 입력 | `install.sh`, `home/.chezmoi.toml.tmpl` |
| script phase와 실행 조건 | `home/.chezmoiscripts/`의 실제 파일명 |
| macOS 패키지 | `home/Brewfile` |
| Linux 패키지 | `home/.chezmoiscripts/linux/run_once_before_01-install-packages.sh.tmpl` |
| 선택된 mattpocock 스킬과 ref | `home/dot_local/bin/executable_mattpocock-skills-sync` |
| 프로젝트 clone | `home/dot_local/bin/executable_projects-bootstrap` |
| Doppler `.env` 동기화 | `home/dot_local/bin/executable_projects-doppler-sync` |
| 테스트 범위 | `tests/`, `Makefile` |

문서와 구현이 다르면 위 기준 파일을 먼저 확인하고 같은 변경에서 문서를 갱신한다.
