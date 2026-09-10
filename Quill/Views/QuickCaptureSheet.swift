import SwiftUI

struct QuickCaptureSheet: View {
    @EnvironmentObject private var store: ArticleStore
    @EnvironmentObject private var integrations: IntegrationHub
    @Environment(\.dismiss) private var dismiss
    @State private var rawURL: String = ""
    @State private var title: String = ""
    @State private var tagsInput: String = ""
    @State private var fetching: Bool = false
    @State private var resolvedTitle: String = ""
    @State private var resolvedSite: String = ""
    @State private var resolvedSummary: String = ""
    @FocusState private var urlFocused: Bool

    private var parsedTags: [String] {
        tagsInput
            .split(separator: " ")
            .map { String($0).trimmingCharacters(in: CharacterSet(charactersIn: "#,")) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: QL.Spacing.md) {
                TextField("https://…", text: $rawURL)
                #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .font(.title3.weight(.semibold))
                #endif
                .focused($urlFocused)
                .padding(QL.Spacing.md)
                .background(QL.Palette.surfaceHigh,
                            in: RoundedRectangle(cornerRadius: QL.Radius.md))
                .onChange(of: rawURL) { _, _ in autofetch() }

                if fetching {
                    HStack(spacing: QL.Spacing.xs) {
                        ProgressView().controlSize(.small)
                        Text("Fetching article…")
                            .font(.caption).foregroundStyle(QL.Palette.textMuted)
                    }
                }

                if !resolvedTitle.isEmpty {
                    Text(resolvedTitle)
                        .font(.headline)
                        .foregroundStyle(QL.Palette.textStrong)
                }
                if !resolvedSite.isEmpty {
                    Text(resolvedSite)
                        .font(.caption)
                        .foregroundStyle(QL.Palette.textMuted)
                }

                TextField("Title (optional, override)", text: $title)
                    .padding(QL.Spacing.md)
                    .background(QL.Palette.surfaceHigh,
                                in: RoundedRectangle(cornerRadius: QL.Radius.md))

                TextField("Tags (e.g. ai / design)", text: $tagsInput)
                    .padding(QL.Spacing.md)
                    .background(QL.Palette.surfaceHigh,
                                in: RoundedRectangle(cornerRadius: QL.Radius.md))

                Spacer()
            }
            .padding(QL.Spacing.lg)
            .navigationTitle("Capture")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .bold()
                    .disabled(urlForSave.isEmpty)
                }
            }
            .onAppear { urlFocused = true }
            .background(QL.Palette.bgDeep.ignoresSafeArea())
        }
        #if os(iOS)
        .presentationDetents([.medium, .large])
        #endif
    }

    private var urlForSave: String {
        rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func autofetch() {
        let trimmed = urlForSave
        guard trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else { return }
        fetchedURL = trimmed
        fetching = true
        Task {
            let meta = await URLMetadataFetcher.shared.fetch(urlString: trimmed)
            await MainActor.run {
                if let meta, fetchedURL == trimmed {
                    resolvedTitle = title.isEmpty ? meta.title : title
                    resolvedSite = meta.siteName
                    resolvedSummary = meta.summary
                }
                fetching = false
            }
        }
    }

    @State private var fetchedURL: String = ""

    private func save() {
        let trimmedURL = urlForSave
        let chosenTitle = title.trimmingCharacters(in: .whitespaces).isEmpty
            ? (resolvedTitle.isEmpty ? (URL(string: trimmedURL)?.host ?? trimmedURL) : resolvedTitle)
            : title.trimmingCharacters(in: .whitespaces)
        let a = store.addArticle(
            url: trimmedURL,
            title: chosenTitle,
            summary: resolvedSummary,
            siteName: resolvedSite,
            tagNames: parsedTags,
            origin: Article.Origin.local
        )
        Task { await integrations.propagateToIntegrations(a) }
    }
}
