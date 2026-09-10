import Foundation

/// Bridge between the iOS Share Extension and the main app. Pure value
/// type with no SwiftData dependency so it compiles into both the
/// `Quill` and `QuillShare` targets.
///
/// Flow:
///   1. Share Extension receives a URL in `extensionContext`
///   2. Writes `{url, sharedAt, suggestedTitle}` records to
///      `<AppGroup>/quill-share-inbox.json`
///   3. Main app reads on next launch (or scenePhase=active) and
///      inserts each pending URL into the inbox, then clears the file.
///
/// The Codable shape is loose on purpose — share extensions are a
/// separate target and shouldn't import the main app's types.
public enum SharedInboxBridge {

    public struct Entry: Codable {
        public let url: String
        public let sharedAt: Date
        public let suggestedTitle: String?
    }

    public static let appGroup = "group.app.quill.shared"
    public static let filename = "quill-share-inbox.json"

    /// Append entries to the pending inbox file. Called from the share extension.
    public static func write(_ entries: [Entry], group: String = appGroup) {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            return
        }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let target = dir.appending(path: filename)
        var existing = (try? readAll(from: target)) ?? []
        existing.append(contentsOf: entries)
        guard let data = try? encoder().encode(existing) else { return }
        try? data.write(to: target, options: .atomic)
    }

    /// Read all pending entries without removing them.
    public static func readAll(group: String = appGroup) -> [Entry] {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            return []
        }
        let fileURL = dir.appending(path: filename)
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Entry].self, from: data)) ?? []
    }

    /// Remove the inbox file (called after a successful drain).
    public static func clear(group: String = appGroup) {
        guard let dir = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group) else {
            return
        }
        try? FileManager.default.removeItem(at: dir.appending(path: filename))
    }

    // MARK: - Private

    private static func encoder() -> JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }

    private static func readAll(from url: URL) throws -> [Entry] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([Entry].self, from: data)
    }
}
