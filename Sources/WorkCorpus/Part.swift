import Foundation

/// A run of pieces a work is divided into: a group of sonnets, a chapter, an act.
public struct Part: Decodable, Identifiable, Sendable, Equatable {
    public let title: String
    public let summary: String
    public let first: Int
    public let last: Int
    private let short: String?

    public var shortTitle: String { short ?? title }

    public var pieces: ClosedRange<Int> { first...last }

    public var id: Int { first }

    public func contains(piece: Int) -> Bool { pieces.contains(piece) }

    public init(title: String, summary: String, first: Int, last: Int, short: String? = nil) {
        self.title = title
        self.summary = summary
        self.first = first
        self.last = last
        self.short = short
    }
}

extension WorkCorpus {
    public static func part(of piece: Int, in parts: [Part]) -> Part? {
        parts.first { $0.contains(piece: piece) }
    }
}
