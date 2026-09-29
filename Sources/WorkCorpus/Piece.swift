import Foundation
import ReadAloudKit

/// What a reader reads in one sitting: a sonnet, a stanza, a scene.
public struct Piece: Decodable, Identifiable, Sendable, Equatable {
    /// One-based position of the piece in its work.
    public let number: Int
    /// Reader-facing title.
    public let title: String
    /// Printed lines in reading order.
    public let lines: [String]
    /// Per-stage sizes of consecutive line groups.
    public let cutSizes: [String: [Int]]

    /// Stable identity, equal to the piece number.
    public var id: Int { number }

    /// First printed line, or an empty string when the piece has no lines.
    public var openingLine: String { lines.first ?? "" }

    /// Printed lines as a ReadAloudKit passage.
    public var passage: Passage { Passage(lines: lines) }

    private enum CodingKeys: String, CodingKey {
        case number
        case title
        case lines
        case cutSizes = "cuts"
    }

    /// Creates a piece, refusing cuts that do not divide its lines.
    ///
    /// Each stage named in `cutSizes` has to be a reading stage other than
    /// ``ReadingStage/line``, and its sizes have to be positive and add up to exactly
    /// the number of lines. The number is not validated against a work.
    ///
    /// - Throws: ``WorkCorpus/WorkShapeError`` naming the piece and the stage when
    ///   the cuts do not divide the lines.
    public init(
        number: Int,
        title: String,
        lines: [String],
        cutSizes: [String: [Int]] = [:]
    ) throws {
        try WorkCorpus.validateCuts(piece: number, lines: lines.count, cutSizes: cutSizes)
        self.number = number
        self.title = title
        self.lines = lines
        self.cutSizes = cutSizes
    }

    /// Decodes a piece, treating an omitted or null `cuts` mapping as empty and refusing
    /// cuts that do not divide its lines.
    ///
    /// - Throws: `DecodingError` when a field is missing or of the wrong kind;
    ///   ``WorkCorpus/WorkShapeError`` naming the piece and the stage when the cuts do
    ///   not divide the lines.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let cuts = try values.decodeIfPresent([String: [CutSize]].self, forKey: .cutSizes)
        try self.init(
            number: try values.decode(Int.self, forKey: .number),
            title: try values.decode(String.self, forKey: .title),
            lines: try values.decode([String].self, forKey: .lines),
            cutSizes: cuts?.mapValues { $0.map(\.value) } ?? [:]
        )
    }
}

struct CutSize: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard let text = try? container.decode(String.self) else {
            value = try container.decode(Int.self)
            return
        }
        guard let value = Self.saturated(text) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "A cut size of \(text) is not a whole number of lines."
            )
        }
        self.value = value
    }

    static func saturated(_ text: String) -> Int? {
        var scalars = text.unicodeScalars[...]
        let negative = scalars.first == "-"
        if negative || scalars.first == "+" { scalars = scalars.dropFirst() }
        guard !scalars.isEmpty, scalars.allSatisfy({ ("0"..."9").contains($0) }) else {
            return nil
        }
        var magnitude = 0
        for scalar in scalars {
            let digit = Int(scalar.value - 0x30)
            let (tens, tensOverflow) = magnitude.multipliedReportingOverflow(by: 10)
            let (sum, sumOverflow) = tens.addingReportingOverflow(digit)
            guard !tensOverflow, !sumOverflow else { return negative ? Int.min : Int.max }
            magnitude = sum
        }
        return negative ? -magnitude : magnitude
    }
}

/// Decodes, assembles, and validates portable reading works.
public enum WorkCorpus {
    /// Piece numbering does not form the required sequence beginning at one.
    public enum CorpusError: LocalizedError, Equatable {
        /// The piece at one position carries another number.
        case outOfOrder(expected: Int, found: Int)

        /// Reader-facing description of the numbering error.
        public var errorDescription: String? {
            switch self {
            case let .outOfOrder(expected, found):
                return "Expected piece \(expected), found \(found)."
            }
        }
    }

    /// The pieces of a work are numbered from one and read in that order, which is what
    /// a reader's place in the work is counted by. What each piece holds is the work's
    /// own business and is read from its file, not decided here.
    public static func validate(_ pieces: [Piece]) throws {
        for (index, piece) in pieces.enumerated() {
            let expected = index + 1
            guard piece.number == expected else {
                throw CorpusError.outOfOrder(expected: expected, found: piece.number)
            }
        }
    }
}
