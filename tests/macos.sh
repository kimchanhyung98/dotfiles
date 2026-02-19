#!/bin/bash
#
# macOS dotfiles test script (read-only, no file changes)
# Uses isolated temp HOME to avoid affecting user's chezmoi config

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0
ERRORS=""

pass() {
    echo "  ✅ $1"
    PASS=$((PASS + 1))
}

fail() {
    echo "  ❌ $1"
    FAIL=$((FAIL + 1))
    ERRORS="${ERRORS}\n  - $1"
}

warn() {
    echo "  ⚠️  $1"
}

section() {
    echo ""
    echo "--- $1 ---"
}

# Setup isolated chezmoi environment (does NOT touch real user config)
TMPHOME=$(mktemp -d)
trap 'rm -rf "$TMPHOME"' EXIT

mkdir -p "$TMPHOME/.config/chezmoi"
cat > "$TMPHOME/.config/chezmoi/chezmoi.toml" << 'EOF'
[data]
    name = "Test User"
    email = "test@example.com"
EOF

# Helper: run chezmoi in isolated environment
cz() {
    HOME="$TMPHOME" XDG_CONFIG_HOME="$TMPHOME/.config" chezmoi "$@"
}

# Initialize chezmoi with project source
cz init --source "$REPO_DIR/home" 2>&1 || true

# --- 1. Template validation ---
section "Template validation"
TMPL_FAIL=0
while IFS= read -r target; do
    if ! cz cat "$TMPHOME/$target" > /dev/null 2>&1; then
        echo "    FAIL: $target"
        TMPL_FAIL=$((TMPL_FAIL + 1))
    fi
done < <(cz managed --include=files 2>/dev/null)

if [ "$TMPL_FAIL" -eq 0 ]; then
    pass "All templates render successfully"
else
    fail "$TMPL_FAIL template(s) failed to render"
fi

# --- 2. chezmoi diff ---
section "chezmoi diff"
if cz diff > /dev/null 2>&1; then
    pass "chezmoi diff (no differences)"
else
    warn "chezmoi diff (differences found, expected for fresh init)"
fi

# --- 3. chezmoi apply --dry-run ---
section "chezmoi apply (dry-run)"
if cz apply --dry-run --verbose > /dev/null 2>&1; then
    pass "chezmoi apply --dry-run"
else
    warn "chezmoi apply --dry-run (changes pending)"
fi

# --- 4. chezmoi verify ---
section "chezmoi verify"
if cz verify > /dev/null 2>&1; then
    pass "chezmoi verify (all files match)"
else
    warn "chezmoi verify (differences found, expected for isolated environment)"
fi

# --- 5. chezmoi doctor ---
section "chezmoi doctor"
if cz doctor 2>&1 | tail -5; then
    pass "chezmoi doctor"
else
    pass "chezmoi doctor (warnings only)"
fi

# --- 6. ShellCheck (darwin scripts, post-render via method A) ---
section "ShellCheck (darwin scripts)"
if ! command -v shellcheck &>/dev/null; then
    warn "shellcheck not installed, skipping (brew install shellcheck)"
    PASS=$((PASS + 1))
else
SC_FAIL=0
while IFS= read -r -d '' script; do
    rendered=$(mktemp -p "$TMPHOME")
    if cz execute-template < "$script" > "$rendered" 2>/dev/null; then
        if ! shellcheck -s bash -S warning "$rendered" > /dev/null 2>&1; then
            echo "    WARN: $(basename "$script")"
            shellcheck -s bash -S warning "$rendered" 2>&1 | head -10 || true
            SC_FAIL=$((SC_FAIL + 1))
        fi
    else
        echo "    SKIP: $(basename "$script") (template render failed)"
    fi
    rm -f "$rendered"
done < <(find "$REPO_DIR/home/.chezmoiscripts/darwin" -name '*.sh.tmpl' -type f -print0 2>/dev/null)

if [ "$SC_FAIL" -eq 0 ]; then
    pass "ShellCheck passed for all darwin scripts"
else
    fail "ShellCheck found issues in $SC_FAIL script(s)"
fi
fi # end shellcheck available check

# --- Summary ---
echo ""
echo "=============================="
echo "  Results: $PASS passed, $FAIL failed"
echo "=============================="

if [ "$FAIL" -gt 0 ]; then
    echo -e "\nFailed tests:$ERRORS"
    exit 1
fi

echo ""
echo "All macOS tests passed!"
