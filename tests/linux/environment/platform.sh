#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC1091
. /etc/os-release
test "$ID" = "ubuntu"
test "$VERSION_ID" = "26.04"
test "$(id -u)" -ne 0
test "${CODESPACES:-false}" != "true"
