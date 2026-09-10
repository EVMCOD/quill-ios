import Foundation
import SwiftData

/// Bidirectional sync between Quill and an Obsidian vault.
///
/// File layout (created lazily):
///   quill/
///     index.md              ← global reading queue
///     articles/
///       <slug>-<uuid8>.md   ← one file per article with highlights
///       ...
///
/// Refresh strategy mirrors Tack's: a scan on launch + background work
/// after every change. Manual "Sync now" triggers a full pass.
@MainActor
public final class ObsidianSyncService {
    public static let shared = ObsidianSyncService()
    private let vault = ObsidianVault.shared

    public var isConfigured: Bool { vault.url != nil }

    public func pickVault(_ url: URL) throws {
        try vault.setVault(url)
        QLLog.obsidian.info("Vault set: \(url.lastPathComponent)")
    }

    public func clear() {
        vault.clear()
    }

    /// One full pass: write every article to disk, rebuild the queue index.
    public func sync(container: ModelContainer) {
        guard isConfigured else { return }
        let ctx = container.mainContext

        // 1. Write every article.
        let all = (try? ctx.fetch(FetchDescriptor<Article>())) ?? []
        for article in all {
            do {
                try writeArticle(article)
                article.lastSyncedAt = .now
            } catch {
                QLLog.obsidian.error("Article sync failed: \(error.localizedDescription)")
            }
        }

        // 2. Delete orphaned files (article on disk but no record).
        let tracked = Set(all.map { filename(for: $0) })
        for url in vault.listArticleFiles() {
            let name = url.lastPathComponent
            if !tracked.contains(name) {
                try? FileManager.default.removeItem(at: url)
            }
        }

        // 3. Rebuild the queue index.
        writeIndex(articles: all)

        try? ctx.save()
    }

    // MARK: - Write

    private func writeArticle(_ article: Article) throws {
        guard let root = vault.root() else { return }
        let articlesDir = root.appending(path: "articles")
        if !FileManager.default.fileExists(atPath: articlesDir.path) {
            try FileManager.default.createDirectory(at: articlesDir, withIntermediateDirectories: true)
        }
        let body = MarkdownSerializer.article(article).data(using: .utf8) ?? Data()
        let target = articlesDir.appending(path: filename(for: article))
        try body.write(to: target, options: .atomic)
    }

    private func writeIndex(articles: [Article]) {
        guard let root = vault.root() else { return }
        let body = MarkdownSerializer.queueIndex(articles).data(using: .utf8) ?? Data()
        let target = root.appending(path: "index.md")
        try? body.write(to: target, options: .atomic)
    }

    private func filename(for article: Article) -> String {
        MarkdownSerializer.filename(for: article)
    }
}
