# Quill

> A focused, adaptive read-later app for iPhone, iPad, and Mac. **Obsidian native**. Capture, highlight, sync.

## What is it?

A native read-later and highlights app. Quill lives at the seam between "I want to read this later" and "I want to keep this passage forever."

- **Capture fast** — paste a URL, share from Safari via Share Extension, or click from the macOS menu bar.
- **Read. Highlight. Capture.** — auto-fetched title + summary, full reader view, in-app highlights.
- **Sync with Obsidian** — each article becomes one markdown file under `quill/articles/`, with YAML frontmatter, original quotes as `> ` blocks, and a daily `quill/index.md` of your queue.
- **Reading streak** — gamified (light): "days in a row you've read at least one article."

## Stack

- SwiftUI (iOS 17.0+, iPadOS 17.0+, macOS 14.0+)
- SwiftData + App Group storage
- Menu-bar item on macOS for quick URL capture
- AppIntents (Save Article from Siri / Shortcuts / share extension)
- xcodegen, Fastlane
- 6 locales: en, es, fr, de, it, pt-BR

## Features

### Core
- Inbox (raw captures), Library (saved and read), Highlights (all)
- Quick Capture sheet with **auto-fetched title + summary**
- Tag articles (`#ai #design`)
- Lightweight reader view with metadata + URL
- Per-article highlights: capture a passage + an optional note
- Reading streak counter
- Light / Dark / system theme picker

### macOS
- Native menubar item with quick URL capture (no focus loss from current app)
- Article list synced in real time across Mac + iPhone via App Group
- App Sandbox + App Group + user-selected files scopes

### Sync (Obsidian)
- Vault folder picker (security-scoped bookmark in Keychain)
- One markdown file per article: `quill/articles/<slug>-<id8>.md`
- `quill/index.md` queue, sorted by created date
- YAML frontmatter per article (`title`, `url`, `site`, `summary`, `status`, `created`, `read`, `tags`, `folder`, `source`, `tackID`)
- Highlights as `> quoted` blocks with optional `— note` line

### AppIntents
- `AddArticleIntent` (Save Article) — Siri / Shortcuts / share extension
  Voice: "Save article to Quill with URL https://..."

## Quick start

```bash
cd ~/quill-ios
./scripts/bootstrap.sh
open Quill.xcodeproj
```

CLI:
```bash
./scripts/build.sh
```

## Build status

```
$ ./scripts/lint.sh
🟢 All gate checks passed.
Errors: 0
Warnings: 0
Files: <TBD> Swift + project.yml + xcprivacy + xcstrings + plists
```

## Roadmap

- [x] v1.0 — Inbox/Library/Highlights/Reader + Obsidian sync
- [ ] v1.1 — iOS Share Extension (capture URL from any app)
- [ ] v1.1 — macOS Notification Center widget (queue count)
- [ ] v1.2 — CloudKit sync (private DB)
- [ ] v2.0 — Reader mode (in-app article extraction, Readability-style)
- [ ] v2.0 — Watch app + complication

## License

Private. © 2026.
