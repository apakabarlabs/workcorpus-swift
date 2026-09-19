import Foundation

/// A run of pieces a work is divided into: a group of sonnets, a chapter, an act.
public struct Part: Decodable, Identifiable, Sendable, Equatable {
    /// Full title shown when the part is introduced.
    public let title: String
    /// Reader-facing account of what the part contains.
    public let summary: String
    /// Number of the first piece in the part.
    public let first: Int
    /// Number of the last piece in the part.
    public let last: Int
    private let short: String?

    /// Compact title when one was supplied, otherwise ``title``.
    public var shortTitle: String { short ?? title }

    /// Inclusive piece-number range occupied by the part.
    public var pieces: ClosedRange<Int> { first...last }

    /// Stable identity, equal to the first piece number.
    public var id: Int { first }

    /// Reports whether a numbered piece belongs to the part.
    public func contains(piece: Int) -> Bool { pieces.contains(piece) }

    /// Creates one consecutive part without validating it against a work.
    public init(title: String, summary: String, first: Int, last: Int, short: String? = nil) {
        self.title = title
        self.summary = summary
        self.first = first
        self.last = last
        self.short = short
    }
}

extension WorkCorpus {
    /// Returns the part containing `piece`, or `nil` when no part covers it.
    public static func part(of piece: Int, in parts: [Part]) -> Part? {
        parts.first { $0.contains(piece: piece) }
    }
}
