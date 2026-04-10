# fzf
if command -v fzf &>/dev/null; then
    source <(fzf --zsh) 2>/dev/null || true
fi
