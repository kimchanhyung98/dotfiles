#!/usr/bin/env bash

set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=tests/lib/chezmoi-test.sh
source "$tests_root/lib/chezmoi-test.sh"

test_home="$(mktemp -d)"
trap 'rm -rf "$test_home"' EXIT
configure_chezmoi_test_home "$test_home"

rendered="$test_home/projects-bootstrap-once.sh"
run_chezmoi "$test_home" execute-template \
    < "$repo_dir/home/.chezmoiscripts/run_once_after_90-projects-bootstrap.sh.tmpl" \
    > "$rendered"
bash -n "$rendered"

log="$test_home/bootstrap.log"
HOME="$test_home" bash "$rendered" >"$log" 2>&1
grep -Fq 'helper missing or not executable' "$log"

mkdir -p "$test_home/.local/bin"
cat > "$test_home/.local/bin/projects-bootstrap" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
cat > "$test_home/.local/bin/projects-doppler-sync" <<'EOF'
#!/usr/bin/env sh
touch "$DOPPLER_CALLED"
EOF
chmod +x \
    "$test_home/.local/bin/projects-bootstrap" \
    "$test_home/.local/bin/projects-doppler-sync"

doppler_called="$test_home/doppler-called"
DOPPLER_CALLED="$doppler_called" HOME="$test_home" \
    bash "$rendered" >"$log" 2>&1
grep -Fq "retry manually: projects-bootstrap 'Test User'" "$log"
test ! -e "$doppler_called"

cat > "$test_home/.local/bin/projects-bootstrap" <<'EOF'
#!/usr/bin/env sh
exit 0
EOF
cat > "$test_home/.local/bin/projects-doppler-sync" <<'EOF'
#!/usr/bin/env sh
exit 1
EOF
chmod +x \
    "$test_home/.local/bin/projects-bootstrap" \
    "$test_home/.local/bin/projects-doppler-sync"

HOME="$test_home" bash "$rendered" >"$log" 2>&1
grep -Fq 'retry manually: projects-doppler-sync' "$log"

CODESPACES=true HOME="$test_home" bash "$rendered" >"$log" 2>&1
grep -Fq 'skipped in GitHub Codespaces' "$log"
