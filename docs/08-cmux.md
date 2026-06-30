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

**cmux.json** (`automation.socketControlMode` 등 일부만 강제, 나머지는 GUI 폴백)

| 키 | 값 | 의도 |
|---|---|---|
| `automation.socketControlMode` | `allowAll` | 외부 도구의 소켓 제어 허용 (CLI/자동화) |
| `automation.claudeCodeIntegration` | `true` | Claude Code 통합 훅 활성화 (기본 on을 명시적으로 보장) |
| `automation.workspaceAutoNaming` | `true` | 에이전트 대화 기반 워크스페이스/탭 자동 명명 |
| `automation.autoNamingAgent` | `claude` | 자동 명명 주체를 Claude로 고정 |
| `terminal.agentHibernation.enabled` | `true` | 유휴 에이전트 일시중단으로 자원 절약 |

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

## cmux.json 전체 설정 레퍼런스

cmux 0.64.x 기준. 기본값은 공식 [Configuration 문서](https://cmux.com/docs/configuration) / 스키마 기준. 강제하지 않은 키는 모두 기본값/GUI를 따른다.

### app — 앱 전반

| 키 | 설명 | 기본값 |
|---|---|---|
| `language` | UI 언어 | `"system"` |
| `appearance` | 라이트/다크/시스템 | `"system"` |
| `appIcon` | Dock 아이콘 스타일 | `"automatic"` |
| `windowTitleTemplate` | 창 제목 포맷 | `""` |
| `menuBarOnly` | Dock 아이콘 숨기고 메뉴바만 | `false` |
| `newWorkspacePlacement` | 새 워크스페이스 위치: `top`/`afterCurrent`/`end` | `"afterCurrent"` |
| `workspaceInheritWorkingDirectory` | 현재 디렉터리 상속 | `true` |
| `minimalMode` | 워크스페이스 타이틀바 숨김 | `false` |
| `keepWorkspaceOpenWhenClosingLastSurface` | 마지막 패널 닫아도 워크스페이스 유지 | `false` |
| `focusPaneOnFirstClick` | 첫 클릭으로 cmux 활성화+포커스 | `true` |
| `openSupportedFilesInCmux` | 지원 파일을 cmux 미리보기로 | `true` |
| `openMarkdownInCmuxViewer` | `.md`를 마크다운 뷰어로 | `true` |
| `globalFontMagnification` | UI 전체 배율(%) 50–200 | `100` |
| `reorderOnNotification` | 알림 워크스페이스 상단 이동 | `true` |
| `iMessageMode` | 에이전트 프롬프트 전송 시 상단 이동 | `false` |
| `confirmQuit` | 종료 확인: `always`/`dirty-only`/`never` | `"always"` |
| `preferredEditor` | 파일 열기용 에디터 명령 | `""` |

### automation — 에이전트 통합 / 소켓 제어

| 키 | 설명 | 기본값 |
|---|---|---|
| `socketControlMode` | 소켓 접근: `off`/`cmuxOnly`/`automation`/`password`/`allowAll` | `"cmuxOnly"` |
| `socketPassword` | password 모드용 비밀번호(`null`=해제) | `""` |
| `claudeCodeIntegration` | Claude Code 훅 활성화 | `true` |
| `claudeBinaryPath` | `claude` 바이너리 경로 | `""` |
| `workspaceAutoNaming` | 대화 기반 워크스페이스 AI 자동 명명 | `false` |
| `autoNamingAgent` | 명명 에이전트: `"auto"` 또는 슬러그 | `"auto"` |
| `ripgrepBinaryPath` | `rg` 바이너리 경로 | `""` |
| `suppressSubagentNotifications` | 하위 에이전트 알림 억제 | `true` |
| `ampIntegration` / `cursorIntegration` / `geminiIntegration` / `kiroIntegration` | 각 도구 훅 | `true` |
| `kiroNotificationLevel` | Kiro 이벤트: `minimal`/`standard`/`verbose` | `"standard"` |
| `portBase` | 워크스페이스 `CMUX_PORT` 시작값 | `9100` |
| `portRange` | 워크스페이스당 예약 포트 수 | `10` |

### terminal — 터미널 렌더링/동작

| 키 | 설명 | 기본값 |
|---|---|---|
| `showScrollBar` | 우측 스크롤바 표시 | `true` |
| `scrollSpeed` | 스크롤 배율 0.25–3.0 | `1` |
| `copyOnSelect` | 선택 시 자동 복사 | `false` |
| `autoResumeAgentSessions` | 재오픈 시 에이전트 세션 자동 재개 | `true` |
| `showTextBoxOnNewTerminals` / `focusTextBoxOnNewTerminals` | TextBox 입력 표시/포커스 | `false` |
| `textBoxMaxLines` | TextBox 최대 줄 1–20 | `10` |
| `agentHibernation.enabled` | 유휴 백그라운드 에이전트 일시중단 | `false` |
| `agentHibernation.idleSeconds` | 일시중단 전 유휴 시간(초) 5–604800 | `5` |
| `agentHibernation.maxLiveTerminals` | 동시 활성 에이전트 한도 1–256 | `12` |

### notifications — 알림

| 키 | 설명 | 기본값 |
|---|---|---|
| `dockBadge` | Dock 미읽음 배지 | `true` |
| `showInMenuBar` | 메뉴바 표시 | `true` |
| `unreadPaneRing` | 미읽음 패널 링 강조 | `true` |
| `paneFlash` | 알림 시 패널 플래시 | `true` |
| `suppressOnlyFocusedSurface` | 정확히 포커스된 surface만 배너 억제 | `false` |
| `sound` | 사운드 프리셋 / `custom_file` / `none` | `"default"` |
| `customSoundFilePath` | 커스텀 사운드 경로 | `""` |
| `command` | 알림 시 실행할 셸 명령 | `""` |
| `hooksMode` | 훅 결합: `append`/`replace` | `"append"` |
| `hooks` | 알림 JSON을 stdin으로 받는 셸 훅 배열 | `[]` |

### sidebar — 사이드바 표시

| 키 | 설명 | 기본값 |
|---|---|---|
| `hideAllDetails` | 워크스페이스 상세 행 숨김 | `false` |
| `wrapWorkspaceTitles` | 제목 줄바꿈 허용 | `false` |
| `showWorkspaceDescription` | 워크스페이스 설명 표시 | `true` |
| `branchLayout` | git 브랜치: `vertical`/`inline` | `"vertical"` |
| `showNotificationMessage` | 최근 알림 텍스트 | `true` |
| `showBranchDirectory` | 작업 디렉터리 표시 | `true` |
| `showPullRequests` / `makePullRequestsClickable` / `openPullRequestLinksInCmuxBrowser` | PR 메타데이터/링크 | `true` |
| `watchGitStatus` | 폴링 대신 파일 감시 | `true` |
| `showSSH` / `showPorts` / `showLog` / `showProgress` | SSH/포트/로그/진행 표시 | `true` |
| `rightMaxWidth` | 사이드바 최대 너비(pt) | `none` |

### browser — 내장 브라우저

| 키 | 설명 | 기본값 |
|---|---|---|
| `defaultSearchEngine` | `google`/`duckduckgo`/`bing`/`kagi`/`custom` | `"google"` |
| `customSearchEngineName` / `customSearchEngineURLTemplate` | 커스텀 검색(`{query}` 치환) | — |
| `showSearchSuggestions` | 옴니바 제안 | `true` |
| `theme` | `system`/`light`/`dark` | `"system"` |
| `discardHiddenWebViews` / `hiddenWebViewDiscardDelaySeconds` | 숨김 탭 메모리 회수 | `true` / `300` |
| `openTerminalLinksInCmuxBrowser` | 터미널 링크를 내장 브라우저로 | `true` |
| `interceptTerminalOpenCommandInCmuxBrowser` | 터미널 `open` 명령 가로채기 | `true` |
| `hostsToOpenInEmbeddedBrowser` / `urlsToAlwaysOpenExternally` | 내장/외부 강제 호스트 | `[]` |

### workspaceColors — 워크스페이스 색

멀티 에이전트 환경에서 워크스페이스를 색으로 구분할 때 유용.

| 키 | 설명 | 기본값 |
|---|---|---|
| `indicatorStyle` | 활성 표시: `leftRail`/`solidFill`/`border`/`wash` 등 | `"leftRail"` |
| `colors` | 이름→HEX 색 팔레트 | 내장 16색 |

```json
{ "workspaceColors": { "colors": { "Red": "#C0392B", "Blue": "#1565C0" } } }
```

### 그 외 섹션

| 섹션 | 주요 키 (기본값) |
|---|---|
| `sidebarAppearance` | `matchTerminalBackground`(false), `tintColor`("#000000"), `tintOpacity`(0.03) |
| `markdown` | `fontSize`(15), `fontFamily`(""), `maxWidth`(980) |
| `fileEditor` | `wordWrap`(false) |
| `fileExplorer` | `doubleClickAction`: `preview`/`defaultEditor`/`preferredEditor` (preview) |
| `workspaceGroups` | `byCwd`(경로 글롭별 설정), `newWorkspacePlacement` |
| `canvas` | `paneGap`(16), `snappingEnabled`(true) |

## 키보드 단축키 커스터마이즈

`shortcuts.bindings`에서 액션을 단일 키(`"cmd+k"`), chord 배열(`["ctrl+b","c"]`), 또는 `null`(해제)로 바인딩. `shortcuts.when`으로 컨텍스트 조건 지정.

```json
{
  "shortcuts": {
    "bindings": { "toggleSidebar": "cmd+b", "newTab": ["ctrl+b", "c"] },
    "when": { "selectWorkspaceByNumber": "!sidebarFocus" }
  }
}
```

주요 기본 단축키: 설정 `Cmd+,` · 설정 리로드 `Cmd+Shift+,` · 명령 팔레트 `Cmd+Shift+P` · 사이드바 토글 `Cmd+B` · 새 탭 `Cmd+N` · 워크스페이스 1–9 `Cmd+1~9` · 우측 split `Cmd+D` · 하단 split `Cmd+Shift+D` · split 줌 `Cmd+Shift+Return` · 브라우저 `Cmd+Shift+L` · 찾기 `Cmd+F` · 알림 `Cmd+I`.

`when` 컨텍스트 키: `sidebarFocus`/`browserFocus`/`terminalFocus`(불리언), `sidebarMode`(`files`/`find`/`sessions`/`feed`/`dock`), `paneCount`/`workspaceCount`(정수). 연산자 `!`, `&&`, `||`, `==`, `=~`, 비교, `in [a,b]`.

## ghostty/config 메모 (cmux 전용 권장)

cmux 내장 Ghostty는 표준 Ghostty 설정을 그대로 읽는다. cmux 환경 특화 권장값:

- `window-show-tab-bar = never` — cmux가 세로 탭을 제공하므로 네이티브 탭바 중복 제거.
- `unfocused-split-*` / `split-divider-color` — 멀티 split(병렬 에이전트) 시 활성/비활성 패널 시각 구분.
- 폰트/패딩/투명도/`shell-integration` 등은 일반 Ghostty와 동일.
- 주의: `macos-option-as-alt = true`는 일부 비US 키보드에서 Option+키 조합 입력과 충돌할 수 있다(커뮤니티 Issue #1657).

## 유용한 기능 · 팁

- **CLI 소켓 제어**: `socketControlMode=allowAll` 덕에 `cmux workspace new`, `cmux split right`, `cmux notify --title "Done" --body "작업 완료"` 등 CLI로 워크스페이스/패널/알림을 스크립트화할 수 있다.
- **에이전트 lifecycle 훅**: Claude Code 등의 lifecycle 훅에서 에이전트 완료 순간 `cmux notify`를 발사해 알림을 받을 수 있다.
- **패널 상태 링**: 패널 테두리 색으로 상태 파악(작업중/완료 green/에러 red).
- **프로젝트별 설정**: 레포 루트의 `.cmux/cmux.json`으로 프로젝트 단위 오버라이드(actions/commands/UI).
- **워크스페이스 색**: `workspaceColors`로 작업별 색을 지정해 다수 세션을 한눈에 구분.
- **재시작 없는 리로드**: 설정 변경 후 `cmux reload-config` 또는 `Cmd+Shift+,`.

## 제약

- **앱 종료 시 실행 프로세스 종료**: 레이아웃·메타데이터는 복원되지만 Claude Code 세션과 dev 서버는 복원되지 않아 수동 재시작이 필요하다. 전체 재시작이 필요한 작업은 실행 중 세션을 고려해 진행한다.

## 참고

- 검증 기준: cmux 0.64.x, 2026-06-30.
- 출처: [cmux Configuration](https://cmux.com/docs/configuration) · [cmux.schema.json](https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json) · [Issue #1657 (ghostty config)](https://github.com/manaflow-ai/cmux/issues/1657) · [Discussion #2531 (cmux/ghostty 설정 분리)](https://github.com/manaflow-ai/cmux/discussions/2531)
