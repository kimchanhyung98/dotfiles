# 환경 설정

## macOS 시스템 설정

`run_onchange_`로 관리하여, 스크립트 내용을 수정하면 다음 `chezmoi apply`에서 자동 재적용된다. 모든 설정은 `defaults write` 명령으로 적용하며, 일부 설정은 관련 프로세스
재시작(`killall`)이 필요하다.

| 영역         | 설정                                                                | 효과                              |
|------------|-------------------------------------------------------------------|---------------------------------|
| Dock       | 자동 숨김, 확대 효과, 아이콘 크기 48, 최근 항목 숨김, scale 최소화, 숨긴 앱 반투명, Spaces 고정 | 화면 공간 확보, 일관된 Dock 동작           |
| Finder     | 경로/상태 바, 확장자·숨김 파일 표시, 폴더 우선 정렬, 현재 폴더 검색, .DS_Store 외부 볼륨 방지     | 파일 탐색 효율성 향상, 외부 볼륨 오염 방지       |
| Keyboard   | 빠른 키 반복, 짧은 반복 지연, press-and-hold 끔, 자동 교정·대문자·대시·마침표·따옴표 끔       | 개발 환경에 최적화된 키 입력, 불필요한 자동 변환 제거 |
| Trackpad   | 탭으로 클릭 비활성화                                                       | 의도하지 않은 탭 클릭 방지                 |
| Screenshot | 저장 위치 Desktop, PNG 형식, 창 그림자 제거                                   | 스크린샷 파일 관리 일관성, 불필요한 그림자 제거     |
| System     | 새 문서 로컬 디스크 저장                                                    | iCloud 대신 로컬 디스크에 기본 저장         |

## Stats

Stats는 사용자 설정과 앱 실행 기록을 같은 plist에 저장한다. 앱의 설정 내보내기도 인증 정보를 제외한 저장 값을 포함하므로, plist에 실행 기록이 있는 것은 정상이다. [Stats 3.0.23의 저장·내보내기 코드](https://github.com/exelban/stats/blob/v3.0.23/Kit/plugins/Store.swift)를 기준으로 확인했다.

dotfiles의 `Stats.plist`에는 `version`, `updater_check_ts`, `support_ts`를 넣지 않는다. 과거 버전과 시각을 다시 적용하지 않기 위해서다. 적용 스크립트의 `defaults import`는 파일에 선언된 값을 덮어쓰고, 선언하지 않은 기존 값은 보존한다. 따라서 이 세 값은 현재 로컬 값을 유지하며, 신규 설치에는 과거 값을 만들지 않는다. 이 동작은 저장 영역을 교체하는 Stats 앱 내부의 가져오기 기능과 다르다.

## Ubuntu와 GitHub Codespaces

| 영역  | 설정                           | 상세                                                        |
|-----|------------------------------|-----------------------------------------------------------|
| 패키지 | Ubuntu CLI baseline | Ubuntu 26.04 LTS와 Codespaces에서 apt만 사용. 다른 Linux 배포판은 명시적으로 거부 |
| 셸 | native Ubuntu | zsh 로그인 셸, en_US.UTF-8, Asia/Seoul 설정을 시도 |
| 셸 | Codespaces | 공통 zsh 파일은 배포하되 로그인 셸·로케일·timezone 같은 container system state는 변경하지 않음 |
| Git | native Ubuntu | 사용자 설정과 검증된 GitHub SSH known_hosts 준비 |
| Git | Codespaces | `CODESPACES=true`를 감지하고 GitHub-managed repository 인증을 유지 |

## 터미널

Ghostty 설정은 `dot_config/ghostty/config.tmpl`로 관리한다. XDG 경로(`~/.config/ghostty/`)를 사용하며, 배포되는 파일명은 `config` (확장자 없음)이다.
Ghostty는 이 단일 파일에서 모든 설정을 읽는다.

설정 형식은 `key = value`이며, 주석은 `#`으로 시작한다(인라인 주석 불가, 별도 줄에서만 사용). Ghostty는 설정 파일 변경 시 수동 리로드를 지원한다(macOS: `Cmd+Shift+,`,
Linux: `Ctrl+Shift+,`). 자동 파일 감시는 제공하지 않으며, 일부 설정은 터미널 재시작이 필요하다.

| 영역    | 설정 항목                                                                                                      | 상세                                                  |
|-------|------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| 폰트    | font-family, font-size, adjust-cell-height                                                                 | D2Coding 사용. 줄 간격 조정                                |
| 테마    | theme                                                                                                      | 전체 색상 테마. 내장 테마 이름으로 지정 (Gruvbox Dark)              |
| 커서    | cursor-style-blink, mouse-hide-while-typing                                                                | 커서 깜빡임 비활성화, 타이핑 중 마우스 커서 숨김                        |
| 창     | window-padding-x/y, window-padding-balance, background-opacity, background-blur, unfocused-split-opacity 등 | 여백, 투명도, 블러, split 패널 투명도, 붙여넣기 보호 활성화, 닫기 확인 다이얼로그 |
| 셸     | shell-integration, scrollback-limit                                                                        | 셸 통합(프롬프트 감지, 명령 완료 마커), 스크롤백 버퍼 크기                 |
| macOS | font-thicken, macos-option-as-alt                                                                          | 레티나 선명도, Option 키를 Alt로 매핑 (macOS 전용)               |

Ghostty는 macOS에서 Brewfile의 Homebrew cask로 설치한다. Ubuntu/Codespaces 지원 범위에는 Ghostty 바이너리 설치가 포함되지 않지만 공통 설정 파일은 배포한다.

## Orca

macOS에서 공식 `stablyai/orca/orca` cask로 앱과 CLI를 설치한다. `run_onchange_after_10-orca-plugins.sh.tmpl`은 최초 적용과 스크립트 변경 시 다음 플러그인을 공식 카탈로그에서 설치한다. 앱 내장 플러그인은 목록에 넣지 않는다.

| 플러그인 ID | 용도 |
|---|---|
| `stablyai.orca-oled-theme` | OLED 테마 |
| `stablyai.orca-material-icons` | Material 파일 아이콘 |
| `stablyai.orca-http` | HTTP 파일 지원 |
| `stablyai.orca-systemd` | systemd 파일 지원 |
| `stablyai.orca-docx` | Word 문서 뷰어 |
| `stablyai.orca-spreadsheet` | 스프레드시트 편집기 |
| `stablyai.orca-image-markup` | 이미지 주석 도구 |

`orca plugin list --environment local --json`으로 설치 목록을 확인한 뒤 누락된 항목만 설치한다. 새 설치는 공식 카탈로그의 현재 버전을 사용한다. 이미 설치된 항목은 버전과 비활성화 상태를 유지하며, 목록 밖 플러그인은 삭제하지 않는다. 플러그인 설치와 사용할 테마 선택은 별개다.

플러그인 CLI에는 실행 중인 Orca가 필요하다. 연결에 실패하면 앱을 백그라운드로 열고, 1초 간격으로 최대 15회 다시 연결한다. 계속 실패하면 apply를 실패 처리한다.

테마·아이콘·구문 같은 콘텐츠 전용 플러그인은 별도 승인 없이 설치된다. Orca가 승인을 요구하면 권한 목록과 fingerprint가 포함된 재실행 명령을 출력한다. 스크립트는 자동 승인하지 않고 나머지 플러그인을 계속 처리한다. 승인 대기만 있으면 종료 코드 3, 일반 설치 오류가 있으면 종료 코드 1로 끝난다. CLI가 안내한 권한을 확인하고 승인 명령을 실행한 뒤 `chezmoi apply`를 다시 실행한다. 실패한 스크립트는 완료로 기록되지 않으므로 누락 항목을 다시 시도한다.

그 밖의 설정 관리 범위는 다음과 같다.

| 항목 | 지원 방식 | 현재 관리 여부 |
|---|---|---|
| 단축키 | `~/.orca/keybindings.json` 파일을 chezmoi로 배포 가능 | 관리하지 않음 |
| 터미널 폰트·테마·커서 | Settings → Terminal → Import from Ghostty로 기존 Ghostty 설정 가져오기 | 수동 가져오기. 지속 동기화 아님 |
| 일반 앱 설정 | Orca Settings에서 변경 | 관리하지 않음 |

로컬 Orca 1.4.257에서 일반 앱 설정을 부분적으로 내보내거나 적용하는 CLI는 확인되지 않았다. 설정은 Application Support 아래 프로필 SQLite DB에 있으며 세션 등 다른 상태도 같은 프로필에 저장된다. DB 전체 복사나 `profile state rollback`을 설정 배포에 사용하지 않는다.

Orca가 등록하는 Claude 훅·테마와 Codex 훅 신뢰 상태도 로컬 값이다. 현재 Claude/Codex 템플릿을 그대로 덮어쓰면 이 값이 빠질 수 있으므로, 적용 전 diff를 확인하고 필요한 로컬 값을 보존한다. [AI 설정 적용 지침](05-ai-tools.md)을 따른다.

근거: [공식 cask](https://github.com/stablyai/homebrew-orca/blob/main/Casks/orca.rb), [플러그인 CLI](https://github.com/stablyai/orca/blob/main/src/cli/specs/plugin-install.ts), [설정](https://github.com/stablyai/orca/blob/main/docs/site/content/docs/settings.mdx), [Ghostty 가져오기](https://github.com/stablyai/orca/blob/main/docs/site/content/docs/terminal.mdx).
