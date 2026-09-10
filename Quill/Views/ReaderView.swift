import SwiftUI

struct ReaderView: View {
    let articleID: UUID
    @EnvironmentObject private var store: ArticleStore
    @State private var newHighlight: String = ""
    @State private var newNote: String = ""
    @FocusState private var highlightFocused: Bool

    private var article: Article? { store.articles.first(where: { $0.id == articleID }) }

    var body: some View {
        ScrollView {
            if let article {
                VStack(alignment: .leading, spacing: QL.Spacing.lg) {
                    hero(article)
                    actionRow(article)
                    if !article.highlights.isEmpty {
                        highlightsSection(article.highlights.sorted(by: { $0.orderIndex < $1.orderIndex }))
                    }
                    addHighlightCard
                    Spacer(minLength: 80)
                }
                .padding(QL.Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                EmptyStateView(
                    system: "questionmark.circle",
                    title: "Article not found",
                    subtitle: "It may have been deleted from your library.",
                    tint: QL.Palette.textMuted
                )
            }
        }
        .navigationTitle(article?.title ?? "Article")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(QL.Palette.bgDeep.ignoresSafeArea())
        .onAppear {
            if let a = article, a.status == .inbox {
                withAnimation(QL.Spring.snappy) { store.toggleRead(a) }
            }
        }
    }

    private func hero(_ a: Article) -> some View {
        VStack(alignment: .leading, spacing: QL.Spacing.xs) {
            if !a.siteName.isEmpty {
                Text(a.siteName.uppercased())
                    .font(QL.Typography.sectionHead)
                    .foregroundStyle(QL.Palette.accent)
                    .tracking(1.0)
            }
            Text(a.title)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(QL.Palette.textStrong)
            if !a.summary.isEmpty {
                Text(a.summary)
                    .font(.body)
                    .foregroundStyle(QL.Palette.textMuted)
                    .padding(.top, QL.Spacing.xs)
            }
            Button {
                #if os(macOS)
                if let url = URL(string: a.url) { NSWorkspace.shared.open(url) }
                #else
                UIApplication.shared.open(URL(string: a.url)!)
                #endif
            } label: {
                Label(a.url, systemImage: QL.Icon.open)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(QL.Palette.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, QL.Spacing.xs)
        }
    }

    private func actionRow(_ a: Article) -> some View {
        HStack(spacing: QL.Spacing.sm) {
            Button {
                store.archive(a)
            } label: {
                Label("Archive", systemImage: QL.Icon.archive).font(.callout)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }

    private func highlightsSection(_ highlights: [Highlight]) -> some View {
        VStack(alignment: .leading, spacing: QL.Spacing.sm) {
            Text("Highlights")
                .font(QL.Typography.sectionHead)
                .foregroundStyle(QL.Palette.textMuted)
                .textCase(.uppercase).tracking(0.6)
            ForEach(highlights, id: \.id) { h in
                VStack(alignment: .leading, spacing: 6) {
                    Text(h.text)
                        .font(QL.Typography.highlight)
                        .foregroundStyle(QL.Palette.textStrong)
                        .padding(QL.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: QL.Radius.md)
                                .fill(QL.Palette.accentMuted)
                        )
                    if !h.note.isEmpty {
                        Text("— \(h.note)")
                            .font(.callout).italic()
                            .foregroundStyle(QL.Palette.textMuted)
                            .padding(.horizontal, QL.Spacing.xs)
                    }
                }
            }
        }
    }

    private var addHighlightCard: some View {
        VStack(alignment: .leading, spacing: QL.Spacing.xs) {
            Text("Capture a passage")
                .font(QL.Typography.sectionHead)
                .foregroundStyle(QL.Palette.textMuted)
                .textCase(.uppercase).tracking(0.6)
            TextField("Quote or passage", text: $newHighlight, axis: .vertical)
                .lineLimit(1...6)
                .focused($highlightFocused)
                .padding(QL.Spacing.md)
                .background(QL.Palette.surfaceHigh,
                            in: RoundedRectangle(cornerRadius: QL.Radius.md))
            TextField("Note (optional)", text: $newNote, axis: .vertical)
                .lineLimit(1...3)
                .padding(QL.Spacing.md)
                .background(QL.Palette.surfaceHigh,
                            in: RoundedRectangle(cornerRadius: QL.Radius.md))
            Button {
                guard let article = article, !newHighlight.isEmpty else { return }
                _ = store.addHighlight(to: article, text: newHighlight, note: newNote)
                newHighlight = ""
                newNote = ""
            } label: {
                Label("Save highlight", systemImage: "highlighter")
                    .font(.callout.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, QL.Spacing.sm)
                    .background(Capsule().fill(QL.Palette.accent))
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
            .disabled(newHighlight.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
