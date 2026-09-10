import SwiftUI
import SwiftData
import AppIntents

@main
struct QuillApp: App {
    @StateObject private var store = ArticleStore.shared
    @StateObject private var integrations = IntegrationHub.shared
    @StateObject private var settings = AppSettings.shared
    @Environment(\.scenePhase) private var scenePhase

    init() {
        TackAppShortcuts.updateAppShortcutParameters()  // shim until real QuillShortcuts lands
        ArticleStore.shared.seedDemoOnFirstLaunch()
    }

    // Shim — placeholder until real QuillShortcuts lands.
    struct TackAppShortcuts {
        static func updateAppShortcutParameters() {}
    }

    var body: some Scene {
        primaryScene
        #if os(macOS)
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(store)
        } label: {
            Image(systemName: "book.closed.fill")
        }
        .menuBarExtraStyle(.window)
        #endif
    }

    private var primaryScene: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(integrations)
                .environmentObject(settings)
                .preferredColorScheme(settings.appearance)
                #if os(macOS)
                .frame(minWidth: 880, minHeight: 600)
                #endif
        }
        .modelContainer(store.container)
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background: integrations.scheduleBackgroundRefresh()
            case .active:    integrations.refreshOnLaunch()
            default: break
            }
        }
        #if os(macOS)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Article") { NotificationCenter.default.post(name: .qlQuickAdd, object: nil) }
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") { NotificationCenter.default.post(name: .qlOpenSettings, object: nil) }
                    .keyboardShortcut(",", modifiers: .command)
            }
        }
        #endif
    }
}

extension Notification.Name {
    static let qlQuickAdd      = Notification.Name("app.quill.quickAdd")
    static let qlOpenSettings  = Notification.Name("app.quill.openSettings")
}

// MARK: - macOS MenuBar

#if os(macOS)
private struct MenuBarContent: View {
    @EnvironmentObject private var store: ArticleStore
    @State private var url: String = ""
    @State private var title: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            captureSection
            inboxSection
            Divider()
            Button("Open Quill…") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderless)
        }
        .padding(QL.Spacing.md)
        .frame(width: 380)
        .onAppear { focused = true }
    }

    @ViewBuilder
    private var captureSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Capture")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            TextField("https://...", text: $url)
                .textFieldStyle(.roundedBorder)
                .focused($focused)
                .onSubmit(add)
            HStack {
                TextField("Title (optional)", text: $title)
                    .textFieldStyle(.roundedBorder)
                Button("Save", action: add)
                    .buttonStyle(.borderedProminent)
                    .disabled(url.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    @ViewBuilder
    private var inboxSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            Text("Inbox · \(store.inbox.count)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            if store.inbox.isEmpty {
                Text("Empty.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                ForEach(store.inbox.prefix(8)) { article in
                    InboxRow(article: article) {
                        store.toggleRead(article)
                    }
                }
            }
        }
    }

    private func add() {
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedUrl.isEmpty else { return }
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let initialTitle: String
        if trimmedTitle.isEmpty {
            initialTitle = URL(string: trimmedUrl)?.host ?? trimmedUrl
        } else {
            initialTitle = trimmedTitle
        }
        let article = store.addArticle(
            url: trimmedUrl,
            title: initialTitle,
            origin: Article.Origin.menu
        )
        Task {
            if let meta = await URLMetadataFetcher.shared.fetch(urlString: trimmedUrl) {
                await MainActor.run {
                    article.title = meta.title
                    article.summary = meta.summary
                    article.siteName = meta.siteName
                    article.imageURL = meta.imageURL
                    try? store.container.mainContext.save()
                    store.refresh()
                }
            }
        }
        url = ""
        title = ""
    }
}

private struct InboxRow: View {
    let article: Article
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: article.status == .read ? "checkmark.seal.fill" : "circle")
                    .foregroundStyle(article.status == .read ? Color.green : Color.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title).lineLimit(1)
                    Text(article.url)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}
#endif
