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

## Linux 기초 설정

| 영역  | 설정                           | 상세                                                        |
|-----|------------------------------|-----------------------------------------------------------|
| 패키지 | curl, git, vim, zsh, ghostty | 패키지 관리자를 자동 감지(apt-get → dnf → yum)하여 설치. 이미 설치된 패키지는 건너뜀 |
| 셸   | 기본 셸 zsh 전환, 히스토리, 키바인딩      | `chsh`로 기본 셸을 zsh로 변경하고 히스토리 크기, 키바인딩 기본값 설정              |
| Git | 사용자 설정, SSH 기초 설정            | 템플릿 변수(name, email) 기반 Git 사용자 설정과 SSH 키 생성 환경 구성         |
| 로케일 | 기본 로케일, 타임존 정책               | 시스템 로케일과 타임존을 일관된 기본값으로 설정                                |

## 터미널

Ghostty 설정은 `dot_config/ghostty/config.tmpl`로 관리한다. XDG 경로(`~/.config/ghostty/`)를 사용하며, 배포되는 파일명은 `config` (확장자 없음)이다.
Ghostty는 이 단일 파일에서 모든 설정을 읽는다.

설정 형식은 `key = value`이며, 주석은 `#`으로 시작한다(인라인 주석 불가, 별도 줄에서만 사용). Ghostty는 설정 파일 변경 시 수동 리로드를 지원한다(macOS: `Cmd+Shift+,`,
Linux: `Ctrl+Shift+,`). 자동 파일 감시는 제공하지 않으며, 일부 설정은 터미널 재시작이 필요하다.

| 영역    | 설정 항목                                                                                                      | 상세                                                  |
|-------|------------------------------------------------------------------------------------------------------------|-----------------------------------------------------|
| 폰트    | font-family, font-size, adjust-cell-height                                                                 | JetBrainsMono Nerd Font 사용. 줄 간격 조정                 |
| 테마    | theme                                                                                                      | 전체 색상 테마. 내장 테마 이름으로 지정 (Gruvbox Dark)              |
| 커서    | cursor-style-blink, mouse-hide-while-typing                                                                | 커서 깜빡임 비활성화, 타이핑 중 마우스 커서 숨김                        |
| 창     | window-padding-x/y, window-padding-balance, background-opacity, background-blur, unfocused-split-opacity 등 | 여백, 투명도, 블러, split 패널 투명도, 붙여넣기 보호 활성화, 닫기 확인 다이얼로그 |
| 셸     | shell-integration, scrollback-limit                                                                        | 셸 통합(프롬프트 감지, 명령 완료 마커), 스크롤백 버퍼 크기                 |
| macOS | font-thicken, macos-titlebar-style, macos-option-as-alt                                                    | 레티나 선명도, 타이틀바 숨김, Option 키를 Alt로 매핑 (macOS 전용)      |

Ghostty는 macOS에서 Homebrew cask(`brew install --cask ghostty`), Linux에서 배포판 패키지 관리자로 설치한다.
