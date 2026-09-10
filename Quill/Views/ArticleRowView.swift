import SwiftUI

/// One-row article entry used by Inbox, Library and the iPad master lists.
struct ArticleSummaryRow: View {
    let article: Article
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(article.title)
                .font(QL.Typography.cardTitle)
                .foregroundStyle(article.status == .read ? QL.Palette.textTertiary : QL.Palette.textStrong)
                .strikethrough(article.status == .read)
                .lineLimit(2)
            HStack(spacing: QL.Spacing.xs) {
                Image(systemName: QL.Icon.bookmark).font(.caption2)
                Text(article.siteName.isEmpty ? article.url : article.siteName)
                    .font(.caption)
                    .foregroundStyle(QL.Palette.textMuted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            if !article.summary.isEmpty {
                Text(article.summary)
                    .font(.caption)
                    .foregroundStyle(QL.Palette.textTertiary)
                    .lineLimit(2)
            }
        }
        .padding(QL.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}
