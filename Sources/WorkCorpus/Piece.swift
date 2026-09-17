import Foundation
import ReadAloudKit

/// What a reader reads in one sitting: a sonnet, a stanza, a scene.
public struct Piece: Decodable, Identifiable, Sendable, Equatable {
    public let number: Int
    public let title: String
    public let lines: [String]
    public let cutSizes: [String: [Int]]

    public var id: Int { number }

    public var openingLine: String { lines.first ?? "" }

    public var passage: Passage { Passage(lines: lines) }

    private enum CodingKeys: String, CodingKey {
        case number
        case title
        case lines
        case cutSizes = "cuts"
    }

    public init(number: Int, title: String, lines: [String], cutSizes: [String: [Int]] = [:]) {
        self.number = number
        self.title = title
        self.lines = lines
        self.cutSizes = cutSizes
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        number = try values.decode(Int.self, forKey: .number)
        title = try values.decode(String.self, forKey: .title)
        lines = try values.decode([String].self, forKey: .lines)
        cutSizes = try values.decodeIfPresent([String: [Int]].self, forKey: .cutSizes) ?? [:]
    }
}

public enum WorkCorpus {
    public enum CorpusError: LocalizedError, Equatable {
        case outOfOrder(expected: Int, found: Int)

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
