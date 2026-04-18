# Zsh 기본 설정

# 히스토리 설정
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# 기본 편집 모드 (화살표 등 히스토리 탐색은 Oh My Zsh의 기본 바인딩 사용)
bindkey -e
