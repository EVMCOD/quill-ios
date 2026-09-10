# Quill changelog

All notable changes to **Quill**. Dates are Europe/Madrid (UTC+1/+2).

## v1.0.0 — 2026-09-10

Initial release. Ready for App Store Connect submission via the Fastlane lanes in `fastlane/Fastfile`.

### Added
- iOS app (`app.quill.ios`, iOS 17+, iPhone + iPad), macOS app (`app.quill.macos`, macOS 14+).
- Universal SwiftUI shell — tabs on iPhone, NavigationSplitView on macOS, gating onboarding flow.
- Three top-level views — **Inbox** (queue), **Library** (saved + read), **Highlights** (all captured passages).
- **Quick Capture** sheet with auto-fetched metadata (HTML `<title>` + og: tags + summary) via `URLMetadataFetcher` actor.
- **Reader** view — per-article hero + highlights + capture form with one-line notes.
- **Reading streak** counter — gamified without nagging.
- **macOS Menu Bar Extra** — quick URL capture + live inbox list (tap to toggle done), `⌘N` Add Article + `⌘,` Settings menu bar commands.
- **Obsidian sync** — pick your vault via security-scoped bookmark in Keychain. One markdown file per article under `quill/articles/`, with YAML frontmatter and `> ` quote blocks for highlights. Daily `quill/index.md` queue.
- **AppIntents** — `AddArticleIntent` for Siri / Shortcuts / share sheet stub.
- 6 locales × 7 strings in `Localizable.xcstrings`: en-US, es-ES, fr-FR, de-DE, it-IT, pt-BR.
- `TK`-style design system (`QL` namespace) — palette (navy + rose-mauve accent), serif typography for article titles and highlight text, SF Rounded for UI.
- `PrivacyInfo.xcprivacy` with disk space + UserDefaults + file timestamp reason codes.
- Fastlane skeleton (`fastlane/Fastfile`) — `test / archive / screenshots / upload / ship / register` lanes for both iOS and macOS.
- `App Store Connect` metadata in 6 locales pre-written at `metadata/<locale>/` — name, subtitle, keywords, description, release_notes.
- Submission scripts at `scripts/` — `archive.sh`, `submit.sh`, `screenshot.sh`, `mac-archive.sh`, `mac-screenshot.sh`, `mac-submit.sh`, `lint.sh`.
- `SUBMIT.md` — 1-page submission playbook.
- Standalone AppKit icon generator at `scripts/render-icon.swift` producing a 1024×1024 Reminders-style icon with a feather accent.

### Status
- Build: `BUILD SUCCEEDED`, errors 0, warnings 0 (both iOS and macOS).
- Lint gate: 5/5 green (xcodegen + iOS + macOS + privacy plist + xcstrings).
- Same architectural pattern as Tack (EVMCOD/tack-ios) — pair via App Group.

### Known limitations
- macOS widget (Notification Center) deferred to v1.1.
- iOS Share Extension deferred to v1.1 (URLMetadataFetcher + `AddArticleIntent` are wired but the extension target is missing).
- iCloud sync toggle deferred to v1.1 (Quick Capture sheet has the chips but the ModelContainer uses local storage).
- Live file-watching inside the vault on macOS beyond `DispatchSource.makeFileSystemObjectSource` is a v1.1 nicety.
- Auto-fetched metadata on first capture is async but the user is shown the URL host until `og:title` returns.
- Reading streak is currently `days in a row with at least one read` — does not track per-list filtering, nor does it include Highlights counts.
