# Zsh 기본 설정

# 히스토리 설정
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# 키 바인딩
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
