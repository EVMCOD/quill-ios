import Foundation

/// Serializes `Article` and `Highlight` into the Markdown syntax
/// compatible with Obsidian's reading-mode: YAML frontmatter + Wikilinks +
/// Highlights as `> quote` blocks. Each article becomes one file in the
/// vault at `quill/articles/<slug>.md`; the queue lives at `quill/index.md`.
public enum MarkdownSerializer {

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let displayDate: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    public static func article(_ article: Article) -> String {
        var out = "---\n"
        out += "id: \(article.id.uuidString)\n"
        out += "title: \(yamlEscape(article.title))\n"
        out += "url: \(article.url)\n"
        if !article.siteName.isEmpty {
            out += "site: \(yamlEscape(article.siteName))\n"
        }
        if !article.summary.isEmpty {
            out += "summary: \(yamlEscape(article.summary))\n"
        }
        out += "status: \(article.status.rawValue)\n"
        out += "created: \(isoFormatter.string(from: article.createdAt))\n"
        if let readAt = article.readAt {
            out += "read: \(isoFormatter.string(from: readAt))\n"
        }
        if !article.tags.isEmpty {
            let names = article.tags.map { "#" + $0.name }.joined(separator: ", ")
            out += "tags: [\(names)]\n"
        }
        if let folder = article.folder, folder.name != Folder.inbox {
            out += "folder: \(yamlEscape(folder.name))\n"
        }
        out += "source: quill\n"
        out += "tackID: \(article.id.uuidString)\n"
        out += "---\n\n"
        out += "# \(article.title)\n\n"
        if !article.siteName.isEmpty {
            out += "[\(article.siteName)](\(article.url))\n\n"
        } else {
            out += "🔗 \(article.url)\n\n"
        }
        out += "> Cached on \(displayDate.string(from: article.createdAt))\n\n"
        if !article.summary.isEmpty {
            out += "> \(article.summary)\n\n"
        }
        if !article.highlights.isEmpty {
            out += "## Highlights\n\n"
            for h in article.highlights.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                out += "> \(h.text)\n"
                if !h.note.isEmpty {
                    out += ">\n"
                    out += "> — \(h.note)\n"
                }
                out += "\n"
            }
        }
        return out
    }

    public static func filename(for article: Article) -> String {
        let safe = article.title
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        let prefix = safe.isEmpty ? "article" : String(safe.prefix(48))
        return "\(prefix)-\(article.id.uuidString.prefix(8)).md"
    }

    public static func queueIndex(_ articles: [Article]) -> String {
        var out = "---\n"
        out += "type: quill-index\n"
        out += "updated: \(isoFormatter.string(from: .now))\n"
        out += "---\n\n"
        out += "# Reading Queue\n\n"
        if articles.isEmpty {
            out += "_Empty._ Capture an article to start.\n"
        } else {
            out += "\(articles.count) saved\n\n"
            for article in articles.sorted(by: { $0.createdAt > $1.createdAt }) {
                out += "- [\(article.title)](\(article.url)) — \(article.siteName.isEmpty ? "link" : article.siteName)\n"
            }
        }
        return out
    }

    private static func yamlEscape(_ s: String) -> String {
        if s.contains(":") || s.contains("#") || s.contains("\"") || s.contains("\n") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\\\"") + "\""
        }
        return s
    }
}
