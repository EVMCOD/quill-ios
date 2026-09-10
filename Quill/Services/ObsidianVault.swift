import Foundation
import SwiftUI

/// Represents the user's chosen Obsidian vault folder. URL is stored as a
/// security-scoped bookmark in the keychain so the entitlement survives
/// across app launches and iOS re-installs.
public final class ObsidianVault: ObservableObject {
    public static let shared = ObsidianVault()

    @Published public private(set) var url: URL?

    private let bookmarkAccount = "vault_bookmark"

    public init() {
        restoreBookmark()
    }

    public func setVault(_ url: URL) throws {
        let bookmark = try url.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        KeychainStore.setData(bookmark, service: .vaultBookmark, account: bookmarkAccount)
        self.url?.stopAccessingSecurityScopedResource()
        _ = url.startAccessingSecurityScopedResource()
        DispatchQueue.main.async { self.url = url }
    }

    public func clear() {
        KeychainStore.remove(service: .vaultBookmark, account: bookmarkAccount)
        url?.stopAccessingSecurityScopedResource()
        url = nil
    }

    private func restoreBookmark() {
        guard let data = KeychainStore.data(service: .vaultBookmark, account: bookmarkAccount) else { return }
        var stale = false
        if let url = try? URL(
            resolvingBookmarkData: data,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) {
            _ = url.startAccessingSecurityScopedResource()
            DispatchQueue.main.async { self.url = url }
        }
    }
}

extension ObsidianVault {
    /// Root folder for Quill-managed files inside the vault.
    public func root() -> URL? {
        guard let url else { return nil }
        let dir = url.appending(path: "quill")
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    public func listArticleFiles() -> [URL] {
        guard let root = root() else { return [] }
        let articlesDir = root.appending(path: "articles")
        return (try? FileManager.default.contentsOfDirectory(
            at: articlesDir, includingPropertiesForKeys: [.contentModificationDateKey]
        ).filter { $0.pathExtension == "md" }) ?? []
    }
}
