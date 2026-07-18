#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
command_path="$repo_dir/home/dot_local/bin/executable_dotfiles-update"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

source_repo="$test_root/source"
fake_bin="$test_root/bin"
call_log="$test_root/chezmoi-calls.log"
mkdir -p "$source_repo" "$fake_bin"
git -C "$source_repo" init --quiet
printf 'tracked\n' > "$source_repo/tracked.txt"
git -C "$source_repo" add tracked.txt
git -C "$source_repo" \
    -c user.name='dotfiles tests' \
    -c user.email='dotfiles-tests@example.invalid' \
    commit --quiet -m initial

cat > "$fake_bin/chezmoi" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
    source-path) printf '%s\n' "$SOURCE_REPO" ;;
    update | verify) printf '%s\n' "$*" >> "$CALL_LOG" ;;
    *) exit 1 ;;
esac
EOF
chmod +x "$fake_bin/chezmoi"

for _ in 1 2; do
    PATH="$fake_bin:$PATH" SOURCE_REPO="$source_repo" CALL_LOG="$call_log" \
        bash "$command_path" >/dev/null
done

test "$(grep -Fc 'update --no-tty' "$call_log")" -eq 2
test "$(grep -Fc 'verify' "$call_log")" -eq 2

printf 'dirty\n' > "$source_repo/untracked.txt"
if PATH="$fake_bin:$PATH" SOURCE_REPO="$source_repo" CALL_LOG="$call_log" \
    bash "$command_path" >"$test_root/dirty.log" 2>&1; then
    echo 'dirty source repository was accepted' >&2
    exit 1
fi
grep -Fq 'source repository has local changes' "$test_root/dirty.log"
test "$(grep -Fc 'update --no-tty' "$call_log")" -eq 2
