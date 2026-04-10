# Zsh 플러그인 로드 설정 (Oh My Zsh)

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
)

if [ -f "$ZSH/oh-my-zsh.sh" ]; then
    source "$ZSH/oh-my-zsh.sh"
else
    echo "[zshrc][warning] Oh My Zsh not found at $ZSH — plugins disabled" >&2
fi
