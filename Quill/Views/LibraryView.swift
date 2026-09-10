import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var store: ArticleStore
    @State private var query: String = ""

    private var filtered: [Article] {
        let base = store.articles.filter { $0.status != .inbox }
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return base.sorted { $0.createdAt > $1.createdAt } }
        return base.filter { a in
            a.title.localizedCaseInsensitiveContains(q)
                || a.url.localizedCaseInsensitiveContains(q)
                || a.summary.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: QL.Spacing.md) {
                searchField
                if filtered.isEmpty {
                    EmptyStateView(
                        system: "books.vertical",
                        title: "Nothing yet",
                        subtitle: "Articles you've read live here.",
                        tint: QL.Palette.success
                    )
                } else {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { idx, article in
                        NavigationLink {
                            ReaderView(article: article)
                        } label: {
                            ArticleSummaryRow(article: article)
                                .qlCard()
                                .qlAppear(index: idx)
                        }
                        .buttonStyle(.plain)
                    }
                }
                Spacer(minLength: 80)
            }
            .padding(QL.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Library")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(QL.Palette.bgDeep.ignoresSafeArea())
    }

    private var searchField: some View {
        HStack(spacing: QL.Spacing.xs) {
            Image(systemName: QL.Icon.search).foregroundStyle(QL.Palette.textMuted)
            TextField("Search saved articles", text: $query)
            if !query.isEmpty {
                Button {
                    query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(QL.Palette.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(QL.Spacing.sm)
        .background(RoundedRectangle(cornerRadius: QL.Radius.md).fill(QL.Palette.surfaceHigh))
    }
}
