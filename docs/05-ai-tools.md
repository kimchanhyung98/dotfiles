# AI 도구 설정

## 공통 원칙

- **인증 정보 보안**: 인증 정보는 사용자 홈 범위의 보안 저장소(환경 변수, OS 키체인)에 유지한다. 설정 파일에 API 키나 토큰을 직접 기재하지 않는다.
- **실제 권한 경계**: Claude는 `bypassPermissions`와 deny 목록을 함께 사용하고, Codex는 `approval_policy = "never"`와 custom `workspace` filesystem/network profile을 함께 사용한다. 승인 prompt가 없으므로 deny/profile이 실제 제한 경계다.
- **설정 소유권**: chezmoi가 소유하는 설정은 source 파일로 관리하고, `~/.claude.json`처럼 도구가 직접 갱신하는 runtime 파일은 ignore한 뒤 CLI 명령으로 필요한 항목만 등록한다.

## 모듈화 기준

- 코어 설치(10)에서 AI CLI 4종과 CodeGraph를 설치하고, 프로바이더별 확장 스크립트(11~12)에서 MCP, 플러그인을 독립 관리한다.
- 서비스별 설정 파일(`settings.json`, `config.toml` 등)과 chezmoi 실행 스크립트(`run_once_11-ai-claude.sh.tmpl`, `run_once_12-ai-codex.sh.tmpl` 등)를 분리한다.
- 인증, 프로필, 권한, 확장(플러그인/스킬) 항목을 독립적으로 관리하여, 하나의 변경이 다른 항목에 영향을 주지 않는다.
- AI 설정 변경이 단일 모듈에 국한되도록 구성하여, 변경 범위를 예측할 수 있다.

## 스킬 배포

Claude Code와 Codex가 단일 출처 `~/.skills`를 공유한다. 지원하는 글로벌 스킬 경로는 `~/.skills`로의 symlink이며, 스킬 형식은 SKILL.md 기반으로 두 도구에서 동일하다.

| 도구          | 글로벌 스킬 경로                                              | 프로젝트 스킬 경로                                       | 배포 방식      |
|-------------|--------------------------------------------------------|--------------------------------------------------|------------|
| Claude Code | `~/.claude/skills/` → `~/.skills/`                     | `.claude/skills/` → `.skills/`                   | symlink 공유 |
| Codex       | `~/.agents/skills/` → `~/.skills/`                    | `.agents/skills/` → `.skills/`                   | symlink 공유 |

**단일 출처 `~/.skills`**: 공통 스킬을 `~/.skills` 한 곳에만 두고, 지원 도구의 `skills` 디렉토리를 여기로 symlink하여 공유한다. chezmoi가
`home/dot_claude/symlink_skills`·`home/dot_agents/symlink_skills`로 symlink를 관리하고,
`mattpocock-skills-sync`가 `~/.skills` 본체를 생성·갱신한다. 이 패턴은 프로젝트 루트의 `.skills` + `.claude/skills`·`.agents/skills` symlink 구조와 동일하다.

**기존 머신 정리**: symlink 전환 이전에 지원 스킬 경로가 실제 디렉토리였던 머신에서는, `run_once_before_00-skills-ssot-migrate` 스크립트가 dotfiles 배포
전에 기존 skills 디렉토리를 삭제한다. 기존 실제 디렉토리가 남아 있으면 chezmoi가 해당 경로를 symlink로 교체할 수 없으므로, 삭제 후 dotfiles 배포 단계에서
`~/.skills` symlink로 교체한다.

**스킬 소스**:

- **사용자 스킬**: `~/.skills/<skill-name>/SKILL.md` 형태로 직접 추가한다. symlink를 통해 Claude Code와 Codex가 즉시 인식한다. oh-my-codex가 설치하는
  스킬도
  symlink를 거쳐 `~/.skills`에 저장되어 공유된다.
- **mattpocock/skills**: 공통 engineering/productivity 후보 스킬은 repo에 직접 포함하지 않는다.
  `~/.local/bin/mattpocock-skills-sync`가 호환되는 upstream tag `v1.0.1`에서 선택한 15개 스킬만 `~/.skills`로 동기화한다.
  `run_onchange_after_06-mattpocock-skills`가 최초 적용 및 스크립트 변경 시 실행한다.
  helper를 재실행하면 같은 pinned tag의 snapshot으로 선택된 동명 디렉토리를 교체한다. upstream upgrade는 helper의 ref와 선택 목록을 함께 바꾸는 명시적 변경으로 수행한다.
  현재 `~/.skills` 본체는 managed target이 아니며 helper가 소유하므로, 선택 목록의 기준은 sync helper 한 곳이다.
- **andrej-karpathy-skills 기반 4원칙**: 배포되는 홈 `AGENTS.md`, 이 저장소의 `CLAUDE.md → AGENTS.md` symlink, Codex `config.toml`의 `developer_instructions`에 반영한다. 별도 홈 `~/CLAUDE.md`는 배포하지 않는다.

## AGENTS.md

`AGENTS.md.tmpl`은 홈 루트에 배포된다:

| 배포 위치 | 대상 경로         | 참조 도구 | 적용 범위                 |
|-------|---------------|-------|-----------------------|
| 홈 루트  | `~/AGENTS.md` | Codex | 프로젝트(홈 디렉토리) 수준 공통 지침 |

**계층 우선순위**: 하위 경로의 AGENTS.md가 상위를 override한다. 이 repo가 관리하는 Codex 지침 경로:

| 우선순위 | 범위      | 경로 예시                | 역할                          |
|:----:|---------|----------------------|-----------------------------|
|  1   | 하위 디렉토리 | `src/api/AGENTS.md`  | 특정 도메인 전용 지침 (최우선 override) |
|  2   | 저장소 루트  | `./AGENTS.md`        | 프로젝트 공통 지침                  |
|  3   | 사용자 홈   | `~/AGENTS.md`        | 사용자 전역 기본 지침                |
|  4   | Codex config | `~/.codex/config.toml`의 `developer_instructions` | Codex 전용 기본 지침 |

**포함 내용**:

| 항목                    | 출처                                 | 상세                               |
|-----------------------|------------------------------------|----------------------------------|
| Think Before Coding   | `AGENTS.md.tmpl`, repo `CLAUDE.md`, Codex `developer_instructions` | 코드를 작성하기 전에 전체 맥락을 이해하고 계획을 수립   |
| Simplicity First      | `AGENTS.md.tmpl`, repo `CLAUDE.md`, Codex `developer_instructions` | 가장 단순한 해결책을 우선 선택하고 불필요한 복잡성을 회피 |
| Surgical Changes      | `AGENTS.md.tmpl`, repo `CLAUDE.md`, Codex `developer_instructions` | 변경 범위를 최소화하고 관련 없는 코드를 수정하지 않음   |
| Goal-Driven Execution | `AGENTS.md.tmpl`, repo `CLAUDE.md`, Codex `developer_instructions` | 사용자의 목표에 집중하여 불필요한 확장을 방지        |
| 도구 공통 운영 규칙           | 프로젝트 공통 정의                         | 각 AI 도구에서 공유하는 작업 규칙과 출력 형식      |

## Claude Code

**설치 (스크립트)**

| 스크립트         | 내용                                  | 설치 대상                            |
|--------------|-------------------------------------|----------------------------------|
| 10-ai-core   | Claude Code (공식 설치 스크립트), CodeGraph | Claude Code / CodeGraph CLI 바이너리 |
| 11-ai-claude | SuperClaude (pipx)                  | CLI 확장 프레임워크                     |

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

Claude Code 플러그인은 `settings.json`의 `enabledPlugins` 필드에 등록된다. 플러그인 전용 `plugins.json`/`hud.json` 파일은 사용하지 않으며, Codex 연동은
`extraKnownMarketplaces.openai-codex`와 `codex@openai-codex`로 선언한다.

| 상태 | 플러그인 |
|---|---|
| 활성 | `code-review`, `code-simplifier`, `codex@openai-codex`, `context7`, `hookify`, `playwright`, `pr-review-toolkit`, `ralph-loop`, `remember`, `security-guidance`, `vercel` |
| 비활성 | LSP, 서비스 연동, 실험 기능 등 나머지 official plugin 항목 |

**MCP 서버**

| 서버        | 역할           | 상세                                                                                  |
|-----------|--------------|-------------------------------------------------------------------------------------|
| codegraph | 코드 그래프 인텔리전스 | `run_once_11-ai-claude.sh.tmpl`이 `claude mcp add-json codegraph --scope user`로 등록한다. |

## Hermes

**설치 (스크립트)**

| 스크립트                                    | 내용                  | 설치 대상           |
|-----------------------------------------|---------------------|-----------------|
| 10-ai-core (macOS), 04-ai-tools (Linux) | Hermes Agent (curl) | Hermes CLI 바이너리 |

**설정 (`hermes setup`이 생성 → ~/.hermes/)**

| 파일/경로                   | 역할        | 상세                                                           |
|-------------------------|-----------|--------------------------------------------------------------|
| `~/.hermes/`            | 실행 홈 디렉토리 | Hermes가 세션, 로그, 설정을 저장하는 기본 홈                                |
| `~/.hermes/.env`        | API 키/비밀  | `hermes setup`이 채우는 환경 변수 파일                                 |
| `~/.hermes/config.yaml` | 핵심 설정     | model, tools, terminal, gateway, agent 등 비시크릿 설정을 저장하는 기본 구성 |

설치 스크립트는 uv, Python, Node.js, ripgrep, ffmpeg 등 Hermes 런타임 의존성을 함께 준비할 수 있다. 초기 설정은 `hermes setup`으로 진행한다. chezmoi가 배포하는
설정 파일은 없으며, 기본 설치만으로 CLI가 준비되고 API 키와 provider 선택은 이후에 완료한다.

## Antigravity

**설치 (스크립트)**

| 스크립트                                    | 내용                                                                       | 설치 대상                       |
|-----------------------------------------|--------------------------------------------------------------------------|-----------------------------|
| 10-ai-core (macOS), 04-ai-tools (Linux) | Antigravity CLI (`curl -fsSL https://antigravity.google/cli/install.sh`) | `agy` 바이너리 (`~/.local/bin`) |

Google Antigravity의 터미널 AI 에이전트다. 설치 시 `agy` 바이너리가 `~/.local/bin`에 등록된다. chezmoi가 배포하는 설정 파일은 없으며, 인증과 초기 설정은 `agy` 첫 실행
시 진행한다.

## Codex

**설치 (스크립트)**

| 스크립트        | 내용                               | 설치 대상                      |
|-------------|----------------------------------|----------------------------|
| 10-ai-core  | Codex CLI (npm), CodeGraph (npm) | Codex CLI / CodeGraph 바이너리 |
| 12-ai-codex | oh-my-codex (npm), 프로필 초기화       | Codex 확장 환경 전체 구성          |

**설정 (dot_codex/ → ~/.codex/)**

| 파일               | 배포 경로                  | 역할    | 상세                                                                                                                                                   |
|------------------|------------------------|-------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| config.toml.tmpl | `~/.codex/config.toml` | 핵심 설정 | 기본 모델(`gpt-5.6-sol`), `approval_policy = "never"`, custom `workspace` 권한 profile, 기본 프롬프트(karpathy 4원칙), MCP 서버를 단일 파일에서 관리. CodeGraph도 MCP 서버로 등록한다. |

**oh-my-codex 주요 기능**

| 기능        | 내용                                           | 상세                                                    |
|-----------|----------------------------------------------|-------------------------------------------------------|
| 에이전트 프롬프트 | architect, planner, executor, debugger 등 30종 | 작업 유형별 시스템 프롬프트로 에이전트 역할과 행동을 정의                      |
| 워크플로우 스킬  | plan, team, autopilot, ultrawork 등 40종       | 단계별 워크플로우. 자동화 수준과 사용자 개입 정도를 선택 가능                   |
| 팀 모드      | tmux 기반 병렬 워커 세션                             | tmux 세션으로 여러 Codex 워커를 병렬 실행하여 작업 분산 처리               |
| MCP 서버    | 상태, 메모리, 코드 인텔리전스, 트레이싱 4종                   | oh-my-codex 자체 MCP 서버. 작업 상태 추적, 메모리 관리, 코드 분석, 실행 추적 |

스킬은 `~/.agents/skills` → `~/.skills` symlink로 공유한다. karpathy 지침은 config.toml의 모델 지침으로 적용한다. CodeGraph는
`codegraph serve --mcp`로 연결하며,
프로젝트별 인덱스는 해당 프로젝트에서 `codegraph init -i`로 생성한다.
