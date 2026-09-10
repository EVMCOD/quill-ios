import SwiftUI

struct ReaderView: View {
    let article: Article
    @EnvironmentObject private var store: ArticleStore
    @EnvironmentObject private var integrations: IntegrationHub
    @State private var newHighlight: String = ""
    @State private var newNote: String = ""
    @State private var showReader = false
    @State private var readerText: ReaderArticle?
    @State private var fetchingReader = false
    @State private var readerError: String?
    @FocusState private var highlightFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: QL.Spacing.lg) {
                hero
                actionRow
                readerSection
                if !article.highlights.isEmpty {
                    highlightsSection(article.highlights.sorted(by: { $0.orderIndex < $1.orderIndex }))
                }
                addHighlightCard
                Spacer(minLength: 80)
            }
            .padding(QL.Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(article.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .background(QL.Palette.bgDeep.ignoresSafeArea())
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showReader ? stopReader() : startReader()
                } label: {
                    Label(showReader ? "Article" : "Read",
                          systemImage: showReader ? QL.Icon.bookmark : "text.viewfinder")
                }
            }
        }
        #endif
    }

    // MARK: - Sections

    private var hero: some View {
        VStack(alignment: .leading, spacing: QL.Spacing.xs) {
            if !article.siteName.isEmpty {
                Text(article.siteName.uppercased())
                    .font(QL.Typography.sectionHead)
                    .foregroundStyle(QL.Palette.accent)
                    .tracking(1.0)
            }
            Text(article.title)
                .font(.system(size: 30, weight: .semibold, design: .serif))
                .foregroundStyle(QL.Palette.textStrong)
            if !article.summary.isEmpty {
                Text(article.summary)
                    .font(.body)
                    .foregroundStyle(QL.Palette.textMuted)
                    .padding(.top, QL.Spacing.xs)
            }
            Button {
                #if os(macOS)
                if let url = URL(string: article.url) { NSWorkspace.shared.open(url) }
                #else
                if let url = URL(string: article.url) { UIApplication.shared.open(url) }
                #endif
            } label: {
                Label(article.url, systemImage: QL.Icon.open)
                    .font(.caption)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(QL.Palette.accent)
            }
            .buttonStyle(.plain)
            .padding(.top, QL.Spacing.xs)
        }
    }

    private var actionRow: some View {
        HStack(spacing: QL.Spacing.sm) {
            Button {
                store.archive(article)
            } label: {
                Label("Archive", systemImage: QL.Icon.archive).font(.callout)
            }
            .buttonStyle(.bordered)
            Spacer()
        }
    }

    @ViewBuilder
    private var readerSection: some View {
        if showReader {
            VStack(alignment: .leading, spacing: QL.Spacing.md) {
                HStack(spacing: QL.Spacing.xs) {
                    Image(systemName: "text.viewfinder")
                        .foregroundStyle(QL.Palette.accent)
                    Text("Reader mode")
                        .font(QL.Typography.sectionHead)
                        .foregroundStyle(QL.Palette.textMuted)
                        .textCase(.uppercase)
                        .tracking(0.6)
                    Spacer()
                    if fetchingReader {
                        ProgressView().controlSize(.small)
                    }
                    if let reader = readerText {
                        Text("\(reader.estimatedReadingMinutes) min read")
                            .font(.caption)
                            .foregroundStyle(QL.Palette.textMuted)
                    }
                }
                if let readerError {
                    Text(readerError)
                        .font(.callout)
                        .foregroundStyle(QL.Palette.danger)
                        .padding(QL.Spacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: QL.Radius.md).fill(QL.Palette.surfaceHigh))
                }
                if let reader = readerText {
                    readingBody(reader)
                }
            }
            .padding(QL.Spacing.md)
            .qlCard()
            .onTapGesture { stopReader() }     // tap-anywhere to dismiss
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    @ViewBuilder
    private func readingBody(_ reader: ReaderArticle) -> some View {
        VStack(alignment: .leading, spacing: QL.Spacing.sm) {
            ForEach(Array(reader.blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .heading(let text, let level):
                    Text(text)
                        .font(.system(size: level <= 2 ? 22 : 18, weight: .semibold, design: .serif))
                        .foregroundStyle(QL.Palette.textStrong)
                        .padding(.top, QL.Spacing.xs)
                        .frame(maxWidth: 920, alignment: .leading)
                case .paragraph(let text):
                    Text(text)
                        .font(.system(size: 17, design: .serif))
                        .foregroundStyle(QL.Palette.textStrong)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: 920, alignment: .leading)
                case .quote(let text):
                    Text("\"\(text)\"")
                        .font(.system(size: 16, weight: .regular, design: .serif).italic())
                        .foregroundStyle(QL.Palette.textMuted)
                        .padding(.leading, QL.Spacing.md)
                        .overlay(
                            Rectangle()
                                .fill(QL.Palette.accent.opacity(0.5))
                                .frame(width: 3)
                                .padding(.vertical, 2),
                            alignment: .leading
                        )
                        .frame(maxWidth: 920, alignment: .leading)
                case .image(let url, _):
                    if let u = URL(string: url) {
                        AsyncImage(url: u) { phase in
                            switch phase {
                            case .success(let img): img.resizable().scaledToFit()
                            default: EmptyView()
                            }
                        }
                        .frame(maxHeight: 320)
                        .cornerRadius(QL.Radius.md)
                        .frame(maxWidth: 920)
                    }
                case .list(let items, let ordered):
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(items.enumerated()), id: \.offset) { idx, item in
                            HStack(alignment: .top, spacing: QL.Spacing.xs) {
                                Text(ordered ? "\(idx + 1)." : "•")
                                    .font(.system(size: 16, design: .serif))
                                    .foregroundStyle(QL.Palette.accent)
                                    .frame(width: 22, alignment: .leading)
                                Text(item)
                                    .font(.system(size: 16, design: .serif))
                                    .foregroundStyle(QL.Palette.textStrong)
                            }
                        }
                    }
                    .frame(maxWidth: 920, alignment: .leading)
                }
            }
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
                        .background(RoundedRectangle(cornerRadius: QL.Radius.md).fill(QL.Palette.accentMuted))
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
                .background(QL.Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: QL.Radius.md))
            TextField("Note (optional)", text: $newNote, axis: .vertical)
                .lineLimit(1...3)
                .padding(QL.Spacing.md)
                .background(QL.Palette.surfaceHigh, in: RoundedRectangle(cornerRadius: QL.Radius.md))
            Button {
                guard !newHighlight.isEmpty else { return }
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

    // MARK: - Actions

    private func startReader() {
        fetchingReader = true
        readerError = nil
        showReader = true
        Task {
            let parsed = await HTMLReader.shared.read(urlString: article.url)
            await MainActor.run {
                fetchingReader = false
                if let parsed {
                    readerText = parsed
                } else {
                    readerError = "Couldn't fetch the article body. Open the original URL instead."
                }
            }
        }
    }

    private func stopReader() {
        withAnimation(QL.Spring.snappy) {
            showReader = false
        }
    }
}
