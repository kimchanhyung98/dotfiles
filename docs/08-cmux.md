# cmux 터미널 설정

cmux는 Ghostty를 터미널 코어로 내장한 macOS 터미널이다. AI 코딩 에이전트를 병렬로 다루는 데 초점이 맞춰져 있다. 설정은 **두 파일로 분리**된다.

| 파일 | 역할 | dotfiles 소스 |
|---|---|---|
| `~/.config/cmux/cmux.json` | cmux 앱 동작: 자동화/소켓, 사이드바, 알림, 단축키, 워크스페이스 색 등 | `home/dot_config/cmux/cmux.json.tmpl` |
| `~/.config/ghostty/config` | 터미널 표현: 폰트·테마·패딩·split 등 (cmux가 읽음) | `home/dot_config/ghostty/config.tmpl` |

> cmux Settings UI에는 **터미널 폰트 패밀리 항목이 없다**. 터미널 폰트는 오직 `~/.config/ghostty/config`의 `font-family`로 결정된다.

## 우선순위와 적용

- **우선순위**: 전역 `~/.config/cmux/cmux.json` 이 **Settings UI보다 우선**한다. 프로젝트별 `.cmux/cmux.json`은 actions/commands/UI만 덮어쓴다.
- **부분 관리**: cmux.json에 **명시한 키만** 파일 관리되고, 나머지는 Settings UI 값으로 폴백한다. 그래서 강제할 항목만 선언하는 것이 dotfiles 철학(사용자 설정 우선)에 맞다.
- **적용**: `chezmoi apply` 로 파일 배포 → cmux에서 **`cmd+shift+,`**(설정 리로드) 또는 **`cmux reload-config`** 실행. 전체 재시작은 불필요(실행 중 에이전트 세션 보호).
- **스키마**: `schemaVersion`은 `1` 유지. 표준 스키마는 [cmux.schema.json](https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json).

## dotfiles가 현재 관리하는 값

**cmux.json** (`automation`/`shortcuts`/`terminal` 일부만 강제, 나머지는 GUI 폴백)

| 키 | 값 | 의도 |
|---|---|---|
| `automation.socketControlMode` | `allowAll` | 개인 로컬 환경에서 cmux CLI/에이전트 훅의 워크스페이스·패널·알림 자동화 허용 |
| `automation.claudeCodeIntegration` | `true` | Claude Code 통합 훅 활성화 (기본 on을 명시적으로 보장) |
| `automation.workspaceAutoNaming` | `true` | 에이전트 대화 기반 워크스페이스/탭 자동 명명 |
| `automation.autoNamingAgent` | `claude` | 자동 명명 주체를 Claude로 고정 |
| `shortcuts.bindings.*.first` | `key=""`, modifiers `false` | cmux 앱 단축키를 비워 터미널/에디터/쉘 단축키와의 충돌 방지 |
| `terminal.agentHibernation.enabled` | `true` | 유휴 에이전트 일시중단으로 자원 절약 |

`allowAll`은 legacy `automation`보다 넓은 소켓 제어 권한이다. 이 repo에서는 개인 macOS 로컬 환경에서 `cmux new-workspace`, `cmux new-split`, `cmux notify` 같은 CLI 자동화를 비밀번호 프롬프트 없이 쓰기 위해 의도적으로 선택한다. 공유 계정이나 신뢰하지 않는 로컬 프로세스가 있는 환경에서는 `password` 또는 `automation` 같은 더 제한적인 모드를 우선 검토한다.

`workspaceAutoNaming`은 에이전트 대화 내용을 바탕으로 워크스페이스/탭 이름을 만든다. 민감한 대화를 다루는 세션에서는 자동 명명 결과가 로컬 cmux UI와 메타데이터에 남을 수 있음을 고려한다.

**ghostty/config** (전체 선언적 관리)

| 항목 | 값 |
|---|---|
| 폰트 | `font-family = D2Coding`, `font-size = 13.5`, `adjust-cell-height = 1` |
| 테마 | `theme = Gruvbox Dark` |
| 탭바 | `window-show-tab-bar = never` (cmux 자체 세로 탭과 중복 제거) |
| split | `unfocused-split-opacity = 0.65`, `unfocused-split-fill = #1d2021`, `split-divider-color = #504945` |
| 창 | `window-padding-x/y`, `window-padding-balance`, `background-opacity = 0.8`, `background-blur = 20` |
| 기타 | `cursor-style-blink = false`, `mouse-hide-while-typing = true`, `shell-integration = zsh`, `scrollback-limit = 10000` |
| macOS | `font-thicken = true`, `macos-option-as-alt = true` |

## cmux.json 관리 방침

이 repo는 cmux upstream 설정 전체를 복제하지 않는다. `home/dot_config/cmux/cmux.json.tmpl`에 선언한 값만 강제하고, 나머지 app/sidebar/browser/notification 및 선언하지 않은 shortcuts 설정은 cmux 기본값 또는 Settings UI 값을 따른다.

새 설정을 추가할 때는 공식 [Configuration 문서](https://cmux.com/docs/configuration)와 [cmux.schema.json](https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json)을 확인하고, dotfiles에서 실제로 강제할 값만 이 문서에 남긴다. 프로젝트 단위 actions/commands/UI 오버라이드는 repo 루트의 `.cmux/cmux.json`에서 관리한다.

## ghostty/config 메모 (cmux 전용 권장)

cmux 내장 Ghostty는 표준 Ghostty 설정을 그대로 읽는다. cmux 환경 특화 권장값:

- `window-show-tab-bar = never` — cmux가 세로 탭을 제공하므로 네이티브 탭바 중복 제거.
- `unfocused-split-*` / `split-divider-color` — 멀티 split(병렬 에이전트) 시 활성/비활성 패널 시각 구분.
- 폰트/패딩/투명도/`shell-integration` 등은 일반 Ghostty와 동일.
- 주의: `macos-option-as-alt = true`는 일부 비US 키보드에서 Option+키 조합 입력과 충돌할 수 있다(커뮤니티 Issue #1657).

## 유용한 기능 · 팁

- **CLI 소켓 제어**: `socketControlMode=allowAll` 덕에 `cmux new-workspace`, `cmux new-split right`, `cmux notify --title "Done" --body "작업 완료"` 등 CLI로 워크스페이스/패널/알림을 스크립트화할 수 있다.
- **에이전트 lifecycle 훅**: Claude Code 등의 lifecycle 훅에서 에이전트 완료 순간 `cmux notify`를 발사해 알림을 받을 수 있다.
- **패널 상태 링**: 패널 테두리 색으로 상태 파악(작업중/완료 green/에러 red).
- **프로젝트별 설정**: 레포 루트의 `.cmux/cmux.json`으로 프로젝트 단위 오버라이드(actions/commands/UI).
- **워크스페이스 색**: `workspaceColors`로 작업별 색을 지정해 다수 세션을 한눈에 구분.
- **재시작 없는 리로드**: 설정 변경 후 `cmux reload-config` 또는 `Cmd+Shift+,`.

## 제약

- **앱 종료 시 프로세스 상태**: 레이아웃·작업 디렉터리는 복원된다. Claude Code처럼 cmux가 session ID를 캡처한 지원 에이전트는 통합 훅과 자동 재개가 활성화된 경우 재개할 수 있지만, 일반 dev server와 임의 프로세스의 메모리 상태는 복원되지 않는다.

## 참고

- 검증 기준: cmux 0.64.x, 2026-06-30.
- 출처: [cmux Configuration](https://cmux.com/docs/configuration) · [CLI API](https://cmux.com/docs/api) · [Session restore](https://cmux.com/docs/session-restore) · [cmux.schema.json](https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json) · [Issue #1657 (ghostty config)](https://github.com/manaflow-ai/cmux/issues/1657) · [Discussion #2531 (cmux/ghostty 설정 분리)](https://github.com/manaflow-ai/cmux/discussions/2531)
