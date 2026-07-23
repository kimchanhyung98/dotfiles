# 운영

## `dotfiles-doctor`

`~/.local/bin/dotfiles-doctor`는 설치와 managed target 상태를 확인한다. AI CLI 중 Claude와 Codex만 required이며 누락 시 non-zero다. Copilot, CodeGraph, Antigravity, Hermes, 언어 runtime과 확장은 optional로 표시한다. zsh/git/vim과 Claude/Codex 설정·공통 skills 경로 같은 dotfiles 핵심 target은 계속 required다.

```sh
dotfiles-doctor
```

## 예약 작업

macOS에서 두 LaunchAgent가 독립적으로 실행된다.

- tokscale: 3일마다 14:00
- dotfiles: 매월 1일과 16일 14:00

두 작업 모두 launchd calendar로 실행한다. 성공 시각, 마지막 실행 timestamp, cache를 저장하지 않으며 성공이나 실패가 다음 calendar 실행일을 바꾸지 않는다.

tokscale 래퍼는 submit의 선택적 GitHub star 프롬프트에 `n`을 한 번 전달하여 비대화형으로 실행한다.

launchd는 예약 시각에 Mac이 잠들어 있으면 깨어난 뒤 누락된 실행을 한 번으로 합쳐 실행한다.

예약 시점과 무관하게 직접 검토·갱신하려면 다음 명령을 사용한다.

```sh
chezmoi diff
chezmoi update
chezmoi verify
```

## 프로젝트 준비

이 저장소의 로컬 개발·테스트 환경을 준비하려면 repository root에서 다음을 실행한다.

```sh
make init
```

`make init`은 Docker CLI와 daemon, 로컬 npm을 확인한 뒤 lockfile 기준 `npm ci`를 실행한다. npm의 `prepare` lifecycle이 Husky를 설정한다. 환경 파일을 만들거나 Compose container를 시작하지 않는다.

native 첫 chezmoi 적용 시 apply 후 `name`을 GitHub username으로 사용하여 공개·비보관 저장소를 최대 100개 `~/Documents/GitHub`에 clone한다. GitHub REST API를 인증 없이 사용하며 개인 계정만 허용하고 organization은 무시한다. clone이 끝나면 대화형 Doppler 로그인을 확인하고, 저장소명과 같은 Doppler project의 `local` config로 누락된 `.env`만 생성한다. Codespaces는 이미 선택한 repository에서 시작하므로 이 전체 흐름을 건너뛴다. `run_once_after_` 접두사가 같은 렌더 결과의 재실행을 막고, helper가 기존 Git 저장소와 `.env`를 보존한다. 예약 동기화는 이 흐름을 별도로 호출하지 않는다.

기존 Git 저장소는 pull/reset하지 않는다. archived 저장소는 제외하고 fork는 포함한다. 일부 clone이나 대상 경로 충돌만 실패하면 성공한 저장소를 유지하고 warning과 상세 목록을 출력한 뒤 exit 0으로 완료한다. 잘못된 ID·API 조회 실패·모든 clone 실패는 오류로 보고한다. clone helper는 `.env`를 변경하지 않고, 후속 Doppler helper만 누락된 `.env`를 생성한다.

이 전체 프로젝트 준비는 dotfiles 핵심 설치와 분리된 optional best-effort 단계다. wrapper는 helper 누락이나 clone·Doppler 실패를 warning과 수동 재시도 명령으로 남기고 성공 종료하므로, 해당 실패가 dotfiles apply 실패로 전이되지 않는다.

최초 실행 결과를 미리 확인하거나 수동으로 재시도할 때만 name을 명시하여 실행한다.

```sh
projects-bootstrap --dry-run GITHUB_NAME
projects-bootstrap GITHUB_NAME
```

최초 로그인을 취소했거나 Doppler 후처리만 다시 실행하려면 대화형 터미널에서 다음 명령을 사용한다.

```sh
projects-doppler-sync
```

이 명령은 로그인을 한 번 요청한 뒤 `~/Documents/GitHub`의 Git 저장소를 순회한다. Doppler project는 저장소명, config는 `local`로 고정하며 기존 `.env`는 보존한다. 생성하는 파일은 mode 0600으로 원자적으로 배치하고 Doppler fallback cache는 만들지 않는다.

## 패키지 동기화

macOS Brewfile 변경 시 zerobrew를 먼저 실행하고, 성공하면 종료한다. zerobrew가 없거나 실패한 경우에만 Homebrew로 폴백한다. 이미 설치된 `xcodes`는 Homebrew bundle 실행에서 제외하지만 나머지 package upgrade는 유지한다. 최종 check 실패는 apply 실패다.

`/opt/zerobrew/bin`은 PATH에서 Homebrew보다 앞에 온다. 같은 이름의 명령은 zerobrew 버전이 쓰이고 zerobrew에 없는 명령은 Homebrew로 폴백된다. 경로는 `ZEROBREW_PREFIX`로 바꿀 수 있다.

대화형 셸의 `brew update`는 zerobrew와 Homebrew 메타데이터를 순서대로 갱신한다. 인자 없는 `brew upgrade`도 zerobrew를 먼저 실행한 뒤 기존 Homebrew 소유 패키지를 갱신한다. 대상을 지정한 `brew upgrade <formula>`는 zerobrew가 성공하면 종료하고 실패할 때만 Homebrew로 폴백하며, `brew upgrade --cask`는 Homebrew로 바로 전달한다. 다른 `brew` 하위 명령도 Homebrew로 그대로 전달된다.

Brewfile에서 삭제된 package는 자동 제거하지 않는다. 제거 후보를 검토할 때만 수동으로 실행한다.

```sh
brew bundle cleanup --file="$(chezmoi source-path)/Brewfile"
```

## 문제 해결

| 증상 | 의미 | 조치 |
|---|---|---|
| Brewfile 최종 check 실패 | zerobrew와 Homebrew 후에도 항목 누락 | 출력된 cask/tap 문제를 해결하고 `chezmoi apply` 재실행 |
| Doppler 로그인에 interactive terminal 필요 | 예약 update 등 비대화형 실행에서 최초 로그인 불가 | 터미널에서 `projects-doppler-sync` 실행 |
| GitHub 사용자/API 조회 실패 | 잘못된 name, organization, network·rate limit 오류 | name을 확인한 뒤 `projects-bootstrap GITHUB_NAME` 재실행 |

## 운영 경계

- 비밀은 Git/chezmoi source에 저장하지 않는다.
- `refreshPeriod`는 scheduler가 아니라 external cache age다.
- `@latest` tokscale 사용은 의도된 정책이다.
- 시스템 timezone이 Asia/Seoul이 아닌 머신은 예약 시각 보장 범위 밖이다.
- 자동 dotfiles update는 dirty source에서 중단하며 실행·성공 timestamp를 기록하지 않는다.
