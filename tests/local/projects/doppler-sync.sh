#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
command_path="$repo_dir/home/dot_local/bin/executable_projects-doppler-sync"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

test_home="$test_root/home"
fake_bin="$test_home/.local/bin"
projects="$test_root/projects"
mkdir -p \
    "$fake_bin" \
    "$projects/matched/.git" \
    "$projects/unmatched/.git" \
    "$projects/preserved/.git" \
    "$projects/not-a-repository"
printf 'ORIGINAL=1\n' > "$projects/preserved/.env"

cat > "$fake_bin/doppler" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

case " $* " in
    *' me '*) exit 0 ;;
    *' secrets download '*)
        project=""
        while [ "$#" -gt 0 ]; do
            if [ "$1" = "--project" ]; then
                project="$2"
                break
            fi
            shift
        done
        if [ "$project" = "matched" ]; then
            printf 'TOKEN=fixture\n'
            exit 0
        fi
        exit 1
        ;;
esac
exit 1
EOF
chmod +x "$fake_bin/doppler"

HOME="$test_home" PROJECTS_ROOT="$projects" bash "$command_path" >/dev/null

grep -Fq 'TOKEN=fixture' "$projects/matched/.env"
grep -Fq 'ORIGINAL=1' "$projects/preserved/.env"
test ! -e "$projects/unmatched/.env"
test ! -e "$projects/not-a-repository/.env"

case "$(uname -s)" in
    Darwin) mode="$(stat -f '%Lp' "$projects/matched/.env")" ;;
    Linux) mode="$(stat -c '%a' "$projects/matched/.env")" ;;
esac
test "$mode" = "600"
