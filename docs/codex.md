# dotfiles

## 범위

- macOS를 기준으로 시스템, 터미널, AI 도구(Claude, Codex, OpenCode, OpenClaw, Copilot) 환경을 일관되게 구성한다.
- Linux는 동일한 구조를 유지하되, 기초 패키지/셸/AI 런타임 중심으로 최소 구성을 보장한다.
- 지정된 14개 저장소는 공식 문서와 저장소 본문 기준으로 검증 후, 유지 가능한 항목만 선별 반영한다.
- 설치와 운영은 chezmoi 선언형 구조를 기준으로 모듈화한다.

## 검증 기준

- 기준일: 2026-02-16
- 검증 우선순위:

1. 공식 문서
2. 공식 저장소 README 및 핵심 가이드
3. 구현 소스(경로/탐색 규칙 등 동작 기준)

- 검증 완료 범위:

1. chezmoi special files, templates, scripts, 변수 체계
2. twpayne/dotfiles의 최소 엔트리 구조와 비밀정보 외부 의존 원칙
3. zerobrew, Ghostty, Claude 생태계 플러그인/스킬, Codex/OpenCode/OpenClaw 설정 체계
4. Claude/Codex/OpenCode/Copilot 스킬 경로 규칙
5. OpenClaw 플러그인 manifest 요구사항과 plugin tool 구조

## 설계 원칙

- 선언형 우선: 설치 대상은 파일 선언, 실행은 단계별 스크립트로 분리한다.
- 멱등성 유지: 재적용 시 결과가 동일하도록 상태 점검 기반으로 설계한다.
- 단계 고정: 시스템 → 터미널 → AI 코어 → 도구별 설정 → 스킬/메모리 순으로 실행한다.
- OS 분리: macOS와 Linux 스크립트 레이어를 분리하고, 공통 정책만 공유한다.
- 모듈화: AI 설정은 단일 스크립트로 묶지 않고 기능 단위로 분리한다.
- 복구 가능성: 실패 지점을 태스크 단위로 격리해 부분 재실행이 가능해야 한다.
- 문서-구성 정합성: 파일 트리, 스크립트 레이어, 운영 체크 항목을 동일 모델로 유지한다.

## 파일 트리

```text
dotfiles/
├── .chezmoiroot
├── .chezmoiversion
├── install.sh
├── docs/
│   ├── dotfiles.md
│   ├── dotfiles-claude.md
│   ├── dotfiles-claude2.md
│   ├── dotfiles-claude3.md
│   ├── dotfiles-codex.md
│   ├── dotfiles-codex2.md
│   ├── dotfiles-codex3.md
│   └── dotfiles-codex4.md
└── home/
    ├── .chezmoi.toml.tmpl
    ├── .chezmoiignore
    ├── .chezmoiexternal.toml
    ├── .chezmoiremove
    ├── .chezmoiscripts/
    │   ├── darwin/
    │   │   ├── run_once_before_01-prerequisites.sh.tmpl
    │   │   ├── run_onchange_after_02-macos-settings.sh.tmpl
    │   │   ├── run_onchange_03-brew-packages.sh.tmpl
    │   │   ├── run_once_04-runtime.sh.tmpl
    │   │   ├── ai/
    │   │   │   ├── run_once_10-ai-core.sh.tmpl
    │   │   │   ├── run_once_11-ai-claude.sh.tmpl
    │   │   │   ├── run_once_12-ai-codex.sh.tmpl
    │   │   │   ├── run_once_13-ai-opencode.sh.tmpl
    │   │   │   ├── run_once_14-ai-openclaw.sh.tmpl
    │   │   │   ├── run_once_15-ai-skills.sh.tmpl
    │   │   │   └── run_onchange_16-ai-mcp.sh.tmpl
    │   │   └── run_once_after_99-manual-install.sh
    │   └── linux/
    │       ├── run_once_before_01-install-packages.sh.tmpl
    │       ├── run_onchange_02-shell-baseline.sh.tmpl
    │       ├── run_onchange_03-git-baseline.sh.tmpl
    │       ├── run_once_04-ai-tools.sh.tmpl
    │       └── run_onchange_05-system-baseline.sh.tmpl
    ├── Brewfile
    ├── dot_zshrc.tmpl
    ├── dot_gitconfig.tmpl
    ├── dot_gitignore_global
    ├── dot_vimrc
    ├── AGENTS.md.tmpl
    ├── dot_claude.json.tmpl
    ├── dot_claude/
    │   ├── settings.json.tmpl
    │   └── hooks/
    ├── dot_codex/
    │   ├── AGENTS.md.tmpl
    │   ├── config.toml.tmpl
    │   └── prompts/
    ├── dot_config/
    │   ├── ghostty/
    │   │   └── config.tmpl
    │   └── opencode/
    │       ├── opencode.json.tmpl
    │       ├── oh-my-opencode.jsonc.tmpl
    │       ├── plugins/
    │       └── skills/
    ├── dot_agents/
    │   └── skills/
    ├── dot_copilot/
    │   └── skills/
    ├── dot_openclaw/
    │   ├── openclaw.json.tmpl
    │   └── workspace/
    │       ├── AGENTS.md.tmpl
    │       ├── SOUL.md.tmpl
    │       └── TOOLS.md.tmpl
    └── dot_local/bin/
        └── executable_dotfiles-doctor
```

## chezmoi special 파일

| 파일                      | 역할              |
|-------------------------|-----------------|
| `.chezmoiroot`          | 소스 루트 고정        |
| `.chezmoiversion`       | 최소 실행 버전 강제     |
| `.chezmoiignore`        | OS/환경별 제외 대상 제어 |
| `.chezmoiexternal.toml` | 외부 리소스 선언형 동기화  |
| `.chezmoiremove`        | 제거 대상 파일 정리     |

## 실행 레이어

### macOS

| 레이어            | 목적                  | 산출물               |
|----------------|---------------------|-------------------|
| prerequisites  | 필수 도구/패키지 매니저 준비    | 기초 런타임 준비         |
| macos-settings | 시스템 UX/입력/보안 기본값 적용 | 일관된 작업 환경         |
| brew-packages  | Brewfile 기반 패키지 반영  | 시스템 패키지 상태        |
| runtime        | AI 런타임/도구 기반 구성     | AI 실행 기반          |
| ai-core        | 공통 AI 도구 준비         | 공통 CLI 기반         |
| ai-claude      | Claude 계층 설정        | Claude 사용자 환경     |
| ai-codex       | Codex 계층 설정         | Codex 사용자 환경      |
| ai-opencode    | OpenCode 계층 설정      | OpenCode 사용자 환경   |
| ai-openclaw    | OpenClaw 계층 설정      | OpenClaw 게이트웨이 기반 |
| ai-skills      | 공통 스킬 배포            | 도구 간 스킬 일관성       |
| ai-mcp         | MCP 반영/갱신           | 도구 연동 상태          |

- chezmoi 스크립트 속성 순서는 `run_` + (`onchange_`/`once_`) + (`before_`/`after_`)를 따른다.
- `macos-settings`는 파일 배포 이후 적용이므로 `run_onchange_after_02-macos-settings.sh.tmpl`을 사용한다.

### Linux

| 레이어              | 목적                   | 산출물         |
|------------------|----------------------|-------------|
| install-packages | 패키지 관리자 기반 필수 패키지 설치 | 기초 운영 환경    |
| shell-baseline   | 셸/환경변수/로케일 기준 정렬     | 셸 일관성       |
| git-baseline     | Git/SSH 기초 설정        | 버전관리 준비     |
| ai-tools         | 핵심 AI CLI 최소 구성      | AI 작업 가능 상태 |
| system-baseline  | 서비스/시스템 기본값 정리       | 안정적 기본 상태   |

## 설치 흐름

### macOS

1. 선행 의존성 준비
2. 외부 리소스 동기화
3. 시스템 설정 적용
4. 패키지 반영
5. 런타임 정리
6. Claude 적용
7. Codex 적용
8. OpenCode 적용
9. OpenClaw 적용
10. 공통 스킬 배포
11. MCP 반영
12. 수동 확인 항목 점검

### Linux

1. 패키지 관리자 감지 및 필수 패키지 반영
2. 셸/로케일/시간대 기준 정렬
3. Git/SSH 기준 반영
4. AI 도구 최소 구성
5. 시스템 기본값 및 진단 항목 반영

## 템플릿 변수

| 변수                   | 용도              |
|----------------------|-----------------|
| `.chezmoi.os`        | OS 분기           |
| `.chezmoi.arch`      | 아키텍처 분기         |
| `.email`             | Git/도구 사용자 식별   |
| `.name`              | 계정 표시 이름        |
| `.ai.default_model`  | 기본 모델 설정        |
| `.ai.profile`        | 환경별 프로필 분기      |
| `.features.openclaw` | OpenClaw 활성화 분기 |

## Brewfile 패키지

Brewfile은 `brew bundle`로 동기화하고, AI CLI는 공식 문서 기준 설치 채널에 맞춰 별도 AI 스크립트에서 관리한다.

| 대주제    | 소주제          | 상세 패키지                                                 |
|--------|--------------|--------------------------------------------------------|
| 시스템    | 기본 CLI       | bash, zsh, curl, wget, git, gh, jq, tree, gnupg        |
| 시스템    | 개발 보조 CLI    | tmux, ripgrep, fzf, watchman, fswatch, direnv          |
| 런타임    | 언어 런타임       | node, python, go, rust, php, ruby                      |
| 런타임    | 패키지/가상환경     | pipx, uv, bun                                          |
| 데이터/도구 | 데이터/유틸       | sqlite                                                 |
| 터미널/앱  | 터미널          | ghostty                                                |
| 터미널/앱  | GUI 앱 (cask) | docker, iterm2, google-chrome, rectangle, slack, figma |
| AI 코어  | 로컬 모델        | ollama                                                 |

**AI CLI 설치 채널 (공식 문서 확인 기준)**

| 도구       | 필수 | 공식 설치 채널                                                                                                                                                     | 기본 운영 채널                                |
|----------|----|--------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------|
| Claude   | 예  | npm (`npm install -g @anthropic-ai/claude-code`), native installer                                                                                           | npm                                     |
| Codex    | 예  | npm (`npm i -g @openai/codex`), Homebrew (`brew install codex`)                                                                                              | npm                                     |
| OpenCode | 예  | install script (`curl -fsSL https://opencode.ai/install \| bash`), npm (`npm i -g opencode-ai@latest`), Homebrew tap (`brew install anomalyco/tap/opencode`) | Homebrew tap (`anomalyco/tap/opencode`) |
| OpenClaw | 예  | npm (`npm install -g @openclaw/openclaw`)                                                                                                                    | npm                                     |
| Gemini   | 예  | npm (`npm install -g @google/gemini-cli`), Homebrew (`brew install gemini-cli`)                                                                              | npm                                     |

- OpenCode는 공식 문서 기준으로 설치 스크립트가 가장 간단한 진입 경로이며, 운영 채널은 최신 릴리스 추적을 위해 Homebrew 공식 tap(`anomalyco/tap`)을 기본으로 사용한다.

## 외부 리소스

| 리소스                    | 용도              | 반영 방식                               |
|------------------------|-----------------|-------------------------------------|
| superpowers            | 공통 워크플로우 스킬     | Claude, Codex, OpenCode 경로 연동       |
| everything-claude-code | Claude 확장 규칙/스킬 | Claude 플러그인 및 rules 선택 반영           |
| awesome-agent-skills   | 범용 스킬 카탈로그      | Claude/Codex/Copilot/OpenCode 선별 반영 |
| andrej-karpathy-skills | 행동 원칙           | AGENTS 정책 통합                        |
| humanizer              | 글쓰기 스킬          | Claude + Codex 공유 배포                |

## macOS 시스템 설정

- 키 반복/입력 지연, 트랙패드, Dock/Finder 기본값 정렬
- 스크린샷 경로 및 파일 규칙 고정
- 기본 셸/터미널 실행 환경 일관화
- 개발자 도구 권한/기초 보안 옵션 확인

## Linux 기초 설정

- 배포판별 패키지 관리자 차이를 흡수한 공통 기준 유지
- 로케일/타임존/셸 초기화 파일 정렬
- SSH, Git, 에이전트 런타임 경로 정리
- GUI 의존 없이 CLI 중심으로 동작 보장

## 터미널

- zerobrew:
    - Homebrew 패키지 설치 경로와 성능 최적화 레이어를 분리해 운영한다.
    - 실험적 성격을 고려해 core 패키지부터 점진 반영한다.
- Ghostty:
    - 사용자 설정 경로는 XDG와 macOS Application Support를 모두 고려한다.
    - 파일명은 `config`를 기준으로 관리하고, 기본 탐색 경로(`$XDG_CONFIG_HOME/ghostty/config`, `~/.config/ghostty/config`)를 우선 준수한다.

## AI 사용자 설정

### 공통 정책

- AI 설정은 단일 대형 스크립트가 아니라 도구별 모듈로 분리한다.
- 공통 지침은 `AGENTS.md` 중심으로 유지한다.
- 스킬은 공통 저장소에서 선별 후 도구별 경로로 동기화한다.
- MCP는 도구별 공식 지원 위치를 준수한다.

### AGENTS 계층 정책

- 전역: 사용자 홈 범위 지침
- 저장소 루트: 프로젝트 공통 지침
- 하위 디렉토리: 업무 도메인 전용 override 지침
- 호환 파일: `AGENTS.md` 단일 표준 사용

### Claude 사용자 설정

- 사용자 경로:
    - `~/.claude/settings.json`
    - `~/.claude/skills/`
    - `~/.claude/agents/`
    - `~/.claude/commands/`
    - `~/.claude.json` (사용자/로컬 MCP 상태)
- 프로젝트 경로:
    - `.claude/settings.json`
    - `.claude/settings.local.json`
    - `.claude/skills/`
    - `.mcp.json`
- 기본 정책:
    - 플러그인 활성화/비활성화는 `~/.claude/settings.json`의 `enabledPlugins` 필드에서 관리
    - claude-hud 세부 설정은 `~/.claude/plugins/claude-hud/config.json`에서 관리
    - claude-mem 데이터/설정은 `~/.claude-mem/` 경로를 기준으로 관리
    - claude-hud 활성 기본값 유지
    - peon-ping 이벤트 알림 사용, `sc_scv` 포함
    - superpowers, everything-claude-code, karpathy 지침을 충돌 없이 계층 적용

### Codex 사용자 설정

- 사용자 경로:
    - `~/.codex/config.toml`
    - `~/.codex/AGENTS.md`
    - `~/.agents/skills/`
- 프로젝트 경로:
    - `.codex/config.toml`
    - `AGENTS.md`
    - `.agents/skills/`
- 기본 정책:
    - 프로필, 승인정책, MCP, 규칙은 `config.toml` 중심으로 통합 관리
    - 별도 `permissions.toml`, `profiles.toml` 분리 파일은 사용하지 않는다.
    - superpowers와 oh-my-codex의 프롬프트/스킬 계층을 충돌 없이 병행한다.

### OpenCode 사용자 설정

- 사용자 경로:
    - `~/.config/opencode/opencode.json`
    - `~/.config/opencode/skills/`
    - `~/.config/opencode/plugins/`
- 프로젝트 경로:
    - `opencode.json`
    - `.opencode/skills/`
    - `.opencode/skill/` (legacy 호환)
    - `.opencode/plugins/`
- 자동 탐색 경로:
    - `.claude/skills/`
    - `.agents/skills/`
- 기본 정책:
    - oh-my-opencode는 필요한 훅/에이전트/카테고리만 선별 반영
    - superpowers와 공통 스킬 계층을 병행해 사용한다.

### OpenClaw 사용자 설정

- 사용자 경로:
    - `~/.openclaw/openclaw.json`
    - `~/.openclaw/extensions/`
    - `~/.openclaw/workspace/`
- 플러그인 정책:
    - 플러그인 설치 경로는 `~/.openclaw/extensions/<plugin-id>/`를 기준으로 한다.
    - 모든 플러그인은 `openclaw.plugin.json` manifest를 포함해야 한다.
    - manifest의 `id`와 `configSchema`는 필수다.
    - memory 계열은 `plugins.slots` 정책으로 단일 활성 상태를 유지한다.
- 메모리 정책:
    - claude-mem 공식 데이터 디렉토리는 `~/.claude-mem/`이며, 필요 시 `CLAUDE_MEM_DATA_DIR`로 재정의할 수 있다.
    - claude-mem 연동 시 장기 메모리 저장 범위와 민감정보 제외 규칙을 분리 관리한다.
    - OpenClaw는 기능/구조 변경이 잦으므로 적용 전 반드시 `https://docs.openclaw.ai` 최신 문서를 재검증한다.

### Copilot 사용자 설정

- 사용자 경로:
    - `~/.copilot/skills/`
- 프로젝트 경로:
    - `.github/skills/`
    - `.claude/skills/` 호환 경로 허용
- 기본 정책:
    - awesome-agent-skills에서 Copilot 호환 스킬만 선별 반영

## 처리 순서

### Phase 1. 시스템

#### Task 1. zerobrew

- 검증 포인트:
    - macOS/Linux 지원 범위
    - 실험적 상태와 운영 안정성 경계
- 반영 범위:
    - core 패키지 우선 적용
    - Brewfile 기반 선언형 구조 유지
- 산출물:
    - zerobrew 반영 스크립트
    - 패키지 레이어 분류 기준

#### Task 2. ghostty

- 검증 포인트:
    - 공식 설치 경로와 커뮤니티 패키지 경로
    - 구성 파일 위치와 파일명 규칙
- 반영 범위:
    - XDG/macOS 경로 동시 대응
    - 단일 테마/키바인딩 정책 파일화
- 산출물:
    - `dot_config/ghostty/` 설정 템플릿
    - macOS/Linux 공통 터미널 기본값

### Phase 2. Claude

#### Task 3. peon-ping

- 검증 포인트:
    - Claude/Codex/OpenCode adapter 지원
    - CESP 이벤트 카테고리
- 반영 범위:
    - 기본 알림 정책 + `sc_scv` 포함
    - 사용자별 볼륨/카테고리 제어 항목
- 산출물:
    - Claude 훅 계층 설정
    - 공통 알림 정책 문서화

#### Task 4. superpowers

- 검증 포인트:
    - Claude 플러그인 마켓플레이스 경로
    - Codex/OpenCode 수동 연동 구조
- 반영 범위:
    - Claude 기본 플러그인
    - Codex/OpenCode 스킬 경로 연결
- 산출물:
    - Claude/Codex/OpenCode 공통 워크플로우 스킬 계층

#### Task 5. everything-claude-code

- 검증 포인트:
    - rules 수동 설치 필요성
    - 훅/에이전트/명령 구성 규모
- 반영 범위:
    - 전체 복제 대신 언어별 rules 선별 적용
    - 충돌 가능한 고강도 자동화 훅은 선택 적용
- 산출물:
    - Claude rules 모듈 구성
    - 에이전트/명령 기본 세트

#### Task 6. claude-hud

- 검증 포인트:
    - statusline 기반 구조
    - 설정 파일 경로
- 반영 범위:
    - Claude 기본 HUD 활성
    - Codex/OpenCode에는 기본 강제 적용하지 않음
- 산출물:
    - HUD 기본 프리셋
    - 표시 항목 정책

#### Task 7. humanizer

- 검증 포인트:
    - SKILL.md 기반 단일 스킬 구조
- 반영 범위:
    - Claude 스킬 배포
    - 동일 스킬을 Codex 경로에도 동기화
- 산출물:
    - 공통 글쓰기 정제 스킬

#### Task 8. awesome-agent-skills

- 검증 포인트:
    - Claude/Codex/Copilot/OpenCode 경로 규칙
    - 대규모 카탈로그 선별 운영 필요성
- 반영 범위:
    - 4개 도구 공통 필수 스킬만 큐레이션
    - 도메인별 스킬 목록 버전 고정
- 산출물:
    - `dot_agents/skills/`
    - `dot_copilot/skills/`
    - `dot_config/opencode/skills/`
    - `dot_claude/skills/`

#### Task 9. andrej-karpathy-skills

- 검증 포인트:
    - `CLAUDE.md` 행동 원칙
    - AGENTS 표준 기반 지침 통합
- 반영 범위:
    - 4대 원칙을 공통 AGENTS 지침에 통합
    - 글로벌/프로젝트/하위 경로 계층 정책에 반영
- 산출물:
    - `AGENTS.md.tmpl`

### Phase 3. OpenCode

#### Task 10. opencode

- 검증 포인트:
    - 글로벌/프로젝트 config merge 구조
    - skills/skill 복수 경로 지원
- 반영 범위:
    - 글로벌 `opencode.json` 기준 구성
    - 프로젝트 `.opencode` 확장 계층 활성
- 산출물:
    - `dot_config/opencode/opencode.json.tmpl`
    - OpenCode 기본 에이전트/권한 정책

#### Task 11. oh-my-opencode

- 검증 포인트:
    - 대규모 기능 묶음 구조
    - Claude 호환 레이어, 훅, MCP 포함 여부
- 반영 범위:
    - 필수 기능만 선별 반영
    - 과도한 자동화/실험 기능은 기본 비활성
- 산출물:
    - `oh-my-opencode.jsonc` 오버레이
    - OpenCode 확장 정책 문서화

#### Task 12. oh-my-codex

- 검증 포인트:
    - Codex 프롬프트/스킬/오케스트레이션 계층
    - AGENTS 기반 운영 구조
- 반영 범위:
    - 프롬프트와 스킬 핵심 세트 반영
    - 팀 오케스트레이션은 선택 기능으로 분리
- 산출물:
    - `dot_codex/prompts/`
    - `dot_agents/skills/` 보강

### Phase 4. OpenClaw

#### Task 13. openclaw

- 검증 포인트:
    - Gateway 중심 아키텍처
    - 플러그인 manifest + schema 검증 모델
- 반영 범위:
    - gateway/workspace/extensions 구조 표준화
    - 채널/도구/플러그인 정책 분리
- 산출물:
    - `dot_openclaw/openclaw.json.tmpl`
    - `dot_openclaw/workspace/*`

#### Task 14. claude-mem

- 검증 포인트:
    - Claude 플러그인 기반 지속 메모리 모델
    - OpenClaw 연동 경로 제공
- 반영 범위:
    - OpenClaw 메모리 슬롯과 충돌 없는 연동
    - 민감정보 제외 규칙과 메모리 주입 정책 분리
- 산출물:
    - `~/.claude-mem/` 운영 정책 문서
    - OpenClaw 연동 절차(`install.cmem.ai/openclaw.sh`) 문서

## AI 스킬 경로 정책

| 도구       | 사용자 경로                       | 프로젝트 경로                                         | 필수 |
|----------|------------------------------|-------------------------------------------------|----|
| Claude   | `~/.claude/skills/`          | `.claude/skills/`                               | 예  |
| Codex    | `~/.agents/skills/`          | `.agents/skills/`                               | 예  |
| Copilot  | `~/.copilot/skills/`         | `.github/skills/` 또는 `.claude/skills/`          | 예  |
| OpenCode | `~/.config/opencode/skills/` | `.opencode/skills/`, `.opencode/skill/`(legacy) | 예  |

## 플러그인/훅 정책

| 영역               | 정책                                                          |
|------------------|-------------------------------------------------------------|
| Claude hooks     | `settings.json` 계층(User/Project/Local) 준수                   |
| Claude MCP       | 프로젝트 `.mcp.json`, 사용자 `~/.claude.json` 분리 운영                |
| Codex config     | `config.toml` 중심 단일 진실 원천 유지                                |
| OpenCode plugins | `~/.config/opencode/plugins/`와 프로젝트 `.opencode/plugins/` 병행 |
| OpenClaw plugins | manifest 필수, schema 검증 통과 필수                                |

## dotfiles-doctor 검증 항목

- chezmoi 버전 및 special 파일 존재 여부
- macOS/Linux 스크립트 레이어 누락 여부
- Ghostty 설정 파일 경로 유효성
- Claude 설정 계층(User/Project/Local) 충돌 여부
- Codex `config.toml` 유효성 및 프로필 선언 누락 여부
- OpenCode config merge 및 skill 탐색 경로 유효성
- OpenClaw plugin manifest/schema 검증 상태
- 공통 스킬 4개 경로(Claude/Codex/Copilot/OpenCode) 동기화 상태
- AGENTS 계층(전역/루트/하위 override) 로딩 검증

## 운영 체크리스트

- 시스템 레이어 적용 후 AI 레이어 적용 순서 준수
- 외부 리소스 동기화 주기 관리
- 스킬 카탈로그 선별 목록 정기 점검
- MCP 서버별 권한 범위 점검
- Linux 기초 레이어 누락 점검
- OpenClaw 플러그인 업데이트 시 schema 재검증

## 문서 규칙

- 구조 변경 시 파일 트리 먼저 갱신
- AI 설정 변경 시 Claude/Codex/OpenCode/OpenClaw/Copilot 경로를 함께 갱신
- 스킬 추가 시 사용자/프로젝트 경로를 동시에 명시
- 검증 기준일과 참고 링크를 함께 유지

## 참고

- https://www.chezmoi.io/
- https://www.chezmoi.io/reference/special-files/
- https://www.chezmoi.io/reference/special-directories/
- https://www.chezmoi.io/reference/source-state-attributes/
- https://www.chezmoi.io/reference/templates/variables/
- https://github.com/twpayne/dotfiles
- https://github.com/lucasgelfond/zerobrew
- https://ghostty.org/docs/config
- https://ghostty.org/docs/install/binary
- https://github.com/ghostty-org/ghostty
- https://code.claude.com/docs/en/settings
- https://code.claude.com/docs/en/hooks
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/plugin-marketplaces
- https://docs.claude.com/en/docs/claude-code/setup
- https://github.com/PeonPing/peon-ping
- https://github.com/obra/superpowers
- https://github.com/affaan-m/everything-claude-code
- https://github.com/jarrodwatts/claude-hud
- https://github.com/blader/humanizer
- https://github.com/VoltAgent/awesome-agent-skills
- https://github.com/forrestchang/andrej-karpathy-skills
- https://developers.openai.com/codex/config-basic
- https://developers.openai.com/codex/config-reference
- https://developers.openai.com/codex/skills
- https://developers.openai.com/codex/guides/agents-md
- https://github.com/openai/codex
- https://github.com/anomalyco/opencode
- https://opencode.ai/docs/config/
- https://opencode.ai/docs/skills
- https://opencode.ai/docs/getting-started/installation
- https://github.com/code-yeongyu/oh-my-opencode
- https://github.com/Yeachan-Heo/oh-my-codex
- https://github.com/openclaw/openclaw
- https://docs.openclaw.ai
- https://docs.openclaw.ai/plugin
- https://docs.openclaw.ai/plugins/manifest
- https://docs.openclaw.ai/tools/plugin
- https://github.com/thedotmack/claude-mem
- https://docs.claude-mem.ai/installation
- https://github.com/google-gemini/gemini-cli
- https://docs.github.com/copilot/concepts/agents/about-agent-skills
