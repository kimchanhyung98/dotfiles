# 로컬 변경 리뷰

검토일: 2026-06-30

## 범위

- cmux 설정 변경 확인
- 로컬 워킹트리 변경이 요청 범위에 비해 과도한지 검토
- 필요 보안 리뷰

## 요약

현재 변경의 핵심 방향은 적절하다. cmux 설정을 legacy `~/.config/cmux/settings.json` 및 macOS `defaults write` 방식에서 primary 설정 파일인 `~/.config/cmux/cmux.json`으로 옮기는 변경은 로컬 cmux 0.64.17 기준과 맞는다.

검토 당시에는 staged 상태에 기존 cmux 파일 삭제만 있고, 대체 파일과 문서/테스트 변경은 unstaged 또는 untracked 상태였다. 커밋 전에는 삭제와 대체 파일을 같은 단위로 묶어 cmux 설정이 제거되는 커밋을 만들지 않도록 주의해야 한다.

## cmux 설정 확인

- `cmux config paths` 기준 primary 설정 파일은 `~/.config/cmux/cmux.json`이다.
- `~/.config/cmux/settings.json`과 `~/Library/Application Support/com.cmuxterm.app/settings.json`은 legacy 경로로 표시된다.
- `cmux reload-config`는 `cmux.json`과 Ghostty config를 함께 리로드한다.
- `home/dot_config/cmux/cmux.json.tmpl`은 JSON으로 유효하고, `cmux config validate --path home/dot_config/cmux/cmux.json.tmpl`를 통과했다.
- 공식 스키마 기준 `automation.socketControlMode = "allowAll"`은 유효한 enum 값이다.

참고:

- https://cmux.com/docs/configuration
- https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json

## 변경 범위 평가

적절한 변경:

- `settings.json.tmpl` 삭제 및 `cmux.json.tmpl` 추가
- `run_onchange_after_04-cmux-settings.sh.tmpl` 삭제
- 설치/아키텍처 문서에서 cmux 경로와 실행 흐름 갱신
- macOS/Linux 테스트에서 cmux 관리 경로를 새 파일명으로 갱신

범위가 커질 수 있는 변경:

- `docs/08-cmux.md`의 전체 설정 레퍼런스는 dotfiles가 실제로 강제하는 변경보다 넓다. upstream 설정표를 크게 복제하면 cmux 업데이트 때 문서가 쉽게 낡는다.
- Ghostty split/tabbar 시각 설정은 cmux 사용성 개선으로는 납득 가능하지만, cmux 설정 마이그레이션과는 별도 성격의 UI 변경이다. 한 커밋에 함께 둘지는 의도적으로 결정하는 편이 좋다.

## 보안 리뷰

확인 결과:

- 비밀정보, 토큰, 인증 파일, 개인 키 추가는 보이지 않는다.
- 삭제된 macOS script는 `defaults write com.cmuxterm.app socketControlMode -string automation`만 수행했으며, 위험한 파일 조작이나 외부 네트워크 실행은 없었다.
- 새 `cmux.json.tmpl`도 외부 명령 실행이나 credential 값을 포함하지 않는다.

주의할 점:

- `socketControlMode = "allowAll"`은 로컬 소켓 제어를 넓게 허용하는 설정이다. 개인 macOS 환경에서 CLI/자동화를 적극 사용할 목적이면 합리적이지만, 공유 계정이나 신뢰하지 않는 로컬 프로세스가 있는 환경에서는 더 보수적인 모드 또는 password 모드를 검토해야 한다.
- `workspaceAutoNaming = true`는 에이전트 대화 내용을 기반으로 워크스페이스/탭 이름을 생성한다. 이름 생성 과정에서 대화 내용 일부가 로컬 에이전트 바이너리에 전달될 수 있다는 운영상 특성을 문서에 남기는 것이 좋다.

## 개선 사항

1. staged 상태 정리
   - 삭제된 legacy 파일과 새 `cmux.json.tmpl`을 같은 설정 변경 단위로 stage한다.
   - 커밋 전 `git diff --cached --name-status`로 삭제만 staged된 상태가 아닌지 확인한다.

2. `docs/08-cmux.md` 예시 수정
   - 검토 중 발견한 `cmux notify --color green --message "Done"` 예시는 cmux 0.64.17 CLI와 맞지 않았다.
   - `cmux notify --title "Done" --body "..."` 형태로 수정했다.

3. `docs/08-cmux.md` 축소 검토
   - 전체 설정 레퍼런스는 공식 문서/스키마 링크로 대체하고, 이 repo가 강제하는 값과 운영 메모 중심으로 줄이는 편이 유지보수에 유리하다.

4. `allowAll` 보안 의도 명시
   - `allowAll`을 쓰는 이유를 “개인 로컬 환경에서 cmux CLI 자동화 허용”처럼 명시한다.
   - 보수적 환경에서는 `password` 또는 더 제한적인 모드를 고려하라는 문구를 추가한다.

5. 테스트 보강 검토
   - 현재 macOS 테스트는 `socketControlMode` 렌더링을 확인한다.
   - 가능하면 `cmux config validate --path` 또는 JSON schema 검증을 테스트에 포함해 잘못된 키/구조를 더 빨리 잡도록 한다.

## 검증 결과

- `jq empty home/dot_config/cmux/cmux.json.tmpl`: 통과
- `chezmoi execute-template < home/dot_config/cmux/cmux.json.tmpl`: 통과
- `cmux config validate --path home/dot_config/cmux/cmux.json.tmpl`: 통과
- `bash tests/zsh-config.sh`: 4 passed, 0 failed
- `bash tests/macos.sh`: 16 passed, 0 failed

비고:

- `tests/macos.sh`에서 ShellCheck는 로컬에 `shellcheck`가 없어 skip되었다.
