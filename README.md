# dotfiles

> macOS dotfiles managed with [chezmoi](https://www.chezmoi.io/)

## Features

- **macOS Support**: Intel & Apple Silicon Macs 지원
- **chezmoi**: 안전하고 유연한 dotfiles 관리
- **Homebrew**: 자동 설치 및 패키지 관리
- **Template System**: 환경별 조건부 설정 적용

## Quick Start

### One-line Install

```bash
curl -fsSL https://raw.githubusercontent.com/kimchanhyung98/dotfiles/main/install.sh | bash
```

### Manual Install

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Apply dotfiles
chezmoi init --apply kimchanhyung98
```

## Structure

```
.
├── .chezmoiroot          # chezmoi source directory 설정 (home)
├── .chezmoiversion       # 최소 chezmoi 버전
├── home/                 # chezmoi source directory
│   ├── .chezmoi.toml.tmpl    # chezmoi 설정 템플릿
│   ├── .chezmoiignore        # 무시할 파일 패턴
│   ├── .chezmoiscripts/      # 자동 실행 스크립트
│   │   └── darwin/           # macOS 전용 스크립트
│   ├── dot_zshrc.tmpl        # zsh 설정
│   ├── dot_gitconfig.tmpl    # git 설정
│   └── dot_gitignore_global  # global gitignore
├── install.sh            # 설치 스크립트
└── README.md
```

## Commands

```bash
# 변경사항 확인
chezmoi diff

# dotfiles 적용
chezmoi apply

# 설정 편집
chezmoi edit ~/.zshrc

# 파일 추가
chezmoi add ~/.config/some-config

# chezmoi source 디렉토리 열기
chezmoi cd
```

## Customization

초기 설정 시 다음 정보를 입력받습니다:
- Full name (Git 커밋용)
- Email address (Git 커밋용)

설정은 `~/.config/chezmoi/chezmoi.toml`에 저장됩니다.

## Architecture Detection

Apple Silicon (arm64) 또는 Intel (amd64) 아키텍처를 자동으로 감지하여:
- Homebrew 경로 설정 (`/opt/homebrew` vs `/usr/local`)
- Rosetta 2 자동 설치 (Apple Silicon)

## Requirements

- macOS (Intel or Apple Silicon)
- Git
- curl

## License

MIT License