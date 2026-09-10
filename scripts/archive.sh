#!/usr/bin/env bash
#
# archive.sh — Build a signed archive suitable for App Store Connect.
# Run before `submit.sh`.
#
set -euo pipefail

cd "$(dirname "$0")/.."

CONFIG="${1:-Release}"
OUT_DIR="./build"
ARCHIVE="$OUT_DIR/Quill.xcarchive"
IPA="$OUT_DIR/Quill.ipa"

echo "🛠  Generating Xcode project"
xcodegen generate --quiet

echo "📦  Building archive (config=$CONFIG)…"
xcodebuild \
    -project Quill.xcodeproj \
    -scheme Quill \
    -configuration "$CONFIG" \
    -destination "generic/platform=iOS" \
    -archivePath "$ARCHIVE" \
    archive

echo "📦  Exporting IPA…"
xcodebuild \
    -exportArchive \
    -archivePath "$ARCHIVE" \
    -exportPath "$OUT_DIR" \
    -exportOptionsPlist "$OUT_DIR/exportOptions.plist"

if [[ ! -f "$IPA" ]]; then
    IPA="$(ls -1 "$OUT_DIR"/*.ipa 2>/dev/null | head -1)"
fi

if [[ ! -f "$IPA" ]]; then
    echo "❌ IPA not produced"; exit 1
fi

echo "✅ Archive + IPA ready at:"
echo "     $ARCHIVE"
echo "     $IPA"
echo ""
echo "Next: scripts/submit.sh $IPA"
