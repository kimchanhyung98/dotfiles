#!/usr/bin/env bash

# Loaded by tests/run.sh through BASH_ENV so bare assertions identify the failure.
dotfiles_test_case="${DOTFILES_TEST_CASE:-unknown}"
unset BASH_ENV DOTFILES_TEST_CASE
# Test helpers use shell functions, so propagate ERR to report the failing command.
set -o errtrace

dotfiles_report_test_failure() {
    printf '[test][error] %s:%s: exit %d: %s\n' \
        "$dotfiles_test_case" "$2" "$1" "$3" >&2
}

trap 'dotfiles_report_test_failure "$?" "$LINENO" "$BASH_COMMAND"' ERR
