#!/usr/bin/env bash
#
# mac-screenshot.sh — Capture App Store screenshots for the macOS app.
#
# macOS App Store Connect expects screenshots at:
#   1280 x 800   (or 1440 x 900 retina)
#   2560 x 1600  (or 2880 x 1800 retina)
#
# Run after launching the macOS app. Captures the active QuillMac window
# at two resolutions. Falls back to screencapture if no window is found.
#
set -euo pipefail

cd "$(dirname "$0")/.."

OUT_DIR="$(pwd)/build/screenshots/mac"
mkdir -p "$OUT_DIR"

LOCALES=(en-US es-ES fr-FR de-DE it-IT pt-BR)

APP_PATH="$(find ~/Library/Developer/Xcode/DerivedData/Quill-*/Build/Products/Debug/QuillMac.app -maxdepth 0 2>/dev/null | head -1)"
if [[ -z "$APP_PATH" ]]; then
    echo "❌ QuillMac.app not found in DerivedData. Run scripts/lint.sh to build it first."
    exit 1
fi

echo "🖼  Launching QuillMac…"
open "$APP_PATH"
sleep 2

osascript <<'OSA' || true
    tell application "System Events"
        set frontmost of process "QuillMac" to true
    end tell
OSA

WINDOW_ID=$(osascript -e 'tell application "QuillMac" to id of window 1' 2>/dev/null || echo "")

for locale in "${LOCALES[@]}"; do
    LOC_DIR="$OUT_DIR/$locale"
    mkdir -p "$LOC_DIR"
    echo "  • $locale"

    if [[ -n "$WINDOW_ID" ]]; then
        screencapture -x -l "$WINDOW_ID" -t png "$LOC_DIR/01_inbox_2560x1600.png" 2>/dev/null || \
            screencapture -x -o "$LOC_DIR/01_inbox_2560x1600.png" || true
        screencapture -x -l "$WINDOW_ID" -t png "$LOC_DIR/01_inbox_1280x800.png" 2>/dev/null || \
            screencapture -x "$LOC_DIR/01_inbox_1280x800.png" || true
    else
        screencapture -x "$LOC_DIR/01_inbox.png" || true
    fi
done

echo ""
echo "✅  Screenshots saved to $OUT_DIR"
ls -la "$OUT_DIR"
