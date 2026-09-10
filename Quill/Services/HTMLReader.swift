import Foundation

/// Lightweight HTML reader (loosely Mozilla Readability-inspired).
/// Strips scripts, styles, nav, header, footer, aside, form, comments.
/// Picks the largest text container by `<p>` count, then `<p>` density.
/// Returns a `ReaderArticle` ready for the SwiftUI reader view.
public struct ReaderArticle: Sendable {
    public let title: String
    public let byline: String?
    public let siteName: String?
    public let imageURL: String?
    public let estimatedReadingMinutes: Int
    public let blocks: [Block]

    public enum Block: Sendable {
        case heading(String, level: Int)
        case paragraph(String)
        case quote(String)
        case image(String, alt: String)
        case list([String], ordered: Bool)
    }
}

public actor HTMLReader {
    public static let shared = HTMLReader()
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func read(urlString: String) async -> ReaderArticle? {
        guard let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        do {
            var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10)
            request.setValue("Quill/1.0 (+quill-app)", forHTTPHeaderField: "User-Agent")
            request.setValue("text/html,application/xhtml+xml", forHTTPHeaderField: "Accept")
            let (data, _) = try await session.data(for: request)
            guard let html = decode(data: data) else { return nil }
            return parse(html: html, fallbackURL: url)
        } catch {
            return nil
        }
    }

    public func parse(html: String, fallbackURL: URL) -> ReaderArticle {
        let title = extractTitle(html: html) ?? fallbackURL.host ?? fallbackURL.absoluteString
        let siteName = extractMeta(html: html, property: "og:site_name")
                       ?? extractMeta(html: html, property: "application-name")
                       ?? fallbackURL.host
        let byline  = extractMeta(html: html, property: "article:author")
                       ?? extractMeta(html: html, property: "author")
        let imageURL = extractMeta(html: html, property: "og:image")
                        ?? extractFirstImgSrc(html: html)

        let scrubbed = scrub(html: html)
        let container = pickContainer(html: scrubbed) ?? scrubbed
        let blocks = blocksFromContainer(container)

        let wordCount = blocks
            .map { Self.wordCount(of: $0) }
            .reduce(0, +)
        let minutes = max(1, Int((Double(wordCount) / 220.0).rounded()))

        return ReaderArticle(
            title: title,
            byline: byline,
            siteName: siteName,
            imageURL: imageURL,
            estimatedReadingMinutes: minutes,
            blocks: blocks
        )
    }

    // MARK: - Scrubbing

    private func scrub(html: String) -> String {
        var out = html
        let drop: [(String, NSRegularExpression.Options)] = [
            ("<script[\\s\\S]*?</script>", [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<style[\\s\\S]*?</style>",  [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<noscript[\\s\\S]*?</noscript>", [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<nav[\\s\\S]*?</nav>",       [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<header[\\s\\S]*?</header>", [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<footer[\\s\\S]*?</footer>", [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<aside[\\s\\S]*?</aside>",   [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<form[\\s\\S]*?</form>",     [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<!--[\\s\\S]*?-->",          [.dotMatchesLineSeparators]),
            ("<script[\\s\\S]*?</script>", [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<svg[\\s\\S]*?</svg>",     [.caseInsensitive, .dotMatchesLineSeparators]),
            ("<aside[\\s\\S]*?</aside>",   [.caseInsensitive, .dotMatchesLineSeparators]),
        ]
        for (pattern, options) in drop {
            if let re = try? NSRegularExpression(pattern: pattern, options: options) {
                out = re.stringByReplacingMatches(
                    in: out,
                    range: NSRange(out.startIndex..., in: out),
                    withTemplate: ""
                )
            }
        }
        return out
    }

    // MARK: - Container selection

    private func pickContainer(html: String) -> String? {
        // First try semantic tags.
        if let r = firstMatch(in: html, pattern: #"(?is)<article[^>]*>(.*?)</article>"#, group: 1) {
            return stripTags(of: r, keepBreaks: true)
        }
        if let r = firstMatch(in: html, pattern: #"(?is)<main[^>]*>(.*?)</main>"#, group: 1) {
            return stripTags(of: r, keepBreaks: true)
        }
        // Fallback: pick the div with the most <p> paragraphs.
        let candidates = matches(in: html, pattern: #"(?is)<div[^>]*>(.*?)</div>"#)
        var best: (text: String, count: Int)?
        for c in candidates {
            let count = countMatches(in: c, pattern: #"(?is)<p[\\s\\S]*?>"#)
            if best == nil || count > (best?.count ?? 0) {
                best = (stripTags(of: c, keepBreaks: true), count)
            }
        }
        return best?.text
    }

    private func matches(in text: String, pattern: String) -> [String] {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return [] }
        let nsRange = NSRange(text.startIndex..., in: text)
        return re.matches(in: text, range: nsRange).compactMap { m in
            guard m.numberOfRanges > 1, let r = Range(m.range(at: 1), in: text) else { return nil }
            return String(text[r])
        }
    }

    private func countMatches(in text: String, pattern: String) -> Int {
        guard let re = try? NSRegularExpression(pattern: pattern) else { return 0 }
        return re.numberOfMatches(in: text, range: NSRange(text.startIndex..., in: text))
    }

    // MARK: - Block extraction

    private func blocksFromContainer(_ html: String) -> [ReaderArticle.Block] {
        var blocks: [ReaderArticle.Block] = []

        // Headings
        let headingPattern = #"(?is)<h([1-6])[^>]*>(.*?)</h\1>"#
        for h in matches(in: html, pattern: headingPattern) {
            let levelStr = firstMatch(in: h, pattern: #"(?is)<h([1-6])[^>]*>"#, group: 1) ?? "2"
            let level = Int(levelStr) ?? 2
            let text = stripTags(of: h, keepBreaks: false)
            if !text.isEmpty { blocks.append(.heading(text, level: level)) }
        }

        // Paragraphs
        let pPattern = #"(?is)<p[^>]*>(.*?)</p>"#
        for p in matches(in: html, pattern: pPattern) {
            let text = stripTags(of: p, keepBreaks: false)
            if text.count > 25 { blocks.append(.paragraph(text)) }
        }

        // Blockquotes
        let bqPattern = #"(?is)<blockquote[^>]*>(.*?)</blockquote>"#
        for bq in matches(in: html, pattern: bqPattern) {
            let text = stripTags(of: bq, keepBreaks: true)
            if !text.isEmpty { blocks.append(.quote(text)) }
        }

        // Lists
        for listMatch in matches(in: html, pattern: #"(?is)<(ol|ul)[^>]*>(.*?)</\1>"#) {
            let ordered = listMatch.hasPrefix("<ol")
            let liPattern = #"(?is)<li[^>]*>(.*?)</li>"#
            var items: [String] = []
            for li in matches(in: listMatch, pattern: liPattern) {
                let t = stripTags(of: li, keepBreaks: false)
                if !t.isEmpty { items.append(t) }
            }
            if !items.isEmpty { blocks.append(.list(items, ordered: ordered)) }
        }

        // Images (only inside the article body, exclude icons / sprites)
        let imgPattern = #"(?is)<img[^>]+src=[\"']([^\"']+)[\"'][^>]*>"#
        for src in matches(in: html, pattern: imgPattern) {
            if src.contains(".svg") { continue }
            if src.contains("icon") || src.contains("logo") { continue }
            let alt = firstMatch(in: html, pattern: #"(?is)<img[^>]*alt=[\"']([^\"']*)[\"'][^>]*src=[\"']\#(NSRegularExpression.escapedPattern(for: src))[\"']"#, group: 1) ?? ""
            blocks.append(.image(src, alt: alt))
        }

        return blocks
    }

    // MARK: - Tag stripping

    private func stripTags(of html: String, keepBreaks: Bool) -> String {
        var text = html
        // Convert block-level tags to separators
        let blockTags = ["p", "div", "section", "article", "blockquote", "li", "br", "h1", "h2", "h3", "h4", "h5", "h6"]
        for tag in blockTags {
            let pattern = "(?is)<\\/?\(tag)\\s*/?>"
            if let re = try? NSRegularExpression(pattern: pattern) {
                text = re.stringByReplacingMatches(
                    in: text,
                    range: NSRange(text.startIndex..., in: text),
                    withTemplate: keepBreaks ? "\n\n" : " "
                )
            }
        }
        // Strip all remaining tags
        if let re = try? NSRegularExpression(pattern: "(?is)<[^>]+>") {
            text = re.stringByReplacingMatches(
                in: text,
                range: NSRange(text.startIndex..., in: text),
                withTemplate: ""
            )
        }
        // Decode entities
        text = decode(html: text)
        // Collapse whitespace
        if !keepBreaks {
            text = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        } else {
            text = text.replacingOccurrences(of: #"\n\s*\n+"#, with: "\n\n", options: .regularExpression)
            text = text.replacingOccurrences(of: #"[ \t]+"#, with: " ", options: .regularExpression)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }

    private func decode(html: String) -> String {
        var t = html
        let map: [(String, String)] = [
            ("&amp;", "&"), ("&lt;", "<"), ("&gt;", ">"),
            ("&quot;", "\""), ("&#39;", "'"), ("&apos;", "'"),
            ("&nbsp;", " "), ("&ndash;", "–"), ("&mdash;", "—"),
            ("&hellip;", "…"), ("&ldquo;", "\u{201C}"), ("&rdquo;", "\u{201D}"),
            ("&lsquo;", "\u{2018}"), ("&rsquo;", "\u{2019}")
        ]
        for (entity, ch) in map {
            t = t.replacingOccurrences(of: entity, with: ch, options: .caseInsensitive)
        }
        return t
    }

    private func decode(data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        if let latin1 = String(data: data, encoding: .isoLatin1) { return latin1 }
        return String(data: data, encoding: .ascii)
    }

    // MARK: - Metadata helpers

    private func extractTitle(html: String) -> String? {
        if let t = firstMatch(in: html, pattern: #"(?is)<title[^>]*>(.*?)</title>"#, group: 1) {
            return decode(html: stripTags(of: t, keepBreaks: false)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let t = extractMeta(html: html, property: "og:title") {
            return t
        }
        return nil
    }

    private func extractMeta(html: String, property: String) -> String? {
        let esc = NSRegularExpression.escapedPattern(for: property)
        let patterns = [
            "<meta\\s+property=[\"']\(esc)[\"']\\s+content=[\"']([^\"']*)[\"']",
            "<meta\\s+content=[\"']([^\"']*)[\"']\\s+property=[\"']\(esc)[\"']",
            "<meta\\s+name=[\"']\(esc)[\"']\\s+content=[\"']([^\"']*)[\"']",
            "<meta\\s+content=[\"']([^\"']*)[\"']\\s+name=[\"']\(esc)[\"']"
        ]
        for p in patterns {
            if let v = firstMatch(in: html, pattern: p, group: 1) {
                return decode(html: v)
            }
        }
        return nil
    }

    private func extractFirstImgSrc(html: String) -> String? {
        let pattern = "(?is)<img[^>]+src=[\"']([^\"']+)[\"']"
        guard let url = firstMatch(in: html, pattern: pattern, group: 1) else { return nil }
        if url.contains(".svg") || url.contains("icon") || url.contains("logo") { return nil }
        return url
    }

    // MARK: - Generic helpers

    private func firstMatch(in text: String, pattern: String, group: Int) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let m = re.firstMatch(in: text, range: nsRange),
              group < m.numberOfRanges,
              let r = Range(m.range(at: group), in: text) else { return nil }
        return String(text[r])
    }

    private static func wordCount(of block: ReaderArticle.Block) -> Int {
        let text: String
        switch block {
        case .heading(let s, _):    text = s
        case .paragraph(let s):     text = s
        case .quote(let s):         text = s
        case .image:                text = ""
        case .list(let items, _):   text = items.joined(separator: " ")
        }
        return text.split { $0.isWhitespace || $0.isNewline }.count
    }
}
