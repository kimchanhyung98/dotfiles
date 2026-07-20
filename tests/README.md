# 테스트 구조

테스트 케이스는 `tests/{env}/{func}/{name}.sh`에 둔다.

| `env` | 실행 환경 | 진입점 |
|---|---|---|
| `local` | 현재 host, network·Docker 없음 | `make check` |
| `macos` | macOS host의 임시 HOME | `make test-macos` |
| `linux` | Linux에서는 임시 HOME을 쓰는 로컬 Ubuntu 26.04, macOS에서는 Docker | `make test-linux` |
| `codespaces` | 실제 Codespaces 로컬 또는 CI·macOS의 Ubuntu 26.04 Docker | `make test-linux` |

`tests/run.sh`는 선택한 환경 아래의 테스트를 경로순으로 각각 새 Bash
process에서 실행한다. `tests/lib/`는 공통 helper, `tests/fixtures/`는 fixture만
제공하며 테스트 케이스가 아니다. 명령이 실패하면 테스트 경로, 행, 종료 상태와
실패한 명령을 출력한다.

`make test`는 macOS에서 macOS 로컬 테스트와 Linux·Codespaces Docker 테스트를
실행한다. Linux에서는 macOS를 생략하고 현재 호스트에서 Linux 테스트를 실행한다.
Linux 로컬 테스트는 실제 HOME 대신 임시 HOME과 현재 checkout의 `home/` source를 쓴다.
다만 actual apply가 패키지, 로그인 셸, locale, timezone 같은 시스템 설정을 바꿀
수 있으므로 준비된 Ubuntu 26.04 환경이나 CI에서 실행한다.

테스트 대상은 `home/` 아래의 chezmoi 관리 소스와 그 렌더·적용 결과로 한정한다.
프로젝트 루트의 작업용 설정, Git 훅, installer 같은 저장소 도구는 이 테스트
스위트의 대상이 아니다.

새 테스트는 내부 함수 호출 여부가 아니라 command의 exit status, 생성된 파일,
렌더링 결과처럼 사용자가 관찰할 수 있는 동작을 확인한다. 외부 API·repository는
`local` fixture로 대체하고 실제 사용자 HOME이나 credential은 사용하지 않는다.
