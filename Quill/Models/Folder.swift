import Foundation
import SwiftData

/// A collection of articles. Pre-seeded with `Inbox`; user can add more.
@Model
public final class Folder {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date
    public var order: Int
    public var accentHex: String?
    public var iconSF: String

    @Relationship(deleteRule: .nullify)
    public var articles: [Article] = []

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "folder",
        accent: String? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.name = name
        self.createdAt = .now
        self.order = order
        self.accentHex = accent
        self.iconSF = icon
    }

    public static let inbox = "Inbox"
    public static let read = "Read"
    public static let archived = "Archive"
}
