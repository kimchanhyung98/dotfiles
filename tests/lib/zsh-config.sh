#!/usr/bin/env bash

set -euo pipefail

test_zsh_config() {
    local test_home="$1"
    local source_dir="$2"
    local fake_bin="$test_home/bin"
    local lang_value
    local binding

    mkdir -p "$test_home/.config/zsh" "$test_home/.oh-my-zsh" "$fake_bin"
    run_chezmoi "$test_home" execute-template < "$source_dir/dot_zshrc.tmpl" > "$test_home/.zshrc"
    run_chezmoi "$test_home" execute-template \
        < "$source_dir/dot_config/zsh/20-path.zsh.tmpl" \
        > "$test_home/.config/zsh/20-path.zsh"
    run_chezmoi "$test_home" execute-template \
        < "$source_dir/dot_config/zsh/30-functions.zsh.tmpl" \
        > "$test_home/.config/zsh/30-functions.zsh"
    cp "$source_dir"/dot_config/zsh/*.zsh "$test_home/.config/zsh/"

    for zsh_file in "$test_home/.zshrc" "$test_home"/.config/zsh/*.zsh; do
        zsh -n "$zsh_file"
    done

    cat > "$fake_bin/locale" <<'EOF'
#!/usr/bin/env sh
if [ "${1:-}" = "-a" ]; then
    printf '%s\n' POSIX C C.UTF-8 en_US.UTF-8
    exit 0
fi
exit 1
EOF
    cat > "$fake_bin/fzf" <<'EOF'
#!/usr/bin/env sh
if [ "${1:-}" = "--zsh" ]; then
    printf '%s\n' 'fzf-history-widget() { :; }' "bindkey '^R' fzf-history-widget"
    exit 0
fi
exit 1
EOF
    cat > "$test_home/.oh-my-zsh/oh-my-zsh.sh" <<'EOF'
bindkey '^R' history-incremental-search-backward
EOF
    chmod +x "$fake_bin/locale" "$fake_bin/fzf"

    lang_value="$(
        env -i HOME="$test_home" PATH="$fake_bin:/usr/bin:/bin" zsh -fc '
            unset LANG LC_ALL
            source "$HOME/.config/zsh/10-env.zsh"
            print -r -- "${LANG:-__unset__}"
        '
    )"
    test "$lang_value" = 'en_US.UTF-8'

    binding="$(
        env -i \
            HOME="$test_home" \
            ZDOTDIR="$test_home" \
            HOMEBREW_SHELLENV_LOADED=1 \
            PATH="$fake_bin:/usr/bin:/bin" \
            zsh -ic "bindkey '^R'" 2>/dev/null
    )"
    grep -Fq 'fzf-history-widget' <<<"$binding"
}
