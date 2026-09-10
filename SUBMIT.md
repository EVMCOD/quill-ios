# SUBMIT · Quill v1.0 → App Store

This is the one-page playbook for shipping **Quill**. Run through it once and you're done.

---

## ⏱ Time to ship

| Scenario | ETA |
|---|---|
| Compiled and shipped | ~15 min of your time + Apple review queue |
| Polished: TestFlight round + screenshots + ASO polish | ~3 hours |

---

## Pre-flight (you, ~10 minutes)

```bash
cd ~/quill-ios
./scripts/lint.sh        # 5/5 gates green
```

Checklist:
- [ ] `bundle ID app.quill.ios` registered in Apple Developer
- [ ] `bundle ID app.quill.macos` registered in Apple Developer
- [ ] App Group `group.app.quill.shared` registered for both bundles
- [ ] Distribution certificate in your Keychain
- [ ] Provisioning profile: *iOS App Store* for `app.quill.ios`
- [ ] Provisioning profile: *Mac App Store* for `app.quill.macos`
- [ ] (Optional) App-Specific password for Apple ID (appleid.apple.com)
- [ ] `~/games-clawstud/public/quill/{privacy,support}/` already deployed (mirror of Tack's)

Quill ships with **one integration** (Obsidian only). No OAuth setup is required to ship — the vault picker is opt-in from the user.

---

## Day 1 · Build + screenshots + archive

### 1) Install tooling

```bash
brew install xcodegen fastlane
```

### 2) Capture screenshots

```bash
./scripts/screenshot.sh
# → ./build/screenshots/<device>/<locale>/*.png
```

### 3) Lint green

```bash
./scripts/lint.sh
# 🟢  All 5 gate checks passed.
```

### 4) Archive for App Store

```bash
./scripts/archive.sh      # → ./build/Quill.ipa + ./build/QuillMac.pkg
```

If `exportOptions.plist` doesn't exist yet:

```bash
cat > build/exportOptions.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key><string>app-store</string>
    <key>teamID</key><string>KADHS6P8PY</string>
    <key>uploadSymbols</key><false/>
</dict>
</plist>
EOF
```

---

## Day 1/2 · Upload metadata + binary

### 5) Sign in to Fastlane Spaceship (one-time)

```bash
fastlane spaceauth
# OR via env
export APPLE_ID_FOR_TACK=valerosenrique@gmail.com   # or App-Specific password below
export FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD=***  # appleid.apple.com>
```

### 6) Upload (no submit-for-review yet)

```bash
./scripts/submit.sh ./build/Quill.ipa
# OR
fastlane ios upload
# feeds ./metadata/<locale>/ to App Store Connect + uploads the binary + screenshots
# does NOT click Submit for Review
```

### 7) Verify on App Store Connect

[App Store Connect → Quill](https://appstoreconnect.apple.com)

Walk through every tab (Versions, App Store, Pricing). Confirm:
- App icon preview chip renders
- Screenshots per device + locale appear in the carousel
- Description renders cleanly (en, es, fr, de, it, pt-BR)
- Age rating: **4+**, no objectionable content
- Pricing: Free (or whatever)
- Encryption: "Uses Non-Exempt Encryption: NO" (already in Info.plist)
- Pricing / Availability set
- Privacy questions answered (no tracking — `PrivacyInfo.xcprivacy` declares only reason APIs)

### 8) Ship it

```bash
fastlane ios upload --submit_for_review true
# OR click Submit for Review in App Store Connect.
```

Apple's first review for new apps typically lands in 24–48 hours.

---

## One-time per Apple Developer account

If `app.quill.ios` doesn't yet exist:

```bash
fastlane ios register
fastlane mac register
```

This creates both bundle IDs + App Group. Run once.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `git push` rejected | `.gitignore` excludes build/. Don't commit `Quill.xcodeproj`. |
| `xcodebuild` says `code signing failed` | Re-attach provisioning profile in Xcode → Signing & Capabilities → click Profile. |
| `fastlane ios upload` says "You have no team" | `fastlane spaceauth` to re-auth. |
| App rejected on Guideline 5.1.1 (Privacy) | `PrivacyInfo.xcprivacy` covers declared reason APIs. If they ask for a privacy FAQ URL, point to the public site. |
| App rejected on Guideline 2.1 (crash on launch) | Crash logs in App Store Connect. Likely a SwiftData migration issue — increment schema or wipe store. |
| App Store Connect: "Missing Compliance" | Answer "No" for Tracking / Encryption. Save. |
| Fetched metadata is empty | Run `./scripts/screenshot.sh` first to populate `build/screenshots/`. |

---

## After approval

Once Apple notifies you the app is `READY_FOR_SALE`:

1. Release the version (Manual or Auto)
2. Promote build from TestFlight to production
3. Tag `git tag v1.0.0-prod` on the commit that shipped
4. Update `~/Documents/Obsidian/OC/projects/quill.md` with `READY_FOR_SALE` + ASC submission ID

---

## Reference

- `scripts/archive.sh` — wrapper around xcodebuild archive + exportOptions
- `scripts/submit.sh` — wrapper around `fastlane ios upload`
- `scripts/screenshot.sh` — wrapper around `fastlane ios screenshots`
- `scripts/mac-archive.sh` / `mac-submit.sh` — macOS twin
- `scripts/lint.sh` — gate check (5 checks)
- `fastlane/Fastfile` — `register / test / archive / screenshots / upload / ship` lanes (iOS + macOS)
- `metadata/<locale>/` — App Store Connect copy in 6 languages
- `Tack/PrivacyInfo.xcprivacy` — required as of Xcode 15
- `~/Documents/Obsidian/OC/projects/quill.md` — daily tracker (TBD)
