# 외부 도구 셸 통합

# direnv
if command -v direnv &>/dev/null; then
    eval "$(direnv hook zsh)"
fi

# mise
if command -v mise &>/dev/null; then
    eval "$(mise activate zsh)"
fi

# fzf
if command -v fzf &>/dev/null; then
    source <(fzf --zsh) 2>/dev/null || true
fi

# Bun
if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    case ":$PATH:" in
        *":$BUN_INSTALL/bin:"*) ;;
        *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
    esac
fi

# zoxide
if command -v zoxide &>/dev/null; then
    eval "$(zoxide init zsh)"
fi
