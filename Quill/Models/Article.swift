import Foundation
import SwiftData

/// A saved-for-later article. Mirrors Tack's `TaskItem` architecture but
/// scoped to a URL + metadata + content snapshot.
@Model
public final class Article {
    @Attribute(.unique) public var id: UUID
    public var url: String
    public var title: String
    public var summary: String
    public var imageURL: String?
    public var siteName: String
    public var createdAt: Date
    public var readAt: Date?
    public var archivedAt: Date?
    public var order: Int

    /// Status enum stored as String for forward compatibility.
    public var statusRaw: String

    /// Origin: local | web | share | menu
    public var origin: String
    public var lastSyncedAt: Date?

    /// Remote ID when mirrored to Obsidian. For Obsidian this is the
    /// relative path within the vault: `quill/articles/<slug>.md`.
    public var remoteID: String?

    @Relationship(deleteRule: .nullify, inverse: \Folder.articles)
    public var folder: Folder?

    @Relationship(inverse: \Tag.articles)
    public var tags: [Tag] = []

    @Relationship(deleteRule: .cascade)
    public var highlights: [Highlight] = []

    public var status: ArticleStatus {
        get { ArticleStatus(rawValue: statusRaw) ?? .inbox }
        set { statusRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        url: String,
        title: String,
        summary: String = "",
        imageURL: String? = nil,
        siteName: String = "",
        folder: Folder? = nil,
        status: ArticleStatus = .inbox,
        origin: String = Origin.local
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.summary = summary
        self.imageURL = imageURL
        self.siteName = siteName
        self.createdAt = .now
        self.readAt = nil
        self.archivedAt = nil
        self.order = 0
        self.statusRaw = status.rawValue
        self.origin = origin
        self.lastSyncedAt = nil
        self.remoteID = nil
        self.folder = folder
    }

    public enum Origin {
        public static let local = "local"
        public static let web   = "web"
        public static let share = "share"
        public static let menu  = "menu"
    }

    public var isRead: Bool   { status == .read }
    public var isArchived: Bool { status == .archived }
}

public enum ArticleStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case inbox
    case read
    case archived

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .inbox:   return "Inbox"
        case .read:    return "Read"
        case .archived: return "Archived"
        }
    }

    public var sfSymbol: String {
        switch self {
        case .inbox:   return "tray.fill"
        case .read:    return "checkmark.seal.fill"
        case .archived: return "archivebox.fill"
        }
    }
}
