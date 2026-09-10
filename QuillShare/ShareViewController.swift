import UIKit
import UniformTypeIdentifiers

/// iOS Share Extension for Quill.
///
/// Receives a URL from Safari / Mail / any app that supports web sharing,
/// appends it to the App Group inbox file via `SharedInboxBridge`,
/// then closes the extension. The main app drains the inbox on next
/// launch through `SharedInbox.drain(into:)`.
final class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        Task { await ingest() }
    }

    private func ingest() async {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            return finish()
        }

        var collected: [SharedInboxBridge.Entry] = []
        for item in items {
            collected.append(contentsOf: await extractUrls(from: item))
        }
        if !collected.isEmpty {
            await MainActor.run { SharedInboxBridge.write(collected) }
        }
        finish()
    }

    private func extractUrls(from item: NSExtensionItem) async -> [SharedInboxBridge.Entry] {
        let typeId = UTType.url.identifier
        guard let attachments = item.attachments else { return [] }

        let suggested = item.attributedContentText?.string
        return await withTaskGroup(of: SharedInboxBridge.Entry?.self) { group in
            for provider in attachments {
                guard provider.hasItemConformingToTypeIdentifier(typeId) else { continue }
                group.addTask {
                    guard let data = try? await provider.loadItem(forTypeIdentifier: typeId),
                          let url = (data as? URL) ?? (data as? String).flatMap(URL.init(string:))
                    else { return nil }
                    return SharedInboxBridge.Entry(
                        url: url.absoluteString,
                        sharedAt: .now,
                        suggestedTitle: suggested
                    )
                }
            }
            var hits: [SharedInboxBridge.Entry] = []
            for await result in group { if let r = result { hits.append(r) } }
            return hits
        }
    }

    private func finish() {
        DispatchQueue.main.async { [weak self] in
            self?.extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
