#!/usr/bin/env bash
#
# screenshot.sh — Capture App Store screenshots via Fastlane snapshot.
#
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v fastlane >/dev/null 2>&1; then
    echo "❌ fastlane not installed. Try: brew install fastlane"
    exit 1
fi

xcodegen generate --quiet

echo "📸  Capturing screenshots…"
fastlane ios screenshots

OUT="$(pwd)/build/screenshots"
if [[ -d "$OUT" ]]; then
    echo "✅  Screenshots saved to $OUT"
    ls -la "$OUT"
else
    echo "⚠️  No screenshots/ directory produced. Inspect fastlane output above."
fi
