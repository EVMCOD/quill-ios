import Foundation
import SwiftData

/// A highlight within an article — the user captures a passage and
/// optionally adds their own note. Mirrors Obsidian's `> quote` syntax
/// for direct round-trip into the vault.
@Model
public final class Highlight {
    @Attribute(.unique) public var id: UUID
    public var text: String           // The quoted passage
    public var note: String           // User's commentary (optional, may be "")
    public var sourceURL: String      // URL where the highlight lives
    public var orderIndex: Int        // Position within the article
    public var createdAt: Date

    /// Reversed-bidirectional — never serialize, always derive.
    public var article: Article?

    public init(
        id: UUID = UUID(),
        text: String,
        note: String = "",
        sourceURL: String,
        article: Article? = nil,
        orderIndex: Int = 0
    ) {
        self.id = id
        self.text = text
        self.note = note
        self.sourceURL = sourceURL
        self.orderIndex = orderIndex
        self.createdAt = .now
        self.article = article
    }
}
