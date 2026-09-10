import Foundation
import SwiftData

/// Main-app side of the share extension handoff. Reads pending entries
/// from the App Group inbox and inserts them into the `ArticleStore`.
@MainActor
public enum SharedInbox {

    public static func drain(into store: ArticleStore, group: String = SharedInboxBridge.appGroup) async {
        let entries = SharedInboxBridge.readAll(group: group)
        guard !entries.isEmpty else { return }

        for entry in entries {
            let initialTitle = entry.suggestedTitle
                ?? URL(string: entry.url)?.host
                ?? entry.url
            let article = store.addArticle(
                url: entry.url,
                title: initialTitle,
                origin: Article.Origin.share
            )
            // Best-effort metadata refresh once the app is in foreground.
            if let meta = await URLMetadataFetcher.shared.fetch(urlString: entry.url) {
                article.title = meta.title
                article.summary = meta.summary
                article.siteName = meta.siteName
                article.imageURL = meta.imageURL
                try? store.container.mainContext.save()
                store.refresh()
            }
        }

        SharedInboxBridge.clear(group: group)
    }
}
