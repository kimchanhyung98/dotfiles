# AI 도구 설정

## 공통 원칙

- **인증 정보 소유권**: API 키나 토큰은 Git/chezmoi source에 직접 기재하지 않고 각 도구의 runtime credential 저장소가 소유한다. 현재 Codex의 file credential 저장 정책은 보안 결정이 필요해 [최종 감사](review/2026-07-18-final-audit.md)에 별도로 기록했다.
- **권한 경계**: Claude의 `bypassPermissions`는 승인 계층을 건너뛰므로 deny 목록과 command hook은 보조 guardrail이지 OS 보안 경계가 아니다. Codex custom `workspace` profile은 sandbox가 적용되는 도구의 filesystem/network 범위를 제한한다. 무승인 정책의 잔여 위험은 [최종 감사](review/2026-07-18-final-audit.md)를 따른다.
- **설정 소유권**: chezmoi가 소유하는 설정은 source 파일로 관리하고, `~/.claude.json`처럼 도구가 직접 갱신하는 runtime 파일은 ignore한 뒤 CLI 명령으로 필요한 항목만 등록한다.

## 모듈화 기준

- 코어 설치(10)에서 필수 Claude/Codex와 선택 AI CLI를 설치하고, 프로바이더별 확장 스크립트(11~12)에서 MCP, 플러그인을 독립 관리한다.
- 서비스별 설정 파일(`settings.json`, `config.toml` 등)과 chezmoi 실행 스크립트(`run_once_11-ai-claude.sh.tmpl`, `run_once_12-ai-codex.sh.tmpl` 등)를 분리한다.
- 인증, 프로필, 권한, 확장(플러그인/스킬) 항목을 독립적으로 관리하여, 하나의 변경이 다른 항목에 영향을 주지 않는다.
- AI 설정 변경이 단일 모듈에 국한되도록 구성하여, 변경 범위를 예측할 수 있다.

## 스킬 배포

Claude Code와 Codex가 단일 출처 `~/.skills`를 공유한다. 지원하는 글로벌 스킬 경로는 `~/.skills`로의 symlink이며, 스킬 형식은 SKILL.md 기반으로 두 도구에서 동일하다.

| 도구          | 글로벌 스킬 경로                                              | 프로젝트 스킬 경로                                       | 배포 방식      |
|-------------|--------------------------------------------------------|--------------------------------------------------|------------|
| Claude Code | `~/.claude/skills/` → `~/.skills/`                     | `.claude/skills/` → `.skills/`                   | symlink 공유 |
| Codex       | `~/.agents/skills/` → `~/.skills/`                    | `.agents/skills/` → `.skills/`                   | symlink 공유 |
| Copilot CLI | `~/.agents/skills/` → `~/.skills/` 재사용              | `.agents/skills/`, `.github/skills/`              | 별도 Copilot symlink 없음 |
| Kimi Code   | `~/.agents/skills/` → `~/.skills/` 재사용              | `.agents/skills/`                                | 별도 Kimi symlink 없음 |
| Kiro CLI    | `~/.kiro/skills/` → `~/.skills/`                       | `.kiro/skills/`                                  | symlink 공유 |

**단일 출처 `~/.skills`**: 공통 스킬을 `~/.skills` 한 곳에만 두고, 지원 도구의 `skills` 디렉토리를 여기로 symlink하여 공유한다. chezmoi가
`home/dot_claude/symlink_skills`·`home/dot_agents/symlink_skills`로 symlink를 관리하고,
chezmoi는 `home/dot_skills`에 선언된 하위 디렉토리를, `mattpocock-skills-sync`는 선택 목록의 동기화 대상 디렉토리를 각각 소유한다. 이 패턴은 프로젝트 루트의 `.skills` + `.claude/skills`·`.agents/skills` symlink 구조와 동일하다.

**기존 머신 정리**: symlink 전환 이전에 지원 스킬 경로가 실제 디렉토리였던 머신에서는, `run_once_before_00-skills-ssot-migrate` 스크립트가 dotfiles 배포
전에 기존 skills 디렉토리를 삭제한다. 기존 실제 디렉토리가 남아 있으면 chezmoi가 해당 경로를 symlink로 교체할 수 없으므로, 삭제 후 dotfiles 배포 단계에서
각 지원 경로를 `~/.skills`를 가리키는 symlink로 교체한다. 삭제한 디렉토리는 백업하지 않으며 migration 스크립트는 `~/.skills` 본체를 건드리지 않는다.

도구별 instruction 경로에 있던 기존 일반 파일도 chezmoi가 `~/AGENTS.md`를 가리키는 managed symlink로 덮어쓰며 별도로 백업하지 않는다.

**스킬 소스**:

- **chezmoi 관리 스킬**: `home/dot_skills/<skill-name>/`에 추가해 `~/.skills/<skill-name>/`로 배포한다. `i-have-adhd`는 upstream commit `cbe69fb83c08a37cf54d5ec9ec6bb88c8bc9973c`의 `SKILL.md`를 Claude/Codex 호출 방식과 적용 범위에 맞게 조정하고, `agents/openai.yaml`과 MIT 라이선스를 가져온다. Claude Code에서는 `/i-have-adhd`로 세션 모드를 시작하고, Codex에서는 매 턴 `$i-have-adhd`를 명시 호출한다.
- **mattpocock/skills**: 공통 engineering/productivity 후보 스킬은 repo에 직접 포함하지 않는다.
  `~/.local/bin/mattpocock-skills-sync`가 호환되는 upstream tag `v1.0.1`에서 선택한 15개 스킬만 `~/.skills`로 동기화한다.
  `run_onchange_after_06-mattpocock-skills`가 최초 적용 및 스크립트 변경 시 실행한다.
  helper를 재실행하면 같은 pinned tag의 snapshot으로 선택된 동명 디렉토리를 교체한다. upstream upgrade는 helper의 ref와 선택 목록을 함께 바꾸는 명시적 변경으로 수행한다.
  helper가 선택 목록의 동명 하위 디렉토리만 소유하므로 chezmoi가 관리하는 `i-have-adhd`와 그 밖의 사용자 스킬은 건드리지 않는다.
- **andrej-karpathy-skills 기반 4원칙**: `~/AGENTS.md`를 단일 원본으로 배포하고 Claude, Codex, Copilot의 공식 사용자 지침 경로를 이 파일로 symlink한다. 이 저장소도 `CLAUDE.md → AGENTS.md` symlink를 사용하며 Codex `config.toml`의 `developer_instructions`에도 핵심 원칙을 반영한다.

## 공통 에이전트 지침

`AGENTS.md.tmpl`은 홈 루트의 단일 원본으로 배포되고 도구별 공식 사용자 경로가 이를 가리킨다:

| 소스 | 대상 경로 | 참조 도구 | 적용 범위 |
|---|---|---|---|
| `AGENTS.md.tmpl` | `~/AGENTS.md` | 공통 원본 | chezmoi가 관리하는 단일 내용 |
| `dot_claude/symlink_CLAUDE.md` | `~/.claude/CLAUDE.md` → `~/AGENTS.md` | Claude Code | 사용자 전역 지침 |
| `dot_codex/symlink_AGENTS.md` | `~/.codex/AGENTS.md` → `~/AGENTS.md` | Codex | 사용자 전역 지침 |
| `dot_copilot/symlink_copilot-instructions.md` | `~/.copilot/copilot-instructions.md` → `~/AGENTS.md` | Copilot CLI | 개인 지침 |
| `dot_kimi-code/symlink_AGENTS.md` | `~/.kimi-code/AGENTS.md` → `~/AGENTS.md` | Kimi Code | 사용자 전역 지침 |
| `dot_kiro/steering/symlink_AGENTS.md` | `~/.kiro/steering/AGENTS.md` → `~/AGENTS.md` | Kiro CLI | 사용자 전역 지침(steering) |

**Codex 계층 우선순위**: 사용자 전역 파일 뒤에 repository root부터 현재 디렉터리까지의 `AGENTS.md`가 순서대로 적용되며 더 가까운 파일이 구체화한다:

| 적용 순서 | 범위 | 경로 예시 | 역할 |
|:--:|---|---|---|
| 1 | 사용자 전역 | `~/.codex/AGENTS.md` | 기본 지침 |
| 2 | 저장소 루트 | `./AGENTS.md` | 프로젝트 공통 지침 |
| 3 | 하위 디렉터리 | `src/api/AGENTS.md` | 특정 도메인 전용 지침 |

`~/.codex/config.toml`의 `developer_instructions`는 이 파일 탐색 계층과 별개의 Codex 전용 기본 지침이다. Claude와 Copilot도 각각 위 표의 사용자 파일을 읽고 repository 지침이 있으면 더 구체적인 컨텍스트로 함께 사용한다.

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
| 11-ai-claude | CodeGraph MCP 등록                  | Claude 사용자 범위 MCP 설정              |

**설정 (dot_claude/ → ~/.claude/)**

| 파일                 | 배포 경로                     | 역할    | 상세                                                                                                                 |
|--------------------|---------------------------|-------|--------------------------------------------------------------------------------------------------------------------|
| settings.json.tmpl | `~/.claude/settings.json` | 핵심 설정 | 현재 자율 실행 정책(`bypassPermissions` + deny guardrail), 활성화된 플러그인 목록(`enabledPlugins`), 언어, 알림 설정. Claude Code의 핵심 사용자 설정 파일 |

`bypassPermissions`에서는 deny 목록이 shell subprocess까지 강제하는 보안 경계가 아니다. 이 정책은 격리 환경 전용으로 바꿀지 승인 기반 모드로 전환할지 [최종 감사](review/2026-07-18-final-audit.md)에서 결정 대상으로 남겨 두었다.

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
| 활성 | `code-review`, `code-simplifier`, `codex@openai-codex`, `context7`, `diagram-design@diagram-design`, `hookify`, `playwright`, `pr-review-toolkit`, `ralph-loop`, `remember`, `security-guidance`, `vercel` |
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
| 10-ai-core  | Codex CLI (공식 standalone installer), CodeGraph (npm, 선택) | Codex CLI / CodeGraph 바이너리 |

**설정 (dot_codex/ → ~/.codex/)**

| 파일               | 배포 경로                  | 역할    | 상세                                                                                                                                                   |
|------------------|------------------------|-------|------------------------------------------------------------------------------------------------------------------------------------------------------|
| config.toml.tmpl | `~/.codex/config.toml` | 핵심 설정 | 기본 모델(`gpt-5.6-sol`), `approval_policy = "never"`, custom `workspace` 권한 profile, 기본 프롬프트(karpathy 4원칙), MCP 서버를 단일 파일에서 관리. CodeGraph도 MCP 서버로 등록한다. |

현재 `cli_auth_credentials_store = "file"`은 source의 비밀 값은 아니지만 `$CODEX_HOME/auth.json` runtime 파일을 사용한다. network 허용 profile과 함께 둘 때의 credential 노출 위험 및 keyring 전환 절차는 [최종 감사](review/2026-07-18-final-audit.md)에 기록했다.

스킬은 `~/.agents/skills` → `~/.skills` symlink로 공유한다. karpathy 지침은 config.toml의 모델 지침으로 적용한다. CodeGraph는
`codegraph serve --mcp`로 연결하며,
프로젝트별 인덱스는 해당 프로젝트에서 `codegraph init -i`로 생성한다.

## GitHub Copilot CLI

Copilot은 사용하지만 필수 AI baseline은 아니다. macOS는 Brewfile의 `copilot-cli` cask로, Linux는 공식 installer로 준비한다. 설치 실패는 Claude/Codex 설치 성공을 무효화하지 않으며 `dotfiles-doctor`에서 optional warning으로 표시한다.

| 경로 | 역할 |
|---|---|
| `~/.copilot/mcp-config.json` | context7, Playwright, sequential-thinking 사용자 MCP 설정 |
| `~/.agents/skills` | Copilot CLI가 인식하는 공통 skill 경로. Codex와 같은 `~/.skills` symlink 재사용 |
| `~/.copilot/copilot-instructions.md` → `~/AGENTS.md` | Copilot CLI 개인 지침 |

과거 `~/.copilot/skills` symlink는 복구하지 않는다. Copilot이 지원하는 `~/.agents/skills`가 이미 공통 단일 출처를 가리키기 때문이다. OpenCode 설정은 관리하지 않으며 legacy 경로는 제거 상태로 유지한다.

## Kimi Code

**설치 (스크립트)**

| 스크립트                                    | 내용                                                                | 설치 대상                        |
|-----------------------------------------|-------------------------------------------------------------------|------------------------------|
| 10-ai-core (macOS), 04-ai-tools (Linux) | Kimi Code CLI (`curl -fsSL https://code.kimi.com/kimi-code/install.sh`) | `kimi` 바이너리 (`~/.kimi-code/bin`) |

Moonshot AI의 터미널 AI 에이전트다. 설치 경로는 installer 기본값을 유지한다. 자동 업데이트가 같은 installer를 `KIMI_INSTALL_DIR` 없이 재실행하므로 경로를 옮기면
갱신본과 실행본이 어긋난다. `KIMI_NO_MODIFY_PATH`는 installer가 chezmoi 소유의 `~/.zshrc`를 수정하지 못하게 설치 스크립트와 `60-tools.zsh` 양쪽에서 지정하며, PATH
등록은 `60-tools.zsh`가 담당한다(같은 디렉토리의 `rg`/`fd` 캐시가 시스템 도구를 가리지 않도록 뒤에 추가).

**설정 (dot_kimi-code/ → ~/.kimi-code/)**

| 파일               | 배포 경로                    | 역할       | 상세                                                |
|------------------|--------------------------|----------|---------------------------------------------------|
| config.toml | `~/.kimi-code/config.toml` | 핵심 설정 | 기본 모델(`kimi-code/k3`, effort `max`를 overrides로 고정), `default_permission_mode = "auto"`, `AgentSwarm` 자동 허용, plan 모드 기본값, 텔레메트리 비활성, `[[permission.rules]]` 가드레일 |
| symlink_AGENTS.md | `~/.kimi-code/AGENTS.md` | 사용자 전역 지침 | `~/AGENTS.md`를 가리키는 symlink. Claude/Codex/Copilot과 동일한 단일 원본을 공유한다 |

`config.toml`은 구독(OAuth) 경로에서 비밀 값을 담지 않는다. 토큰은 `~/.kimi-code/credentials/`(0700/0600)가 소유하고 config에는 참조만 남는다. CLI가 런타임에 같은
파일에 oauth 참조와 `[models."kimi-code/*"]` 카탈로그를 다시 쓰지만, chezmoi가 파일을 소유하며 `dotfiles-update`의 `chezmoi update --force`가 이런 로컬 drift를
무시하고 저장소 상태로 덮어쓴다. K3의 effort `max`처럼 managed refresh가 덮어쓸 수 있는 값은 `[models."<alias>".overrides]`로 pin한다. `tui.toml`,
`mcp.json`, `sessions/`는 배포 대상이 아니다.

Kimi는 프로젝트 레벨 설정 파일이 없어 `[[permission.rules]]`를 둘 수 있는 곳이 이 파일뿐이다. 차단은 이 규칙만 담당하고 `[[hooks]]`는 두지 않는다 — 전역 설정이
저장소 로컬 `.hooks/*.sh`를 실행하면 작업 중인 아무 저장소의 스크립트나 실행하게 된다.

스킬과 커스텀 에이전트는 `~/.agents/skills`·`~/.agents/agents`에서, 프로젝트는 `.agents/`와 루트 `AGENTS.md`에서 읽으므로 Kimi 전용 symlink나 프로젝트 파일은 두지
않는다. 머신 종속 경로가 들어가는 `.kimi-code/local.toml`은 `.gitignore` 대상이다.

## Kiro CLI

**설치 (스크립트)**

| 스크립트 | 내용 | 설치 대상 |
|---|---|---|
| 10-ai-core (macOS), 04-ai-tools (Linux) | Kiro CLI (`curl -fsSL https://cli.kiro.dev/install`) | macOS `/Applications/Kiro CLI.app` + `~/.local/bin` symlink, Linux `~/.local/bin`(`unzip` 필요) |

installer는 PATH를 수정하지 않고 안내만 하므로 `~/.local/bin` 등록은 기존 shell 설정이 담당한다. 기존 설치가 있을 때만 `/dev/tty`로 교체 여부를 묻기 때문에
`command -v kiro-cli` 가드가 비대화 실행을 보장한다. macOS installer는 설치 직후 앱을 백그라운드(`open -g`)로 한 번 띄우고 3초 대기하므로 첫 `chezmoi apply`가
그만큼 길어진다.

**설정 (dot_kiro/ → ~/.kiro/)**

| 파일 | 배포 경로 | 역할 | 상세 |
|---|---|---|---|
| settings/private_cli.json.tmpl | `~/.kiro/settings/cli.json` | 전역 설정 | 기본 에이전트·모델·effort, 무승인 시작 확인 제거, 텔레메트리·콘텐츠 공유 차단. `private_` 속성으로 0600을 보존 |
| agents/yolo.json.tmpl | `~/.kiro/agents/yolo.json` | 무승인 에이전트 | 내장 `kiro_default` 복제 + `allowedTools: ["@builtin"]`. `toolsSettings`의 deny 목록이 유일한 차단 경로 |
| symlink_skills | `~/.kiro/skills/` → `~/.skills/` | 스킬 | Claude/Codex와 같은 단일 출처 공유 |
| steering/symlink_AGENTS.md | `~/.kiro/steering/AGENTS.md` → `~/AGENTS.md` | 사용자 전역 지침 | Kiro global steering 위치에서 공통 지침 재사용 |

내장 에이전트는 편집할 수 없고 `allowedTools`가 에이전트 단위 필드라, 승인 프롬프트를 없애려면 커스텀 에이전트가 필요하다. `yolo`는 `kiro-cli agent create
--from kiro_default`로 복제한 뒤 신뢰 설정을 얹은 것으로 Claude의 `bypassPermissions`와 같은 성격이며, `toolsSettings.*.denied*`가 승인 계층을 대신한다.
`@builtin`에 AWS 도구가 포함되므로 production 계정에서는 최소 권한 credential을 쓴다. 복제해 온 `prompt`는 내장 기본 프롬프트의 스냅샷이라 CLI 업그레이드와
함께 낡는다. 갱신은 `agent create`를 다시 실행해 옮기는 명시적 변경으로 한다.

차단은 preToolUse 훅이 아니라 deny 목록이 전담한다. 저장소 `.hooks/`의 guard를 붙이려면 계약 변환기가 필요한데(Kiro는 exit 2 + STDERR, guard는 exit 0 +
STDOUT JSON), 그 경로는 guard 실행 실패·스크립트 부재·payload 불일치가 모두 통과로 귀결되는 fail-open이다. deny 목록은 CLI 내부에서 평가되므로 그런 실패
모드가 없다. 대신 guard가 하던 realpath 기반 판단은 글롭으로 재현되지 않아, 절대 경로를 통한 저장소 밖 쓰기는 `../**`와 홈 앵커 deny가 막는 범위까지만
차단된다. `.hooks/`의 guard는 이 저장소의 프로젝트 설정(`.claude/settings.json`)만 쓰는 개발용 안전장치이며, chezmoi가 배포하는 전역 설정은 참조하지 않는다.

`deniedPaths`는 Codex `[permissions.workspace.filesystem.":workspace_roots"]`의 secret deny와 같은 범위를 갖는다. `**/` 패턴이 session cwd 기준이라 같은 규칙을
홈 앵커로도 병기해 다른 작업 디렉터리에서 홈 자격증명이 노출되는 것을 막고, 파일 도구별 설정은 상속되지 않으므로 read/write/grep/glob에 각각 명시한다.
`kiro-cli agent validate`는 모르는 필드도 깨진 정규식도 exit 0으로 통과시키므로 검증은 `settings list --all`과 실제 동작 테스트로 한다. `deniedCommands`는
Rust regex로 평가된다.

`~/.kiro/sessions/`, `~/.kiro/.cli_bash_history`, 프로젝트 `.kiro/settings/lsp.json`은 런타임 데이터라 배포 대상이 아니다. 이 저장소는 project Kiro 설정을 두지
않으므로 `.kiro/*`를 ignore한다. 기존 `~/.kiro/skills`가 실제 디렉터리면 run-once script가 먼저 제거한다 — 공통 원본 `~/.skills`는 건드리지 않는다.

## omp

**설치 (스크립트)**

| 스크립트                                    | 내용                                              | 설치 대상                     |
|-----------------------------------------|-------------------------------------------------|---------------------------|
| 10-ai-core (macOS), 04-ai-tools (Linux) | omp (`curl -fsSL https://omp.sh/install`, `--binary`) | `omp` 바이너리 (`~/.local/bin`) |
| 10-ai-core (macOS), 04-ai-tools (Linux) | pi-provider-kiro (`omp plugin install npm:pi-provider-kiro`) | omp 확장 (`~/.omp/plugins`) |

Pi 기반 터미널 AI 에이전트다. installer는 bun이 있으면 bun 빌드 경로를 타고 bun 1.3.14 미만이면 실패하므로, `--binary`로 prebuilt 바이너리를 강제한다. 이 저장소는
Bun을 별도로 설치하므로 지정하지 않으면 omp 설치가 bun 버전에 묶인다. 설치 위치는 installer 기본값 `~/.local/bin`이고 rc 파일은 건드리지 않는다.

**설정 (dot_omp/agent/ → ~/.omp/agent/)**

| 파일               | 배포 경로                        | 역할       | 상세                                                |
|------------------|------------------------------|----------|---------------------------------------------------|
| config.yml | `~/.omp/agent/config.yml` | 핵심 설정 | 역할별 모델(`modelRoles`)과 fallback 체인, 프로바이더 우선순위, advisor, 승인 정책과 `bash.patterns` 차단 규칙, LSP 진단. `enabledModels`를 두지 않아 발견된 모든 프로바이더/모델이 선택기에 표시된다. CLI(`omp config set`, `/settings`)가 이 파일을 다시 써도 `chezmoi update --force`가 저장소 상태로 덮어쓴다. 그래서 CLI가 첫 실행에서 써넣는 `symbolPreset`·`theme`·`setupVersion`도 저장소에 함께 둔다 |
| symlink_AGENTS.md | `~/.omp/agent/AGENTS.md`    | 사용자 전역 지침 | `~/AGENTS.md`를 가리키는 symlink. 경로가 한 단계 깊어 `../../AGENTS.md`다 |

`models.yml`(커스텀 provider), `agent.db`(인증 저장소), `RULES.md`는 배포하지 않는다. 데이터 루트는 `PI_CODING_AGENT_DIR`로 옮길 수 있으나 기본값을 쓴다.

**역할별 모델**: omp는 턴 성격에 따라 역할을 나눠 모델을 고른다. 내장 역할은 `default`, `smol`, `slow`, `vision`, `plan`, `designer`, `commit`, `tiny`, `task`, `advisor`이며,
값은 `provider/modelId`로 고정하거나 `"@role"`로 다른 역할을 참조한다. 뒤에 `:minimal`~`:max` 접미사로 thinking 강도를 붙인다. `anthropic`, `openai-codex`, `kimi-code`는
API key 없이 `/login`으로 붙는 구독 프로바이더라, 이 저장소가 Claude·Codex·Kimi에서 쓰는 모델을 그대로 역할에 배치한다.

**역할별 모델과 fallback**: 역할·모델 매핑, 프로바이더 우선순위, fallback 순서는 운영 중 수시로 바뀌므로 문서나 테스트에 고정하지 않는다.
현재 값은 `config.yml`을 단일 기준으로 확인한다. Kiro 확장은 설치해 두지만, 사용 여부와 순서 역시 이 설정 파일에서 관리한다.

omp는 discovery provider로 다른 도구의 설정 경로를 그대로 읽는다. 사용자 지침은 우선순위가 `native`(`~/.omp/agent/AGENTS.md`) > `claude`(`~/.claude/CLAUDE.md`) >
`agents`·`codex`(`~/.agents/AGENTS.md`, `~/.codex/AGENTS.md`) 순이고 **한 개만 살아남으므로**, 위 symlink가 나머지를 shadow한다. 셋 다 `~/AGENTS.md`를 가리켜 결과는 같다.
스킬도 `claude`·`agents` provider가 `~/.claude/skills`·`~/.agents/skills`를 이미 읽어 omp 전용 symlink는 두지 않는다.

omp 훅은 `pi.on(...)`을 등록하는 JS/TS 확장 모듈이지만, 전역 설정은 저장소 로컬 `.hooks/*.sh`를 실행하지 않는다. 저장소 가드레일은 스크립트를 재사용하는 대신
`bash.patterns`의 deny 규칙으로 다시 표현한다. `tools.approvalMode`가 `yolo`라 이 규칙이 유일한 차단 경로이며, glob 기반이므로 정규식보다 범위가 거칠다.
