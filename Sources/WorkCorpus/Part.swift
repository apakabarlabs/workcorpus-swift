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

    private enum CodingKeys: String, CodingKey {
        case title
        case summary
        case first
        case last
        case short
    }

    /// Creates one consecutive part without validating it against a work.
    ///
    /// - Throws: ``WorkCorpus/WorkShapeError/partOutOfRange(first:last:)`` when the part
    ///   does not start at piece one or later, ends before it starts, or does not fit in
    ///   32 bits.
    public init(
        title: String,
        summary: String,
        first: Int,
        last: Int,
        short: String? = nil
    ) throws {
        guard first >= 1, last >= first, WorkCorpus.fitsIn32Bits(last) else {
            throw WorkCorpus.WorkShapeError.partOutOfRange(first: first, last: last)
        }
        self.title = title
        self.summary = summary
        self.first = first
        self.last = last
        self.short = short
    }

    /// Decodes a part.
    ///
    /// - Throws: `DecodingError` when a field is missing or is not text where text
    ///   belongs; ``WorkCorpus/WorkShapeError`` naming the field when `first` or `last`
    ///   is not a YAML integer within 32 bits, or when the part is not a range of pieces.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            title: try values.decode(String.self, forKey: .title),
            summary: try values.decode(String.self, forKey: .summary),
            first: try values.decode(WholeNumber.self, forKey: .first).value,
            last: try values.decode(WholeNumber.self, forKey: .last).value,
            short: try values.decodeIfPresent(String.self, forKey: .short)
        )
    }
}

extension WorkCorpus {
    /// Returns the part containing `piece`, or `nil` when no part covers it.
    public static func part(of piece: Int, in parts: [Part]) -> Part? {
        parts.first { $0.contains(piece: piece) }
    }
}
