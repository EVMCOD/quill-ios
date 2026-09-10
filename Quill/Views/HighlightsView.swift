import SwiftUI

struct HighlightsView: View {
    @EnvironmentObject private var store: ArticleStore

    private var allHighlights: [Highlight] {
        store.articles
            .flatMap(\.highlights)
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: QL.Spacing.md) {
                Text(eyebrow)
                    .font(QL.Typography.sectionHead)
                    .foregroundStyle(QL.Palette.textMuted)
                    .textCase(.uppercase).tracking(0.6)
                Text("\(allHighlights.count)")
                    .font(QL.Typography.metricLg)
                    .foregroundStyle(QL.Palette.textStrong)
                    .monospacedDigit()
                if allHighlights.isEmpty {
                    EmptyStateView(
                        system: "highlighter",
                        title: "No highlights yet",
                        subtitle: "Open an article and tap \"Capture a passage\" to save your first.",
                        tint: QL.Palette.warning
                    )
                } else {
                    ForEach(Array(allHighlights.prefix(60).enumerated()), id: \.element.id) { idx, h in
                        highlightCard(h, index: idx)
                    }
                }
                Spacer(minLength: 80)
            }
            .padding(QL.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Highlights")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(QL.Palette.bgDeep.ignoresSafeArea())
    }

    private var eyebrow: String {
        switch allHighlights.count {
        case 0:  return "Highlights"
        case 1:  return "1 passage"
        default: return "\(allHighlights.count) passages"
        }
    }

    private func highlightCard(_ h: Highlight, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(h.text)
                .font(QL.Typography.highlight)
                .foregroundStyle(QL.Palette.textStrong)
                .padding(QL.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: QL.Radius.md).fill(QL.Palette.accentMuted)
                )
            HStack(spacing: QL.Spacing.xs) {
                if let article = h.article {
                    Image(systemName: QL.Icon.bookmark)
                        .font(.caption2)
                    Text(article.title)
                        .font(.caption)
                        .foregroundStyle(QL.Palette.textMuted)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Spacer()
                Text(h.createdAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(QL.Palette.textTertiary)
            }
            .padding(.horizontal, QL.Spacing.xs)
            if !h.note.isEmpty {
                Text("— \(h.note)")
                    .font(.callout).italic()
                    .foregroundStyle(QL.Palette.textMuted)
                    .padding(.horizontal, QL.Spacing.xs)
            }
        }
        .qlCard()
        .qlAppear(index: index)
    }
}
