# AI 도구 설정

## 공통 원칙

- **인증 정보 보안**: 인증 정보는 사용자 홈 범위의 보안 저장소(환경 변수, OS 키체인)에 유지한다. 설정 파일에 API 키나 토큰을 직접 기재하지 않는다.
- **기본 제한 정책**: 워크스페이스 권한은 기본 제한 정책에서 시작한다. 필요한 권한만 명시적으로 허용하여, 의도하지 않은 파일 수정이나 시스템 변경을 방지한다.
- **템플릿 관리**: 모든 설정 파일은 `.tmpl`로 관리하여 OS, 아키텍처, 사용자 정보에 따른 환경별 분기가 가능하다.

## 모듈화 기준

- 코어 설치(10)에서 공식 AI CLI 4종을 설치하고, 프로바이더별 확장 스크립트(11~14)에서 MCP, 스킬, 플러그인을 독립 관리한다.
- 공식 AI CLI(10번대)와 외부 오픈소스 도구(20번대)를 번호 대역으로 구분한다.
- 서비스별 설정 파일(`settings.json`, `config.toml` 등)과 실행 스크립트(`ai-claude.sh`, `ai-codex.sh` 등)를 분리한다.
- 인증, 프로필, 권한, 확장(플러그인/스킬) 항목을 독립적으로 관리하여, 하나의 변경이 다른 항목에 영향을 주지 않는다.
- AI 설정 변경이 단일 모듈에 국한되도록 구성하여, 변경 범위를 예측할 수 있다.

## 스킬 배포

공통 스킬을 각 도구의 글로벌 스킬 경로에 배포한다. 스킬 형식은 SKILL.md 기반으로 도구에 무관하게 동일하다.

| 도구             | 글로벌 스킬 경로                                                              | 프로젝트 스킬 경로                                                | 배포 방식                                     |
|----------------|------------------------------------------------------------------------|-----------------------------------------------------------|-------------------------------------------|
| Claude Code    | `~/.claude/skills/`                                                    | `.claude/skills/`                                         | `.chezmoiexternal.toml`로 humanizer 자동 동기화 |
| Codex          | `~/.agents/skills/`                                                    | `.agents/skills/`                                         | `.chezmoiexternal.toml`로 humanizer 자동 동기화 |
| Gemini         | `~/.gemini/skills/`                                                    | -                                                         | ai-gemini 스크립트에서 superpowers copy         |
| GitHub Copilot | `~/.copilot/skills/`                                                   | `.github/skills/`, `.claude/skills/`                      | ai-copilot 스크립트에서 superpowers copy        |
| OpenCode       | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | `.opencode/skills/`, `.claude/skills/`, `.agents/skills/` | ai-opencode 스크립트에서 superpowers copy       |

**스킬 소스**:

- **humanizer**: AI 글쓰기 패턴 제거 스킬. AI 특유의 과도한 수식어, 반복 구조, 형식적 표현을 자연스러운 문장으로 교정한다. Claude와 Codex는 `.chezmoiexternal.toml`
  로 자동 배포된다.
- **superpowers**: 브레인스토밍, TDD, 코드 리뷰, 서브에이전트 기반 개발 등 12종+ 스킬. ai-core(10)에서 ~/superpowers에 한 번 clone하고,
  Codex/Gemini/Copilot/OpenCode 각 프로바이더 스크립트에서 도구별 스킬 경로로 복사하여 개별 커스텀 가능. Claude는 플러그인 마켓플레이스로 설치.
- **andrej-karpathy-skills**: 코딩 행동 지침 4대 원칙. Claude에서는 플러그인 마켓플레이스로 설치하고, Codex에서는 config.toml의 모델 지침으로 적용한다.

## AGENTS.md

`AGENTS.md.tmpl`은 홈 루트에 배포된다:

| 배포 위치 | 대상 경로         | 참조 도구           | 적용 범위                 |
|-------|---------------|-----------------|-----------------------|
| 홈 루트  | `~/AGENTS.md` | Codex, OpenCode | 프로젝트(홈 디렉토리) 수준 공통 지침 |

**계층 우선순위**: 하위 경로의 AGENTS.md가 상위를 override한다. Codex와 OpenCode가 실제로 따르는 탐색 순서:

| 우선순위 | 범위      | 경로 예시                | 역할                          |
|:----:|---------|----------------------|-----------------------------|
|  1   | 하위 디렉토리 | `src/api/AGENTS.md`  | 특정 도메인 전용 지침 (최우선 override) |
|  2   | 저장소 루트  | `./AGENTS.md`        | 프로젝트 공통 지침                  |
|  3   | 사용자 홈   | `~/AGENTS.md`        | 사용자 전역 기본 지침                |
|  4   | 도구 글로벌  | `~/.codex/AGENTS.md` | 도구 전용 글로벌 지침 (Codex만 해당)    |

**포함 내용**:

| 항목                    | 출처                                 | 상세                               |
|-----------------------|------------------------------------|----------------------------------|
| Think Before Coding   | andrej-karpathy-skills (CLAUDE.md) | 코드를 작성하기 전에 전체 맥락을 이해하고 계획을 수립   |
| Simplicity First      | andrej-karpathy-skills (CLAUDE.md) | 가장 단순한 해결책을 우선 선택하고 불필요한 복잡성을 회피 |
| Surgical Changes      | andrej-karpathy-skills (CLAUDE.md) | 변경 범위를 최소화하고 관련 없는 코드를 수정하지 않음   |
| Goal-Driven Execution | andrej-karpathy-skills (CLAUDE.md) | 사용자의 목표에 집중하여 불필요한 확장을 방지        |
| 도구 공통 운영 규칙           | 프로젝트 공통 정의                         | 각 AI 도구에서 공유하는 작업 규칙과 출력 형식      |

## Claude Code

**설치 (스크립트)**

| 스크립트         | 내용                       | 설치 대상                |
|--------------|--------------------------|----------------------|
| 10-ai-core   | Claude Code (공식 설치 스크립트) | Claude Code CLI 바이너리 |
| 11-ai-claude | SuperClaude (pipx)       | CLI 확장 프레임워크         |

**설정 (dot_claude/ → ~/.claude/)**

| 파일                 | 배포 경로                     | 역할    | 상세                                                                                                                 |
|--------------------|---------------------------|-------|--------------------------------------------------------------------------------------------------------------------|
| settings.json.tmpl | `~/.claude/settings.json` | 핵심 설정 | 권한 정책(`bypassPermissions` + deny 목록), 활성화된 플러그인 목록(`enabledPlugins`), 언어, 알림 설정. Claude Code의 모든 동작을 제어하는 단일 설정 파일 |

**추가 사용자 경로** (chezmoi 관리 대상이 아닌 Claude Code 네이티브 경로):

| 경로                    | 역할              | 상세                                                         |
|-----------------------|-----------------|------------------------------------------------------------|
| `~/.claude/commands/` | 글로벌 커스텀 슬래시 커맨드 | 마크다운 파일로 정의하는 사용자 커스텀 슬래시 커맨드. `/help`에서 목록 확인 가능          |
| `~/.claude/agents/`   | 글로벌 커스텀 서브에이전트  | YAML frontmatter가 포함된 마크다운 파일로 정의하는 서브에이전트. 오케스트레이터가 자동 생성 |

**MCP 설정 위치**: 사용자 범위는 `~/.claude.json`, 프로젝트 범위는 `.mcp.json`을 사용한다. `~/.claude/` 디렉토리 내부가 아닌 **홈 디렉토리 루트**에 위치하는 점에
주의. `~/.claude.json`은 Claude Code가 런타임에 직접 관리하며(`.chezmoiignore`로 chezmoi 배포 제외), `.mcp.json`은 프로젝트별 MCP 서버를 선언한다.

**플러그인**

Claude Code 플러그인은 `settings.json`의 `enabledPlugins` 필드에 등록된다. 플러그인 전용 `plugins.json`/`hud.json` 파일은 사용하지 않으며, MCP는
`~/.claude.json`(사용자)과 `.mcp.json`(프로젝트)으로 관리한다.

| 플러그인                   | 역할            | 설치 방식       | 상세                                                                                                                                     |
|------------------------|---------------|-------------|----------------------------------------------------------------------------------------------------------------------------------------|
| superpowers            | 구조화된 워크플로우    | 플러그인 마켓플레이스 | 브레인스토밍, TDD, 코드 리뷰, 서브에이전트 기반 개발 등 12종+ 스킬을 제공. 코드 작성 전 계획 수립, 검증 후 완료 선언 등 체계적 개발 프로세스를 강제                                            |
| claude-hud             | 상태 표시줄        | 플러그인 마켓플레이스 | 컨텍스트 사용량, 현재 모델, Git 상태, 활성 도구, 에이전트, 진행률을 터미널 하단에 실시간 표시. 기본 statusline으로 설정. 설정은 자동 생성됨 (`~/.claude/plugins/claude-hud/config.json`) |
| andrej-karpathy-skills | 코딩 행동 지침      | 플러그인 마켓플레이스 | Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven Execution 4대 원칙을 Claude Code 세션에 자동 주입하여 코드 품질 기준선 유지             |

**MCP 서버**

| 서버                  | 역할             | 상세                                                                                              |
|---------------------|----------------|-------------------------------------------------------------------------------------------------|
| context7            | 라이브러리 공식 문서 조회 | resolve-library-id로 라이브러리를 식별한 뒤 get-library-docs로 공식 문서와 코드 예제를 검색. 외부 라이브러리 사용 시 최신 공식 패턴을 참조 |
| sequential-thinking | 체계적 다단계 분석     | 복잡한 문제를 구조화된 사고 단계로 분해하여 분석. 디버깅, 아키텍처 설계, 코드 리뷰 등 다단계 추론이 필요한 작업에 활용                           |

## Codex

**설치 (스크립트)**

| 스크립트        | 내용                                                             | 설치 대상             |
|-------------|----------------------------------------------------------------|-------------------|
| 10-ai-core  | Codex CLI (npm)                                                | Codex CLI 바이너리    |
| 12-ai-codex | oh-my-codex (npm), superpowers (~/superpowers에서 copy), 프로필 초기화 | Codex 확장 환경 전체 구성 |

**설정 (dot_codex/ → ~/.codex/)**

| 파일               | 배포 경로                  | 역할    | 상세                                                                                                                                |
|------------------|------------------------|-------|-----------------------------------------------------------------------------------------------------------------------------------|
| config.toml.tmpl | `~/.codex/config.toml` | 핵심 설정 | 기본 모델(`gpt-5.5`), 승인 정책, 기본 프롬프트(karpathy 4원칙), MCP 서버 설정을 단일 파일에서 관리. 별도의 `permissions.toml`이나 `profiles.toml` 파일은 존재하지 않음 |

**oh-my-codex 주요 기능**

| 기능        | 내용                                           | 상세                                                    |
|-----------|----------------------------------------------|-------------------------------------------------------|
| 에이전트 프롬프트 | architect, planner, executor, debugger 등 30종 | 작업 유형별 시스템 프롬프트로 에이전트 역할과 행동을 정의                      |
| 워크플로우 스킬  | plan, team, autopilot, ultrawork 등 40종       | 단계별 워크플로우. 자동화 수준과 사용자 개입 정도를 선택 가능                   |
| 팀 모드      | tmux 기반 병렬 워커 세션                             | tmux 세션으로 여러 Codex 워커를 병렬 실행하여 작업 분산 처리               |
| MCP 서버    | 상태, 메모리, 코드 인텔리전스, 트레이싱 4종                   | oh-my-codex 자체 MCP 서버. 작업 상태 추적, 메모리 관리, 코드 분석, 실행 추적 |

superpowers도 Codex에 설치된다 (~/superpowers에서 copy). karpathy 지침은 config.toml의 모델 지침으로 적용한다.

## OpenCode

**설치 (스크립트)**

| 스크립트           | 내용                                                                       | 설치 대상                |
|----------------|--------------------------------------------------------------------------|----------------------|
| 20-ai-opencode | OpenCode (npm), oh-my-opencode (npm), superpowers (~/superpowers에서 copy) | OpenCode 바이너리와 확장 기능 |

**설정 (dot_config/opencode/ → ~/.config/opencode/)**

| 파일                        | 배포 경로                                     | 역할    | 상세                                                           |
|---------------------------|-------------------------------------------|-------|--------------------------------------------------------------|
| opencode.json.tmpl        | `~/.config/opencode/opencode.json`        | 핵심 설정 | AI 프로바이더, 권한 정책, 에이전트 설정, MCP 서버 목록을 정의                      |
| oh-my-opencode.jsonc.tmpl | `~/.config/opencode/oh-my-opencode.jsonc` | 확장 설정 | oh-my-opencode의 에이전트 오버라이드, 훅, 카테고리 설정. JSONC(주석 허용 JSON) 형식 |
| plugins/                  | `~/.config/opencode/plugins/`             | 플러그인  | superpowers 등 OpenCode 플러그인 배포                               |
| skills/                   | `~/.config/opencode/skills/`              | 스킬    | OpenCode 전용 스킬과 공유 스킬을 이 경로에 배포                              |

**oh-my-opencode 주요 기능**

| 기능           | 내용                               | 상세                                                                               |
|--------------|----------------------------------|----------------------------------------------------------------------------------|
| 멀티 모델 에이전트   | 작업별 최적 모델 자동 배정 (11종 에이전트)       | 작업 유형(코드 작성, 리뷰, 디버깅, 문서화)에 따라 AI 모델 자동 배정                                       |
| 백그라운드 에이전트   | 병렬 에이전트 동시 실행                    | 독립 작업을 여러 에이전트로 병렬 처리                                                            |
| 내장 훅         | Todo 강제 완료, 주석 검사 등 41종          | 코드 품질 자동 검증 훅(32 core + 7 continuation + 2 skill). Todo 완료 강제, 주석 검사, 보안 패턴 감지 등 |
| MCP          | Context7, augment-context-engine | 외부 문서 검색(Context7), 코드 컨텍스트 분석(augment-context-engine)을 MCP 서버로 통합               |
| LSP/AST-Grep | 결정론적 리팩토링 도구                     | LSP와 AST-Grep 기반 리팩토링. AI 추론이 아닌 구문 분석으로 동작                                      |

superpowers도 OpenCode에 설치된다 (~/superpowers에서 copy).

OpenCode는 프로젝트/글로벌 모두에서 `.opencode/skills/` 외에 `.claude/skills/`와 `.agents/skills/`도 자동 탐색한다. 별도 설정 없이 Claude, Codex와
동일한 스킬을 자동으로 인식한다.

## Gemini

**설치 (스크립트)**

| 스크립트         | 내용                                                     | 설치 대상               |
|--------------|--------------------------------------------------------|---------------------|
| 10-ai-core   | Gemini CLI (npm)                                       | Gemini CLI 바이너리     |
| 13-ai-gemini | SuperGemini (pipx), superpowers (~/superpowers에서 copy) | Gemini CLI 확장 프레임워크 |

SuperGemini는 Gemini CLI의 확장 프레임워크로, 슬래시 명령어와 AI 에이전트 페르소나를 제공한다. superpowers는 ~/superpowers에서 ~
/.gemini/skills/superpowers로 복사된다.

**설정 (dot_gemini/ → ~/.gemini/)**

- `settings.json` 기본 승인 모드는 `auto_edit`로 설정한다.
- MCP 서버: context7, sequential-thinking, augment-context-engine 3종.
- YOLO 모드는 설정 파일 기본값(`general.defaultApprovalMode`)으로는 지정할 수 없으며, 실행 시 `--approval-mode=yolo` 옵션을 사용해야 한다.
- 이 dotfiles는 `gemini-yolo` 별칭(`gemini --approval-mode=yolo`)을 제공한다.

## Copilot

**설치 (스크립트)**

| 스크립트          | 내용                                 | 설치 대상            |
|---------------|------------------------------------|------------------|
| 10-ai-core    | Copilot CLI (npm)                  | Copilot CLI 바이너리 |
| 14-ai-copilot | superpowers (~/superpowers에서 copy) | Copilot 확장 환경 구성 |

**설정 (dot_copilot/ → ~/.copilot/)**

| 파일                   | 배포 경로                        | 역할     | 상세                                                       |
|----------------------|------------------------------|--------|----------------------------------------------------------|
| mcp-config.json.tmpl | `~/.copilot/mcp-config.json` | MCP 설정 | Copilot CLI의 MCP 서버 설정                                   |
| skills/              | `~/.copilot/skills/`         | 글로벌 스킬 | superpowers 스킬을 배포. 각 스킬은 `<skill-name>/SKILL.md` 형태로 구성 |

Copilot 스킬 경로:

- **글로벌**: `~/.copilot/skills/<skill-name>/SKILL.md` — 모든 프로젝트에서 참조
- **프로젝트**: `.github/skills/<skill-name>/SKILL.md` 또는 `.claude/skills/<skill-name>/SKILL.md` — 해당 프로젝트에서만 참조
