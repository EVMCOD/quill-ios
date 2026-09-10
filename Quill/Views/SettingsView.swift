import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var integrations: IntegrationHub
    @StateObject private var settings = AppSettings.shared

    private var appearanceBinding: Binding<String> {
        Binding(
            get: { settings.appearanceRaw },
            set: { settings.setAppearance(AppSettings.Appearance(rawValue: $0) ?? .system) }
        )
    }

    var body: some View {
        List {
            Section {
                NavigationLink(destination: ObsidianSettingsView()) {
                    IntegrationRow(
                        name: "Obsidian",
                        sfSymbol: "diamond",
                        state: integrations.obsidian,
                        accent: .indigo
                    )
                }
            } header: {
                Text("Integrations")
            } footer: {
                Text("Quill writes a clean markdown file per article, plus a `quill/index.md` queue file. Place your vault anywhere readable: iCloud, Dropbox, your home folder.")
            }

            Section {
                LabeledContent("Last sync") {
                    Text(integrations.lastSync?.formatted(date: .abbreviated, time: .shortened) ?? "Never")
                        .foregroundStyle(QL.Palette.textMuted)
                }
            } header: {
                Text("Sync")
            }

            Section {
                Picker("Theme", selection: appearanceBinding) {
                    ForEach(AppSettings.Appearance.allCases) { a in
                        Text(a.label).tag(a.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Appearance")
            }

            Section {
                LabeledContent("Version", value: "1.0.0 (build 1)")
                LabeledContent("Bundle", value: "app.quill.ios")
                LabeledContent("Engine", value: "SwiftData + Obsidian")
            } header: {
                Text("About")
            }
        }
        .navigationTitle("Settings")
        .background(QL.Palette.bgDeep.ignoresSafeArea())
    }
}

struct IntegrationRow: View {
    let name: String
    let sfSymbol: String
    let state: IntegrationHub.IntegrationState
    let accent: Color

    var body: some View {
        HStack {
            Image(systemName: sfSymbol)
                .foregroundStyle(accent)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(name).font(.body)
                Text(state.label)
                    .font(.caption)
                    .foregroundStyle(color(for: state))
            }
            Spacer()
            Circle()
                .fill(color(for: state))
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }

    private func color(for state: IntegrationHub.IntegrationState) -> Color {
        switch state {
        case .ok:             return QL.Palette.success
        case .syncing:        return QL.Palette.warning
        case .error:          return QL.Palette.danger
        case .disconnected,
             .notConfigured:  return QL.Palette.textTertiary
        }
    }
}
