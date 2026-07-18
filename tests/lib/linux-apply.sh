#!/usr/bin/env bash

set -euo pipefail

linux_apply_dotfiles() {
    local fixture_root="$1"
    local fake_bin="$fixture_root/bin"
    local skills_repo="$fixture_root/skills-repo"
    local skill_root
    local tool
    local apply_log="$fixture_root/chezmoi-apply.log"

    mkdir -p "$fake_bin" "$skills_repo" "$HOME/.local/bin"

    git init --quiet "$skills_repo"
    git -C "$skills_repo" checkout --quiet -b main
    for skill_root in \
        skills/engineering/codebase-design \
        skills/engineering/diagnosing-bugs \
        skills/engineering/domain-modeling \
        skills/engineering/grill-with-docs \
        skills/engineering/improve-codebase-architecture \
        skills/engineering/prototype \
        skills/engineering/setup-matt-pocock-skills \
        skills/engineering/tdd \
        skills/engineering/to-issues \
        skills/engineering/to-prd \
        skills/engineering/triage \
        skills/productivity/grill-me \
        skills/productivity/grilling \
        skills/productivity/handoff \
        skills/productivity/writing-great-skills; do
        mkdir -p "$skills_repo/$skill_root"
        printf '# fixture\n' > "$skills_repo/$skill_root/SKILL.md"
    done
    git -C "$skills_repo" add .
    git -C "$skills_repo" \
        -c user.name='dotfiles tests' \
        -c user.email='dotfiles-tests@example.invalid' \
        commit --quiet -m fixtures
    git -C "$skills_repo" tag v1.0.1

    cat > "$fake_bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

output=""
url=""
while [ "$#" -gt 0 ]; do
    case "$1" in
        --output)
            output="$2"
            shift 2
            ;;
        http://* | https://*)
            url="$1"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

case "$url" in
    */repos\?*) printf '[]\n' > "$output" ;;
    */users/*) printf '{"type":"User","login":"TestUser"}\n' > "$output" ;;
    *) exit 1 ;;
esac
printf '200'
EOF
    cat > "$fake_bin/ssh-keyscan" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
    chmod +x "$fake_bin/curl" "$fake_bin/ssh-keyscan"

    cat > "$HOME/.local/bin/dotfiles-test-tool" <<'EOF'
#!/usr/bin/env sh
case "${1:-}" in
    me) exit 0 ;;
    --version) printf 'test tool 1.0\n' ;;
esac
exit 0
EOF
    chmod +x "$HOME/.local/bin/dotfiles-test-tool"
    for tool in claude codex copilot agy hermes doppler; do
        ln -sf dotfiles-test-tool "$HOME/.local/bin/$tool"
    done

    if ! PATH="$fake_bin:$HOME/.local/bin:$PATH" \
        MATTPOCOCK_SKILLS_REPO_URL="file://$skills_repo" \
            chezmoi apply --exclude=externals --force --verbose >"$apply_log" 2>&1; then
        tail -100 "$apply_log" >&2
        return 1
    fi

    if ! chezmoi verify --exclude=externals; then
        echo "chezmoi verify failed after apply" >&2
        return 1
    fi
}
