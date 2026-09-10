import SwiftUI
import SwiftData

/// Adaptive shell — TabView on iOS, NavigationSplitView on macOS.
struct RootView: View {
    @EnvironmentObject private var store: ArticleStore
    @EnvironmentObject private var integrations: IntegrationHub
    @EnvironmentObject private var settings: AppSettings
    @State private var selection: Tab = .inbox
    @State private var presentingQuickAdd = false

    enum Tab: Hashable { case inbox, library, highlights, settings }

    var body: some View {
        Group {
            if !settings.hasOnboarded {
                OnboardingView { settings.hasOnboarded = true }
            } else {
                content
            }
        }
        .preferredColorScheme(settings.appearance)
        #if os(iOS)
        .onReceive(NotificationCenter.default.publisher(for: .qlQuickAdd)) { _ in
            presentingQuickAdd = true
        }
        #endif
    }

    @ViewBuilder
    private var content: some View {
        #if os(macOS)
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220)
        } detail: {
            detail
        }
        .sheet(isPresented: $presentingQuickAdd) {
            QuickCaptureSheet()
                .environmentObject(store)
                .environmentObject(integrations)
        }
        #else
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
        .sheet(isPresented: $presentingQuickAdd) {
            QuickCaptureSheet()
                .environmentObject(store)
                .environmentObject(integrations)
        }
        .overlay(alignment: .bottomTrailing) {
            QuickAddButton { presentingQuickAdd = true }
                .padding(.trailing, QL.Spacing.lg)
                .padding(.bottom, QL.Spacing.xxl)
        }
        #endif
    }

    #if os(macOS)
    private var sidebar: some View {
        List(selection: $selection) {
            Label("Inbox",      systemImage: QL.Icon.inbox).tag(Tab.inbox)
            Label("Library",    systemImage: QL.Icon.library).tag(Tab.library)
            Label("Highlights", systemImage: QL.Icon.highlights).tag(Tab.highlights)
            Divider()
            Label("Settings",   systemImage: QL.Icon.settings).tag(Tab.settings)
        }
        .listStyle(.sidebar)
        .safeAreaInset(edge: .bottom) {
            Button {
                presentingQuickAdd = true
            } label: {
                Label("Quick Capture", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
        }
    }

    @ViewBuilder
    private var detail: some View {
        switch selection {
        case .inbox:      InboxView()
        case .library:    LibraryView()
        case .highlights: HighlightsView()
        case .settings:   SettingsView()
        }
    }
    #endif
}

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
