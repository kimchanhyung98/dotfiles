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

# Kimi Code
export KIMI_NO_MODIFY_PATH=1

# - installer 기본 경로. rg/fd 캐시도 같은 디렉토리에 담기므로 PATH 뒤에 붙여 시스템 도구를 가리지 않게 한다.
if [ -d "$HOME/.kimi-code/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.kimi-code/bin:"*) ;;
        *) export PATH="$PATH:$HOME/.kimi-code/bin" ;;
    esac
fi
