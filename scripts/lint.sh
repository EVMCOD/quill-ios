#!/usr/bin/env bash
#
# lint.sh — Gate check before merging anything to main.
#
set -euo pipefail
cd "$(dirname "$0")/.."

ERRORS=0
step() { echo ""; echo "── $1"; }
fail() { echo "❌  $1"; ERRORS=$((ERRORS + 1)); }

step "1/5  xcodegen generate"
if xcodegen generate --quiet; then echo "✅  .xcodeproj regenerated"
else fail "xcodegen failed"; fi

step "2/5  xcodebuild iOS Debug"
LOG=/tmp/quill-lint-build.log
if xcodebuild \
    -project Quill.xcodeproj \
    -scheme Quill \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -configuration Debug \
    build > "$LOG" 2>&1; then
    ECOUNT=$(grep -c "error:" "$LOG" 2>/dev/null || echo 0)
    WCOUNT=$(grep -c "warning:" "$LOG" 2>/dev/null || echo 0)
    echo "✅  iOS Build SUCCEEDED · errors=$ECOUNT, warnings=$WCOUNT"
else
    ERR_COUNT=$(grep -c "error:" "$LOG" 2>/dev/null || echo 0)
    fail "iOS build failed with $ERR_COUNT errors — see $LOG"
fi

step "3/5  xcodebuild macOS Debug"
MAC_LOG=/tmp/quill-mac-lint-build.log
if xcodebuild \
    -project Quill.xcodeproj \
    -scheme QuillMac \
    -destination 'platform=macOS' \
    -configuration Debug \
    -allowProvisioningUpdates \
    build > "$MAC_LOG" 2>&1; then
    ECOUNT=$(grep -c "error:" "$MAC_LOG" 2>/dev/null || echo 0)
    WCOUNT=$(grep -c "warning:" "$MAC_LOG" 2>/dev/null || echo 0)
    echo "✅  macOS Build SUCCEEDED · errors=$ECOUNT, warnings=$WCOUNT"
else
    ERR_COUNT=$(grep -c "error:" "$MAC_LOG" 2>/dev/null || echo 0)
    fail "macOS build failed with $ERR_COUNT errors — see $MAC_LOG"
fi

step "4/5  PrivacyInfo.xcprivacy"
PI="Quill/PrivacyInfo.xcprivacy"
if [[ -f "$PI" ]]; then
    if python3 -c "import plistlib; plistlib.load(open('$PI','rb')); print('valid')" 2>/dev/null | grep -q valid; then
        echo "✅  $PI is valid XML plist"
    else fail "$PI does not parse as XML plist"
    fi
else fail "$PI missing"; fi

step "5/5  Localizable.xcstrings"
if [[ -f "Quill/Resources/Localizable.xcstrings" ]]; then
    STRINGS=$(python3 -c "import json; print(len(json.load(open('Quill/Resources/Localizable.xcstrings'))['strings']))")
    echo "✅  $STRINGS strings present"
else fail "Localizable.xcstrings missing"; fi

echo ""
if [[ $ERRORS -eq 0 ]]; then
    echo "🟢  All gate checks passed."; exit 0
else
    echo "🔴  $ERRORS gate check(s) failed."; exit 1
fi
