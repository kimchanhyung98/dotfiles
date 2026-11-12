# 테스트 구조

테스트 케이스는 `tests/{env}/{func}/{name}.sh`에 둔다.

| `env` | 실행 환경 | 진입점 |
|---|---|---|
| `local` | 현재 host, network·Docker 없음 | `make check` |
| `macos` | macOS host의 임시 HOME | `make test-macos` |
| `linux` | Linux에서는 임시 HOME을 쓰는 로컬 Ubuntu 26.04, macOS에서는 Docker | `make test-linux` |
| `codespaces` | 실제 Codespaces·Ubuntu CI에서 직접 실행, macOS에서는 Docker | `CODESPACES=true make test-linux` |

`tests/run.sh`는 선택한 환경 아래의 테스트를 경로순으로 각각 새 Bash
process에서 실행한다. `tests/lib/`는 공통 helper, `tests/fixtures/`는 fixture만
제공하며 테스트 케이스가 아니다. 명령이 실패하면 테스트 경로, 행, 종료 상태와
실패한 명령을 출력한다.

`make test`는 macOS에서 macOS 로컬 테스트와 Linux·Codespaces Docker 테스트를
실행한다. Linux에서는 macOS를 생략하고 현재 호스트에서 Linux 테스트를 실행한다.
Linux 로컬 테스트는 임시 HOME과 현재 checkout의 `home/`에서 복사한 테스트 소스를 쓴다.
다만 actual apply가 패키지, 로그인 셸, locale, timezone 같은 시스템 설정을 바꿀
수 있으므로 준비된 Ubuntu 26.04 환경이나 CI에서 실행한다.

주 테스트 대상은 `home/` 아래의 chezmoi 관리 소스와 그 렌더·적용 결과다.
Codex 설정 검사는 저장소의 `.codex/config.toml`과도 비교한다. Git 훅과
`install.sh` 같은 저장소 도구는 이 테스트 스위트의 대상이 아니다.

공통 검사에는 Bash, Git, chezmoi, jq, Zsh가 필요하다. macOS suite에는
ShellCheck, Codex CLI, Kimi CLI도 필요하다. Antigravity와 Kiro CLI 검사는
해당 CLI가 설치된 경우에만 추가한다.

테스트 소스는 `home/`을 복사하되 `.chezmoiexternal.toml`을 제외한다. chezmoi
캐시도 임시 HOME 안에 두므로 외부 다운로드와 사용자 캐시에 의존하지 않는다.
실제 배포 소스의 외부 리소스 설정은 유지한다. 필요한 도구와 패키지를 준비한
뒤 테스트는 네트워크 없이 실행할 수 있다. 도구·패키지 설치와 Docker 이미지
빌드에는 네트워크가 필요하다.

Orca 테스트는 가짜 CLI·앱 실행 명령과 임시 상태로 설치 흐름을 검증한다.
Docker는 Linux/Codespaces 동작과 macOS 전용 항목 제외를 확인한다. 실제 macOS
앱 설치·GUI 실행·플러그인 승인까지 검증한 결과로 해석하지 않는다.

새 테스트는 내부 함수 호출 여부가 아니라 command의 exit status, 생성된 파일,
렌더링 결과처럼 사용자가 관찰할 수 있는 동작을 확인한다. 외부 API·repository는
`local` fixture로 대체하고 실제 사용자 HOME이나 credential은 사용하지 않는다.
