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
    ///   the cuts do not divide the lines, or naming the piece when its number or a cut
    ///   size does not fit in 32 bits.
    public init(
        number: Int,
        title: String,
        lines: [String],
        cutSizes: [String: [Int]] = [:]
    ) throws {
        guard WorkCorpus.fitsIn32Bits(number) else {
            throw WorkCorpus.WorkShapeError.invalidNumber(place: "piece \(number)")
        }
        try WorkCorpus.validateCuts(piece: number, lines: lines.count, cutSizes: cutSizes)
        self.number = number
        self.title = title
        self.lines = lines
        self.cutSizes = cutSizes
    }

    /// Decodes a piece, treating an omitted or null `cuts` mapping as empty and refusing
    /// cuts that do not divide its lines.
    ///
    /// - Throws: `DecodingError` when a field is missing or is not text where text
    ///   belongs; ``WorkCorpus/WorkShapeError`` naming the field when the number or a
    ///   cut size is not a YAML integer within 32 bits, or naming the piece and the stage
    ///   when the cuts do not divide the lines.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let cuts = try values.decodeIfPresent([String: [WholeNumber]].self, forKey: .cutSizes)
        try self.init(
            number: try values.decode(WholeNumber.self, forKey: .number).value,
            title: try values.decode(String.self, forKey: .title),
            lines: try values.decode([String].self, forKey: .lines),
            cutSizes: cuts?.mapValues { $0.map(\.value) } ?? [:]
        )
    }
}

struct WholeNumber: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        do {
            value = Int(try decoder.singleValueContainer().decode(Int32.self))
        } catch {
            let place = WorkCorpus.place(decoder.codingPath)
            throw WorkCorpus.WorkShapeError.invalidNumber(place: place)
        }
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
