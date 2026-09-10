import SwiftUI

struct ObsidianSettingsView: View {
    @EnvironmentObject private var integrations: IntegrationHub
    @ObservedObject private var vault = ObsidianVault.shared
    @State private var pickerOpen = false

    var body: some View {
        Form {
            Section {
                if let url = vault.url {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current vault")
                            .font(.caption).foregroundStyle(QL.Palette.textMuted)
                        Text(url.lastPathComponent)
                            .font(.body.weight(.semibold))
                        Text(url.deletingLastPathComponent().path)
                            .font(.caption)
                            .foregroundStyle(QL.Palette.textTertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    Button("Pick another vault…") { pickerOpen = true }
                    Button("Clear vault", role: .destructive) {
                        integrations.clearObsidianVault()
                    }
                } else {
                    Button {
                        pickerOpen = true
                    } label: {
                        Label("Pick vault folder…", systemImage: "folder.badge.plus")
                    }
                }
            } footer: {
                Text("Quill writes one markdown file per article under `quill/articles/`, plus a `quill/index.md` queue. Each file uses YAML frontmatter so other tools — Dataview, Templater, Scripts — can read them.")
            }

            Section("Sync") {
                Button {
                    Task { await integrations.syncAll() }
                } label: {
                    Label("Sync now", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(vault.url == nil)

                if let last = integrations.lastSync {
                    Text("Last sync \(last.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(QL.Palette.textMuted)
                }
            }
        }
        .navigationTitle("Obsidian")
        .sheet(isPresented: $pickerOpen) {
            FolderPickerSheet { url in
                integrations.setObsidianVault(url)
                pickerOpen = false
            }
        }
    }
}

// MARK: - Folder picker

#if os(iOS)
struct FolderPickerSheet: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        picker.shouldShowFileExtensions = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            onPick(url)
        }
    }
}
#else
struct FolderPickerSheet: View {
    let onPick: (URL) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: QL.Spacing.lg) {
            Text("Pick vault").font(.title2.weight(.semibold))
            Text("Choose the vault folder in the dialog below.")
                .multilineTextAlignment(.center)
                .foregroundStyle(QL.Palette.textMuted)
            Button("Open picker…") {
                let panel = NSOpenPanel()
                panel.canChooseDirectories = true
                panel.canChooseFiles = false
                panel.allowsMultipleSelection = false
                panel.prompt = "Choose vault"
                if panel.runModal() == .OK, let url = panel.url {
                    onPick(url)
                }
            }
            .buttonStyle(.borderedProminent)
            Button("Cancel") { dismiss() }
        }
        .padding(QL.Spacing.xl)
        .frame(width: 420)
    }
}
#endif
