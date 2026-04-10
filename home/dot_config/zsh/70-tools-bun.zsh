# Bun 런타임 환경 설정
if [ -d "$HOME/.bun" ]; then
    export BUN_INSTALL="$HOME/.bun"
    case ":$PATH:" in
        *":$BUN_INSTALL/bin:"*) ;;
        *) export PATH="$BUN_INSTALL/bin:$PATH" ;;
    esac
fi
