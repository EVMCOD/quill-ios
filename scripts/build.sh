#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
xcodegen generate --quiet
xcodebuild \
  -project Quill.xcodeproj \
  -scheme Quill \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
