import SwiftUI
import SwiftData
import Combine

/// Single source of truth for articles + highlights. Mirrors Tack's
/// `TaskStore` pattern: App Group-backed SwiftData container, observable.
@MainActor
public final class ArticleStore: ObservableObject {
    public static let shared = ArticleStore()

    public let container: ModelContainer

    @Published public private(set) var articles: [Article] = []
    @Published public private(set) var folders: [Folder] = []

    private var cancellables: Set<AnyCancellable> = []

    private init() {
        let schema = Schema([Article.self, Highlight.self, Folder.self, Tag.self])
        let url = Self.storeURL()
        let config = ModelConfiguration(schema: schema, url: url)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            container = try! ModelContainer(for: schema, configurations: [fallback])
            QLLog.fail.error("Open store failed: \(error). Falling back to in-memory.")
        }
        seedIfNeeded()
        observe()
    }

    // MARK: - Mutation API

    @discardableResult
    public func addArticle(
        url: String,
        title: String,
        summary: String = "",
        imageURL: String? = nil,
        siteName: String = "",
        folder: Folder? = nil,
        tagNames: [String] = [],
        origin: String = Article.Origin.local
    ) -> Article {
        let ctx = container.mainContext
        let target = folder ?? ensureInbox(in: ctx)
        let article = Article(
            url: url,
            title: title,
            summary: summary,
            imageURL: imageURL,
            siteName: siteName,
            folder: target,
            origin: origin
        )
        article.order = nextOrder(in: ctx)
        // Resolve / create tags
        var tags: [Tag] = []
        for name in tagNames where !name.isEmpty {
            let descriptor = FetchDescriptor<Tag>(predicate: #Predicate<Tag> { $0.name == name })
            if let existing = try? ctx.fetch(descriptor).first {
                tags.append(existing)
            } else {
                let tag = Tag(name: name)
                ctx.insert(tag)
                tags.append(tag)
            }
        }
        article.tags = tags
        ctx.insert(article)
        try? ctx.save()
        refresh()
        return article
    }

    public func toggleRead(_ article: Article) {
        if article.status == .read {
            article.status = .inbox
            article.readAt = nil
        } else {
            article.status = .read
            article.readAt = .now
        }
        try? container.mainContext.save()
        refresh()
    }

    public func archive(_ article: Article) {
        article.status = .archived
        article.archivedAt = .now
        try? container.mainContext.save()
        refresh()
    }

    public func unarchive(_ article: Article) {
        article.status = article.readAt != nil ? .read : .inbox
        article.archivedAt = nil
        try? container.mainContext.save()
        refresh()
    }

    @discardableResult
    public func addHighlight(to article: Article, text: String, note: String = "") -> Highlight {
        let ctx = container.mainContext
        let next = (article.highlights.map(\.orderIndex).max() ?? -1) + 1
        let h = Highlight(text: text, note: note, sourceURL: article.url, article: article, orderIndex: next)
        ctx.insert(h)
        article.highlights.append(h)
        try? ctx.save()
        refresh()
        return h
    }

    public func deleteArticle(_ article: Article) {
        container.mainContext.delete(article)
        try? container.mainContext.save()
        refresh()
    }

    // MARK: - Derived getters

    public var inbox:  [Article] { articles.filter { $0.status == .inbox }.sorted { $0.createdAt > $1.createdAt } }
    public var read:   [Article] { articles.filter { $0.status == .read }.sorted { $0.createdAt > $1.createdAt } }
    public var archiveBucket: [Article] { articles.filter { $0.status == .archived }.sorted { $0.createdAt > $1.createdAt } }

    // MARK: - Reading streak

    public var readingStreak: Int {
        let cal = Calendar.current
        let readingDays = Set(articles
            .filter { $0.status == .read }
            .compactMap { $0.readAt }
            .map { cal.startOfDay(for: $0) })
        var streak = 0
        var day = cal.startOfDay(for: .now)
        while readingDays.contains(day) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
            if streak > 365 { break }
        }
        return streak
    }

    // MARK: - Private

    private func observe() {
        NotificationCenter.default
            .publisher(for: ModelContext.didSave)
            .debounce(for: .milliseconds(80), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
        refresh()
    }

    public func refresh() {
        let ctx = container.mainContext
        articles = (try? ctx.fetch(FetchDescriptor<Article>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)]))) ?? []
        folders  = (try? ctx.fetch(FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.order), SortDescriptor(\.name)]))) ?? []
    }

    private func ensureInbox(in ctx: ModelContext) -> Folder {
        let descriptor = FetchDescriptor<Folder>(predicate: #Predicate { $0.name == "Inbox" })
        if let existing = try? ctx.fetch(descriptor).first { return existing }
        let inbox = Folder(name: "Inbox", icon: "tray", accent: nil, order: 0)
        ctx.insert(inbox)
        return inbox
    }

    private func nextOrder(in ctx: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Article>(sortBy: [SortDescriptor(\.order, order: .reverse)])
        return ((try? ctx.fetch(descriptor).first?.order) ?? 0) + 1
    }

    private func seedIfNeeded() {
        let ctx = container.mainContext
        let count = (try? ctx.fetchCount(FetchDescriptor<Folder>())) ?? 0
        if count == 0 {
            ctx.insert(Folder(name: "Inbox",  icon: "tray",     accent: nil,            order: 0))
            ctx.insert(Folder(name: "Read",   icon: "checkmark.seal.fill", accent: nil,    order: 1))
            ctx.insert(Folder(name: "Archive", icon: "archivebox.fill", accent: nil,    order: 2))
            try? ctx.save()
        }
    }

    /// One-shot seed for first-launch demos — populated once, then the
    /// user owns their data. Mirrors Tack's `seedDemoDataOnFirstLaunch`.
    public func seedDemoOnFirstLaunch() {
        let key = "app.quill.didSeedDemoData.v1"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: key) else { return }
        if seedDemosIfEmpty() {
            defaults.set(true, forKey: key)
        }
    }

    @discardableResult
    private func seedDemosIfEmpty() -> Bool {
        let ctx = container.mainContext
        let existing = (try? ctx.fetchCount(FetchDescriptor<Article>())) ?? 0
        guard existing == 0 else { return false }
        let inbox = (try? ctx.fetch(FetchDescriptor<Folder>(predicate: #Predicate { $0.name == "Inbox" })).first)
                    ?? ensureInbox(in: ctx)
        let demos: [(url: String, title: String, summary: String, status: ArticleStatus)] = [
            ("https://www.apple.com/newsroom/",
             "Apple Newsroom",
             "Press releases, features, and updates from Apple.",
             .inbox),
            ("https://tonsky.me/blog/monitors/",
             "Monitors are easy",
             "Notes on what to look for in a great computer monitor.",
             .inbox),
            ("https://apenwarr.ca/log/20240803",
             "Tailscale: a year in review",
             "Reflections on shipping a network stack for individuals and teams.",
             .read),
            ("https://brandur.org/rampant",
             "Rampant",
             "On the design of developer APIs.",
             .inbox),
            ("https://dri.es/fosdem-2024-keynote",
             "FOSDEM 2024 keynote",
             "The shape of Postgres to come — a wide-ranging community talk.",
             .read),
            ("https://en.wikipedia.org/wiki/Persistence_(computer_science)",
             "Persistence (computer science)",
             "Survey article on persistence mechanisms in software systems.",
             .inbox)
        ]
        for (idx, d) in demos.enumerated() {
            let a = Article(url: d.url, title: d.title, summary: d.summary,
                            siteName: URL(string: d.url)?.host ?? "",
                            folder: inbox, status: d.status, origin: Article.Origin.local)
            a.order = idx
            if d.status == .read { a.readAt = .now.addingTimeInterval(-Double.random(in: 0...7200)) }
            ctx.insert(a)
        }
        try? ctx.save()
        refresh()
        return true
    }

    private static func storeURL() -> URL {
        let groupID = "group.app.quill.shared"
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) {
            return url.appending(path: "Quill.store")
        }
        let dir = (try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true
        )) ?? FileManager.default.temporaryDirectory
        return dir.appending(path: "Quill.store")
    }
}
