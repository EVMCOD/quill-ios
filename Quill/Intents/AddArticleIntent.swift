import AppIntents
import Foundation

/// Quick add an article from Siri / Shortcuts.
struct AddArticleIntent: AppIntent {
    static var title: LocalizedStringResource = "Save article"
    static var description = IntentDescription("Saves an article to Quill for later reading.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "URL")
    var url: String

    init() {}

    init(url: String) { self.url = url }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .result(dialog: "I need a URL to save.")
        }
        let initialTitle = URL(string: trimmed)?.host ?? trimmed
        let article = ArticleStore.shared.addArticle(
            url: trimmed, title: initialTitle,
            origin: Article.Origin.share
        )
        Task {
            if let meta = await URLMetadataFetcher.shared.fetch(urlString: trimmed) {
                await MainActor.run {
                    article.title = meta.title
                    article.summary = meta.summary
                    article.siteName = meta.siteName
                    article.imageURL = meta.imageURL
                    try? ArticleStore.shared.container.mainContext.save()
                    ArticleStore.shared.refresh()
                }
            }
        }
        await IntegrationHub.shared.propagateToIntegrations(article)
        return .result(dialog: "Saved \"\(initialTitle)\" to Quill.")
    }
}
