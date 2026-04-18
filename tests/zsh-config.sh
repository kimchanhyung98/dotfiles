#!/bin/bash
#
# Zsh 설정 회귀 테스트
# - LANG 폴백이 UTF-8 locale을 올바르게 설정하는지 확인
# - Oh My Zsh 이후에도 fzf Ctrl-R 바인딩이 유지되는지 확인

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
SOURCE_DIR="${CHEZMOI_SOURCE_DIR:-${REPO_DIR}/home}"

if [ ! -d "${SOURCE_DIR}" ]; then
    SOURCE_DIR="${HOME}/.local/share/chezmoi"
fi

PASS=0
FAIL=0

pass() {
    echo "  ✅ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  ❌ $1"
    FAIL=$((FAIL + 1))
}

section() {
    echo ""
    echo "--- $1 ---"
}

write_test_chezmoi_config() {
    local test_home="$1"
    local homebrew_prefix="$2"

    mkdir -p "${test_home}/.config/chezmoi"
    cat > "${test_home}/.config/chezmoi/chezmoi.toml" <<EOF
[data]
    name = "Test User"
    email = "test@example.com"
    homebrewPrefix = "${homebrew_prefix}"
    isAppleSilicon = true
EOF
}

setup_rendered_zsh_home() {
    local test_home="$1"
    local homebrew_prefix="$2"

    mkdir -p "${test_home}/.config/zsh"
    write_test_chezmoi_config "${test_home}" "${homebrew_prefix}"

    HOME="${test_home}" XDG_CONFIG_HOME="${test_home}/.config" \
        chezmoi execute-template < "${SOURCE_DIR}/dot_zshrc.tmpl" > "${test_home}/.zshrc"
    HOME="${test_home}" XDG_CONFIG_HOME="${test_home}/.config" \
        chezmoi execute-template < "${SOURCE_DIR}/dot_config/zsh/20-path.zsh.tmpl" > "${test_home}/.config/zsh/20-path.zsh"
    HOME="${test_home}" XDG_CONFIG_HOME="${test_home}/.config" \
        chezmoi execute-template < "${SOURCE_DIR}/dot_config/zsh/30-functions.zsh.tmpl" > "${test_home}/.config/zsh/30-functions.zsh"

    cp "${SOURCE_DIR}"/dot_config/zsh/*.zsh "${test_home}/.config/zsh/"
}

setup_fake_commands() {
    local fakebin="$1"
    local test_home="$2"
    local homebrew_prefix="$3"

    mkdir -p "${fakebin}" "${test_home}/.oh-my-zsh" "${homebrew_prefix}/bin"

    cat > "${fakebin}/locale" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "-a" ]; then
    cat <<'LOCALES'
POSIX
C
C.UTF-8
en_US.UTF-8
LOCALES
    exit 0
fi
exit 1
EOF

    cat > "${fakebin}/fzf" <<'EOF'
#!/bin/sh
if [ "${1:-}" = "--zsh" ]; then
    cat <<'FZF'
fzf-history-widget() { :; }
bindkey '^R' fzf-history-widget
FZF
    exit 0
fi
exit 1
EOF

    cat > "${test_home}/.oh-my-zsh/oh-my-zsh.sh" <<'EOF'
bindkey '^R' history-incremental-search-backward
EOF

    cat > "${homebrew_prefix}/bin/brew" <<EOF
#!/bin/sh
count_file="\${HOME}/brew-shellenv-count"
if [ "\${1:-}" = "shellenv" ]; then
    count=0
    if [ -f "\${count_file}" ]; then
        count=\$(cat "\${count_file}")
    fi
    count=\$((count + 1))
    printf '%s' "\${count}" > "\${count_file}"
    cat <<'BREW'
export HOMEBREW_PREFIX="${homebrew_prefix}";
export PATH="${homebrew_prefix}/bin:${homebrew_prefix}/sbin:\$PATH";
fpath[1,0]="${homebrew_prefix}/share/zsh/site-functions";
BREW
    exit 0
fi
exit 1
EOF

    chmod +x "${fakebin}/locale" "${fakebin}/fzf" "${homebrew_prefix}/bin/brew"
}

cleanup_temp_homes() {
    rm -rf \
        "${lang_home:-}" \
        "${bind_home:-}" \
        "${guard_home:-}" \
        "${missing_home:-}"
}
trap cleanup_temp_homes EXIT

section "LANG fallback"
lang_home="$(mktemp -d)"
lang_homebrew_prefix="${lang_home}/fake-homebrew"
setup_rendered_zsh_home "${lang_home}" "${lang_homebrew_prefix}"
setup_fake_commands "${lang_home}/fakebin" "${lang_home}" "${lang_homebrew_prefix}"

lang_value="$(
    env -i \
        HOME="${lang_home}" \
        PATH="${lang_home}/fakebin:/usr/bin:/bin" \
        zsh -fc '
            unset LANG LC_ALL
            source "$HOME/.config/zsh/10-env.zsh"
            print -r -- "${LANG:-__unset__}"
        '
)"

if [ "${lang_value}" = "en_US.UTF-8" ]; then
    pass "LANG falls back to en_US.UTF-8 when locale is available"
else
    echo "    got: ${lang_value}"
    fail "LANG fallback did not select en_US.UTF-8"
fi

section "fzf binding order"
bind_home="$(mktemp -d)"
bind_homebrew_prefix="${bind_home}/fake-homebrew"
setup_rendered_zsh_home "${bind_home}" "${bind_homebrew_prefix}"
setup_fake_commands "${bind_home}/fakebin" "${bind_home}" "${bind_homebrew_prefix}"

bind_output="$(
    env -i \
        HOME="${bind_home}" \
        ZDOTDIR="${bind_home}" \
        HOMEBREW_SHELLENV_LOADED=1 \
        PATH="${bind_home}/fakebin:/usr/bin:/bin" \
        zsh -ic "bindkey '^R'" 2>/dev/null
)"

if printf '%s\n' "${bind_output}" | grep -q 'fzf-history-widget'; then
    pass "Ctrl-R remains bound to fzf-history-widget after startup"
else
    echo "    got: ${bind_output}"
    fail "Ctrl-R binding was overwritten during startup"
fi

section "Homebrew shellenv guard"
guard_home="$(mktemp -d)"
guard_homebrew_prefix="${guard_home}/fake-homebrew"
setup_rendered_zsh_home "${guard_home}" "${guard_homebrew_prefix}"
setup_fake_commands "${guard_home}/fakebin" "${guard_home}" "${guard_homebrew_prefix}"

if grep -q 'brew shellenv' "${guard_home}/.config/zsh/20-path.zsh"; then
    guard_count="$(
        env -i \
            HOME="${guard_home}" \
            PATH="/usr/bin:/bin" \
            zsh -fc '
                source "$HOME/.config/zsh/20-path.zsh"
                source "$HOME/.config/zsh/20-path.zsh"
                cat "$HOME/brew-shellenv-count"
            '
    )"

    if [ "${guard_count}" = "1" ]; then
        pass "Homebrew shellenv runs only once across repeated sourcing"
    else
        echo "    got: ${guard_count}"
        fail "Homebrew shellenv reran on repeated sourcing"
    fi
else
    pass "Non-darwin render skips Homebrew shellenv"
fi

section "Missing Homebrew safety"
missing_home="$(mktemp -d)"
missing_homebrew_prefix="${missing_home}/fake-homebrew"
setup_rendered_zsh_home "${missing_home}" "${missing_homebrew_prefix}"
setup_fake_commands "${missing_home}/fakebin" "${missing_home}" "${missing_homebrew_prefix}"
rm -f "${missing_homebrew_prefix}/bin/brew"

if grep -q 'brew shellenv' "${missing_home}/.config/zsh/20-path.zsh"; then
    missing_stderr="${missing_home}/missing-brew.stderr"
    if env -i HOME="${missing_home}" PATH="/usr/bin:/bin" zsh -fc 'source "$HOME/.config/zsh/20-path.zsh"' >/dev/null 2>"${missing_stderr}"; then
        if [ ! -s "${missing_stderr}" ]; then
            pass "Missing Homebrew does not break shell startup"
        else
            echo "    got:"
            sed 's/^/    /' "${missing_stderr}"
            fail "Missing Homebrew emitted startup errors"
        fi
    else
        fail "Missing Homebrew broke shell startup"
    fi
else
    pass "Non-darwin render does not require Homebrew"
fi

echo ""
echo "=============================="
echo "  Results: ${PASS} passed, ${FAIL} failed"
echo "=============================="

if [ "${FAIL}" -gt 0 ]; then
    exit 1
fi
