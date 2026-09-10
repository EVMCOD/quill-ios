import SwiftUI
import SwiftData

/// Adaptive shell — TabView on iPhone, NavigationSplitView on iPad + macOS,
/// gating onboarding on the first launch.
struct RootView: View {
    @EnvironmentObject private var store: ArticleStore
    @EnvironmentObject private var integrations: IntegrationHub
    @EnvironmentObject private var settings: AppSettings
    @State private var selection: Tab = .inbox
    @State private var showingQuickAdd = false
    @State private var detailID: UUID?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    @Environment(\.horizontalSizeClass) private var hSize

    enum Tab: Hashable { case inbox, library, highlights, settings }

    var body: some View {
        mainContent
            .preferredColorScheme(settings.appearance)
            #if os(iOS)
            .onReceive(NotificationCenter.default.publisher(for: .qlQuickAdd)) { _ in
                showingQuickAdd = true
            }
            #endif
            .onAppear { Task { await SharedInbox.drain(into: store) } }
            .sheet(isPresented: $showingQuickAdd) {
                QuickCaptureSheet()
                    .environmentObject(store)
                    .environmentObject(integrations)
            }
    }

    @ViewBuilder
    private var mainContent: some View {
        if !settings.hasOnboarded {
            OnboardingView { settings.hasOnboarded = true }
        } else if shouldUseSplit {
            splitLayout
        } else {
            tabLayout
        }
    }

    // iPad regular width OR macOS — use split layout
    private var shouldUseSplit: Bool {
        #if os(macOS)
        return true
        #else
        return hSize == .regular
        #endif
    }

    // MARK: - Phone layout (TabView)

    @ViewBuilder
    private var tabLayout: some View {
        TabView(selection: $selection) {
            NavigationStack { InboxView() }
                .tabItem { Label("Inbox", systemImage: QL.Icon.inbox) }
                .tag(Tab.inbox)
            NavigationStack { LibraryView() }
                .tabItem { Label("Library", systemImage: QL.Icon.library) }
                .tag(Tab.library)
            NavigationStack { HighlightsView() }
                .tabItem { Label("Highlights", systemImage: QL.Icon.highlights) }
                .tag(Tab.highlights)
            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: QL.Icon.settings) }
                .tag(Tab.settings)
        }
        .overlay(alignment: .bottomTrailing) {
            QuickAddButton { showingQuickAdd = true }
                .padding(.trailing, QL.Spacing.lg)
                .padding(.bottom, QL.Spacing.xxl)
        }
    }

    // MARK: - iPad + macOS layout (NavigationSplitView)

    @ViewBuilder
    private var splitLayout: some View {
        #if os(macOS)
        NavigationSplitView(columnVisibility: .constant(.all)) {
            sidebar
        } detail: {
            detailColumn
        }
        .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        #else
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar
        } content: {
            listColumn
        } detail: {
            detailColumn
        }
        #endif
    }

    @ViewBuilder
    private var sidebar: some View {
        List {
            sidebarRow(.inbox,     icon: QL.Icon.inbox,      label: "Inbox")
            sidebarRow(.library,   icon: QL.Icon.library,    label: "Library")
            sidebarRow(.highlights, icon: QL.Icon.highlights, label: "Highlights")
            Divider()
            sidebarRow(.settings,  icon: QL.Icon.settings,   label: "Settings")
        }
        .listStyle(.sidebar)
        #if os(macOS)
        .safeAreaInset(edge: .bottom) {
            Button {
                showingQuickAdd = true
            } label: {
                Label("Quick Capture", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
        #endif
    }

    @ViewBuilder
    private func sidebarRow(_ tab: Tab, icon: String, label: String) -> some View {
        Button {
            selection = tab
        } label: {
            HStack {
                Image(systemName: icon).frame(width: 22)
                    .foregroundStyle(selection == tab ? QL.Palette.accent : QL.Palette.textMuted)
                Text(label)
                    .foregroundStyle(selection == tab ? QL.Palette.textStrong : QL.Palette.textMuted)
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    /// iPad only — the master list (open articles) feeds the detail.
    @ViewBuilder
    private var listColumn: some View {
        Group {
            switch selection {
            case .inbox:
                InboxListView(detailID: $detailID)
            case .library:
                LibraryListView(detailID: $detailID)
            case .highlights:
                HighlightsListView(detailID: $detailID)
            case .settings:
                SettingsView()
            }
        }
    }

    @ViewBuilder
    private var detailColumn: some View {
        if let id = detailID, let article = store.articles.first(where: { $0.id == id }) {
            ReaderView(article: article)
        } else if selection == .settings {
            SettingsView()
        } else {
            VStack(spacing: QL.Spacing.md) {
                Image(systemName: "book")
                    .font(.system(size: 56))
                    .foregroundStyle(QL.Palette.textTertiary)
                Text("Pick an article to start reading.")
                    .font(.callout)
                    .foregroundStyle(QL.Palette.textMuted)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(QL.Palette.bgDeep)
        }
    }
}

// MARK: - iPad master list variants

private struct InboxListView: View {
    @EnvironmentObject private var store: ArticleStore
    @Binding var detailID: UUID?

    var body: some View {
        List(selection: $detailID) {
            Section("Inbox") {
                ForEach(store.inbox) { article in
                    ArticleSummaryRow(article: article).tag(article.id as UUID?)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Inbox")
    }
}

private struct LibraryListView: View {
    @EnvironmentObject private var store: ArticleStore
    @Binding var detailID: UUID?
    var body: some View {
        List(selection: $detailID) {
            Section("Saved") {
                ForEach(store.articles.filter { $0.status != .inbox }) { article in
                    ArticleSummaryRow(article: article).tag(article.id as UUID?)
                }
            }
        }
        .navigationTitle("Library")
    }
}

private struct HighlightsListView: View {
    @EnvironmentObject private var store: ArticleStore
    @Binding var detailID: UUID?
    var body: some View {
        List(selection: $detailID) {
            ForEach(store.articles.filter { !$0.highlights.isEmpty }) { article in
                Section(article.title) {
                    ForEach(article.highlights.sorted(by: { $0.orderIndex < $1.orderIndex })) { h in
                        Text(h.text)
                            .font(QL.Typography.highlight)
                            .foregroundStyle(QL.Palette.textStrong)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Highlights")
    }
}

// MARK: - Quick add button

private struct QuickAddButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Image(systemName: QL.Icon.addBold)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle().fill(QL.Palette.accent)
                        .shadow(color: QL.Palette.accentGlow, radius: 12, x: 0, y: 6)
                )
        }
        .accessibilityLabel("Quick Capture")
        .qlHoverable()
    }
}
