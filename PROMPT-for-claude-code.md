# Ship Quill iOS + macOS to App Store — autonomous run for Claude Code

## CONTEXT YOU NEED

**App:** Quill — a focused read-later app for iPhone, iPad, and Mac. SwiftUI + SwiftData + WidgetKit + AppIntents. iOS 17.0+ / macOS 14.0+.

**Bundles:**
- iOS:  `app.quill.ios`             (Team `KADHS6P8PY`)
- macOS: `app.quill.macos`
- App Group (shared): `group.app.quill.shared`
- iOS Share Extension: `app.quill.ios.share` (embedded in main bundle)

**Apple ID:** `valerosenrique@gmail.com`

**State of the repo** at HEAD (= `ad9b011`):
- ✅ Code is ship-ready: 32 Swift files, 0 errors, 0 warnings on iOS + macOS.
- ✅ `scripts/lint.sh` = 🟢 5/5 gates green (xcodegen + iOS build + macOS build + PrivacyInfo + Localizable.xcstrings).
- ✅ `Tack/PrivacyInfo.xcprivacy` (sic — same path despite target name) — disk space / UserDefaults / file timestamp reason codes declared.
- ✅ AppIcon 1024×1024 at `Quill/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- ✅ App Store Connect metadata pre-written at `metadata/<locale>/` for all six locales (`en-US`, `es-ES`, `fr-FR`, `de-DE`, `it-IT`, `pt-BR`).
- ✅ Fastlane skeleton in `fastlane/Fastfile` with separate `ios` and `mac` lanes: `register / test / archive / screenshots / upload / ship`.
- ✅ Submission scripts in `scripts/` — `archive.sh`, `submit.sh`, `screenshot.sh`, `mac-archive.sh`, `mac-submit.sh`, `mac-screenshot.sh`, `lint.sh`.
- ✅ `SUBMIT.md` (one-page playbook), `CHANGELOG.md` (single entry, v1.0.0), `ICON.md` (icon design spec).
- ✅ Repository already on `main` at `github.com/EVMCOD/quill-ios`.

**User context:**
- macOS 26.6, Xcode 26.
- User is at the keyboard and will type Apple ID + 2FA codes when prompted.
- The user has 5 minutes of patience and wants to ship both targets tonight.
- Do not take any external action (no `git push --force`, no `gh release`) without explicit confirmation.

## YOUR JOB

Walk through steps 1–5 below, in order. Each step reports success or failure with the exact command that failed and a one-line remediation. Don't skip steps. Don't loop on a failing step — stop and ask.

```
WORKDIR      = /Users/enriquevaleros/quill-ios
BUNDLE_IOS   = app.quill.ios
BUNDLE_MAC   = app.quill.macos
TEAM         = KADHS6P8PY
APPLEID      = valerosenrique@gmail.com
BRANCH       = main
```

## STEP 1 — Verify state

```bash
cd "$WORKDIR" && ./scripts/lint.sh
```

Expected: `🟢  All gate checks passed.`

If not, debug and re-run the failing step. Do not proceed past this point if build is broken.

## STEP 2 — Register bundle IDs (one-time)

Two options. **Try Option B (fastlane) first.**

### Option B (preferred)

```bash
cd "$WORKDIR"
fastlane spaceauth
# → Walks through Apple ID signin + 2FA prompt
fastlane ios register
fastlane mac register
```

If `fastlane ios register` reports the bundle already exists, **that's fine** — fastlane idempotent. Move on to Step 3.

### Option A (fallback, Xcode UI)

```
1. open $WORKDIR/Quill.xcodeproj
2. Wait for Xcode to finish indexing.
3. Set the Scheme dropdown to "Quill":
   • Click target "Quill" in the sidebar.
   • Open "Signing & Capabilities" tab.
   • Tick "Automatically manage signing".
   • Team dropdown: ENRIQUE VALEROS MURIANA (KADHS6P8PY).
   • Click Enable on the "Register bundle — Enable" popup.
4. Set the Scheme dropdown to "QuillMac":
   • Repeat steps 3a–3e on target "QuillMac".
5. Confirm both targets show a non-empty provisioning profile.
6. Close Xcode.
```

After either option, verify profiles exist locally:

```bash
ls -lh ~/Library/MobileDevice/Provisioning\ Profiles/*.mobileprovision | tail -5
find ~/Library/MobileDevice/Provisioning\ Profiles -mtime -1h
```

## STEP 3 — Capture App Store screenshots

```bash
cd "$WORKDIR"
./scripts/screenshot.sh       # iOS via fastlane snapshot
ls build/screenshots/         # confirm PNGs landed
# (For macOS run ./scripts/mac-screenshot.sh too.)
```

If snapshot can't drive the UI tests (no `SnapshotTests` yet), the script accepts whatever lands and the manual screenshots you took (in `~/quill-ios/build/screenshots/`) will do.

## STEP 4 — Archive + Upload (both targets)

```bash
cd "$WORKDIR"

# iOS first — Apple ID + 2FA prompt once.
./scripts/submit.sh ./build/Quill.ipa
# OR:
fastlane ios ship

# macOS next — same Apple ID + 2FA.
./scripts/mac-submit.sh ./build/mac/QuillMac.pkg
# OR:
fastlane mac ship
```

`fastlane ios ship` chains: `test → archive → screenshots → upload`.
`fastlane mac ship` chains the same for macOS.

If signing fails with "no profiles found":

```bash
# Verify the bundle ID is registered + team matches:
xcodebuild -project Quill.xcodeproj -showBuildSettings | grep DEVELOPMENT_TEAM
# Should print KADHS6P8PY. Re-run Step 2 if not.

# Or retry with -allowProvisioningUpdates:
xcodebuild ... archive -allowProvisioningUpdates
```

If archive fails with `ALSDataContractCorrupt` or similar Core Foundation issue, `xcrun simctl erase all` and re-build.

## STEP 5 — Verify in App Store Connect (USER TOUCH)

Ask the user to open https://appstoreconnect.apple.com → **Quill**.

Walk through with them (don't auto-navigate):

- [ ] App icon preview chip renders.
- [ ] Screenshots per device + locale appear in the carousel (en-US has the most).
- [ ] Description renders cleanly across `en-US`, `es-ES`, `fr-FR`, `de-DE`, `it-IT`, `pt-BR`.
- [ ] Age rating questionnaire: **4+**, no objectionable content.
- [ ] Pricing: Free (or whatever).
- [ ] Availability: All territories or user-selected.
- [ ] Encryption: **"Uses Non-Exempt Encryption: NO"** — already in Info.plist.
- [ ] Privacy questions answered (no tracking — `PrivacyInfo.xcprivacy` declares only reason APIs).

User clicks **"Submit for Review"** on both listings (iOS + macOS).

After Apple's app review window (24–48 h for first submission, faster for updates), each version moves to `READY_FOR_SALE`.

## GUARDRAILS

- **Never** click Submit for Review — that's the user's call at the end of Step 5.
- **Never** modify `project.yml`, source Swift files, or `metadata/<locale>/` unless a build or deliver step explicitly requires it.
- **Always** surface the full error message if any step fails, plus the next command to try.
- **Always** ask before doing any web fetch, repo push, or destructive shell action.
- After Step 4 succeeds on both platforms, do not modify code — proceed straight to verification.

## REPORT BACK

Print a single block at the end:

```
✅ Step 1  lint gate
✅ Step 2  bundle IDs registered        (or: provisioning profile present, <name>)
✅ Step 3  iOS screenshots saved → ./build/screenshots/<device>/<locale>/*.png (count files)
✅ Step 3  macOS screenshots saved → ./build/screenshots/mac/<locale>/*.png (count files)
✅ Step 4  iOS uploaded to App Store Connect — version 1.0 build 1 status: <Received / Invalid>
✅ Step 4  macOS uploaded to App Store Connect — version 1.0 build 1 status: <Received / Invalid>
⏸  Step 5  paused for user verification in App Store Connect

If anything failed, list the failing command + the most likely fix.
```

## START

Begin with Step 1 (lint). Report the status before moving on.
