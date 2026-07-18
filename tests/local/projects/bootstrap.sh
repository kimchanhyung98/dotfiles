#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
command_path="$repo_dir/home/dot_local/bin/executable_projects-bootstrap"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_bin="$test_root/bin"
fixtures="$test_root/fixtures"
projects="$test_root/projects"
mkdir -p "$fake_bin" "$fixtures" "$projects/existing/.git" "$projects/conflict"
printf 'keep\n' > "$projects/existing/marker"

cat > "$fixtures/profile.json" <<'EOF'
{"type":"User","login":"ExampleUser"}
EOF
cat > "$fixtures/repositories.json" <<'EOF'
[
  {"name":"active","clone_url":"https://example.invalid/active.git","archived":false,"private":false,"owner":{"type":"User"}},
  {"name":"existing","clone_url":"https://example.invalid/existing.git","archived":false,"private":false,"owner":{"type":"User"}},
  {"name":"conflict","clone_url":"https://example.invalid/conflict.git","archived":false,"private":false,"owner":{"type":"User"}},
  {"name":"archived","clone_url":"https://example.invalid/archived.git","archived":true,"private":false,"owner":{"type":"User"}},
  {"name":"private","clone_url":"https://example.invalid/private.git","archived":false,"private":true,"owner":{"type":"User"}}
]
EOF

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
    */repos\?*) cp "$FIXTURES/repositories.json" "$output" ;;
    */users/*) cp "$FIXTURES/profile.json" "$output" ;;
    *) exit 1 ;;
esac
printf '200'
EOF
cat > "$fake_bin/git" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" != "clone" ]; then
    exit 1
fi
destination="${@: -1}"
mkdir -p "$destination/.git"
EOF
chmod +x "$fake_bin/curl" "$fake_bin/git"

bootstrap_errors="$test_root/bootstrap-errors.log"
PATH="$fake_bin:$PATH" \
FIXTURES="$fixtures" \
PROJECTS_ROOT="$projects" \
    bash "$command_path" example >/dev/null 2>"$bootstrap_errors"

test -d "$projects/active/.git"
grep -Fq 'keep' "$projects/existing/marker"
test ! -e "$projects/archived"
test ! -e "$projects/private"
grep -Fq '[warning] some repositories were not cloned' "$bootstrap_errors"
grep -Fq 'destination exists but is not a Git repository' "$bootstrap_errors"

dry_run_projects="$test_root/dry-run-projects"
dry_run_output="$(
    PATH="$fake_bin:$PATH" \
    FIXTURES="$fixtures" \
    PROJECTS_ROOT="$dry_run_projects" \
        bash "$command_path" --dry-run example
)"
test ! -e "$dry_run_projects"
grep -Fq '[dry-run] clone ExampleUser/active' <<<"$dry_run_output"
