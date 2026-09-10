import Foundation

/// Lightweight HTML metadata fetcher. Pulls `<title>`, `<meta property="og:...">`
/// tags, and a clean site name. Designed to be tolerant — anything that fails
/// returns nil and lets the caller fall back to the URL host as the title.
public actor URLMetadataFetcher {
    public static let shared = URLMetadataFetcher()
    private let session: URLSession
    private let cache = NSCache<NSString, CachedMetadata>()

    public final class CachedMetadata: NSObject {
        public let title: String
        public let summary: String
        public let imageURL: String?
        public let siteName: String

        public init(title: String, summary: String, imageURL: String?, siteName: String) {
            self.title = title
            self.summary = summary
            self.imageURL = imageURL
            self.siteName = siteName
        }
    }

    public init(session: URLSession = .shared) {
        self.session = session
        cache.countLimit = 256
    }

    public func fetch(urlString: String) async -> CachedMetadata? {
        let key = NSString(string: urlString)
        if let cached = cache.object(forKey: key) {
            return cached
        }
        guard let url = URL(string: urlString), url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 6)
        request.setValue("QuillBot/1.0", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html", forHTTPHeaderField: "Accept")

        do {
            let (data, response) = try await session.data(for: request)
            guard let html = Self.decodeHTML(data: data) else { return nil }
            guard let http = response as? HTTPURLResponse, (200..<400).contains(http.statusCode) else {
                return nil
            }
            let meta = Self.parse(html: html, fallbackHost: url.host ?? "")
            cache.setObject(meta, forKey: key)
            return meta
        } catch {
            QLLog.app.error("URL fetch failed: \(error.localizedDescription)")
            return nil
        }
    }

    public static func parse(html: String, fallbackHost: String) -> CachedMetadata {
        let title = extractTitle(html: html) ?? fallbackHost
        let summary = extractContent(html: html, attr: "name", key: "description")
                          ?? extractContent(html: html, attr: "property", key: "og:description")
                          ?? ""
        let imageURL = extractContent(html: html, attr: "property", key: "og:image")
        let siteName = extractContent(html: html, attr: "property", key: "og:site_name")
                       ?? fallbackHost
        return CachedMetadata(title: title, summary: summary, imageURL: imageURL, siteName: siteName)
    }

    // MARK: - Helpers

    private static func extractTitle(html: String) -> String? {
        // Pulls `<title>...</title>` first.
        if let t = firstMatch(in: html, pattern: "<title[\\s>]([\\s\\S]*?)</title>", group: 1) {
            return decode(t).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Falls back to og:title.
        if let t = extractContent(html: html, attr: "property", key: "og:title") {
            return t
        }
        return nil
    }

    /// Tries UTF-8 first, falls back to ISO-Latin-1 if that fails — guarantees
    /// we read whatever encoding the server sends, including binary-tagged pages.
    private static func decodeHTML(data: Data) -> String? {
        if let utf8 = String(data: data, encoding: .utf8) { return utf8 }
        if let latin1 = String(data: data, encoding: .isoLatin1) { return latin1 }
        return String(data: data, encoding: .ascii)
    }

    private static func extractContent(html: String, attr: String, key: String) -> String? {
        // `<meta property="og:title" content="..." />` etc.
        let escapedAttr = NSRegularExpression.escapedPattern(for: attr)
        let escapedKey  = NSRegularExpression.escapedPattern(for: key)
        let pattern = "<meta\\s+(?:[^>]*\\s+)?\(escapedAttr)\\s*=\\s*[\"']\(escapedKey)[\"'][^>]*content\\s*=\\s*[\"']([^\"']*)[\"']"
        if let m = firstMatch(in: html, pattern: pattern, group: 1) {
            return decode(m)
        }
        // Order-sensitive fallback: attr after key.
        let pattern2 = "<meta\\s+(?:[^>]*\\s+)?content\\s*=\\s*[\"']([^\"']*)[\"'][^>]*\(escapedAttr)\\s*=\\s*[\"']\(escapedKey)[\"']"
        if let m = firstMatch(in: html, pattern: pattern2, group: 1) {
            return decode(m)
        }
        return nil
    }

    private static func decode(_ s: String) -> String {
        var out = s
        out = out.replacingOccurrences(of: "&amp;",  with: "&")
        out = out.replacingOccurrences(of: "&lt;",   with: "<")
        out = out.replacingOccurrences(of: "&gt;",   with: ">")
        out = out.replacingOccurrences(of: "&quot;", with: "\"")
        out = out.replacingOccurrences(of: "&#39;",  with: "'")
        out = out.replacingOccurrences(of: "&apos;", with: "'")
        out = out.replacingOccurrences(of: "&nbsp;", with: " ")
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func firstMatch(in text: String, pattern: String, group: Int) -> String? {
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else { return nil }
        let nsRange = NSRange(text.startIndex..., in: text)
        guard let match = re.firstMatch(in: text, range: nsRange),
              group < match.numberOfRanges,
              let r = Range(match.range(at: group), in: text) else { return nil }
        return String(text[r])
    }
}
