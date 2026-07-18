#!/usr/bin/env bash

set -euo pipefail

managed="$(chezmoi managed --include=all)"
for target in \
    Brewfile \
    .config/cmux/cmux.json \
    .config/rectangle/RectangleConfig.json \
    .config/stats/Stats.plist \
    .config/tokscale/submit.sh \
    Library/LaunchAgents/ai.tokscale.submit.plist; do
    if grep -Fxq "$target" <<<"$managed"; then
        echo "desktop target is managed in Codespaces: $target" >&2
        exit 1
    fi
done
