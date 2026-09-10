# Quill · Fastlane

Automation for building, screenshotting, and uploading **Quill** to App Store Connect.

## Setup (one-time)

```bash
brew install fastlane
cd ~/quill-ios
```

Sign in once:
```bash
fastlane spaceauth
# OR set env
export APPLE_ID_FOR_QUILL=valerosenrique@gmail.com
export QUILL_ITC_TEAM_ID=<your App Store Connect Team ID>
```

If 2FA on your Apple Developer account, use an App-Specific password via
`FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`.

## Lanes

| Lane | What it does | When to run |
|---|---|---|
| `fastlane ios test` | Run UI tests via `scan` | After schema changes |
| `fastlane ios archive` | Build signed `Quill.ipa` | Before upload |
| `fastlane ios screenshots` | Capture screenshots per device + locale | Before release |
| `fastlane ios upload` | Upload metadata + binary to App Store Connect | Before submit |
| `fastlane ios ship` | Chain: test → archive → screenshots → upload | End-to-end |
| `fastlane ios register` | Create bundle ID + App Group | First time |
| `fastlane mac …` | macOS twins for `app.quill.macos` | macOS path |

## Metadata

App Store Connect content lives in `../metadata/<locale>/`:
- `name.txt` (50 chars)
- `subtitle.txt` (30 chars)
- `keywords.txt` (100 chars)
- `description.txt` (4000 chars)
- `release_notes.txt` (4000 chars)

Locales mirror `Localizable.xcstrings`: en-US, es-ES, fr-FR, de-DE, it-IT, pt-BR.

## Privacy manifest

`../Tack/PrivacyInfo.xcprivacy` — declares only `disk space / UserDefaults / file timestamp` reason APIs. No tracking, no collected data types.

## Reference

- `SUBMIT.md` — full submission playbook
- `scripts/lint.sh` — 5 gate checks (must pass before any commit)
- `metadata/<locale>/` — App Store Connect copy in 6 languages
