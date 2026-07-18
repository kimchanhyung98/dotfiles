#!/usr/bin/env bash

set -euo pipefail

test "${CODESPACES:-false}" = "true"
test "$(id -u)" -ne 0
