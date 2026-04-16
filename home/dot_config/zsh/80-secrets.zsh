# 민감 정보는 로컬 전용 파일로 분리
# 예: ~/.config/zsh/secrets.local.zsh

if [ -f "$HOME/.config/zsh/secrets.local.zsh" ]; then
    source "$HOME/.config/zsh/secrets.local.zsh"
fi
