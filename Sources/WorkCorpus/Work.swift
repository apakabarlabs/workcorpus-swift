import Foundation
import Yams

/// A reading work and the configuration used to present it.
///
/// Decode through ``WorkCorpus/decodeWork(_:)`` or
/// ``WorkCorpus/decodeWorkFromBook(_:)`` to validate the complete work before use.
/// Decoding this type directly does not validate relationships between its fields.
public struct Work: Decodable, Sendable {
    /// Language the work is written in, as the work names it: a language tag such as
    /// `en`, `eng` or `en-GB`.
    ///
    /// It arrives with the work rather than being assumed, because the same reading
    /// mechanics carry works in other languages.
    public let language: String
    /// Reading pieces, expected to be numbered from one and ordered by number.
    public let pieces: [Piece]
    /// Parts, expected to cover the pieces consecutively and exactly once.
    public let parts: [Part]
    /// Piece numbers intended to be available without purchase.
    public let free: [Int]
    /// Thresholds used to display stage progress.
    public let stageField: StageFieldScale
    /// Threshold used to identify difficult words.
    public let difficultWords: DifficultWordsConfiguration

    private enum CodingKeys: String, CodingKey {
        case language
        case pieces
        case parts
        case free
        case stageField = "stage_field"
        case difficultWords = "difficult_words"
    }
}

/// Configuration for classifying repeatedly missed words.
public struct DifficultWordsConfiguration: Decodable, Sendable {
    /// Minimum accumulated score at which a word is difficult.
    public let scoreThreshold: Int

    private enum CodingKeys: String, CodingKey {
        case scoreThreshold = "score_threshold"
    }

    /// Creates a threshold without validating it against a work.
    public init(scoreThreshold: Int) {
        self.scoreThreshold = scoreThreshold
    }
}

extension WorkCorpus {
    /// The work, or one of its pieces, is not shaped the way a work has to be.
    public enum WorkShapeError: LocalizedError, Equatable {
        /// The parts leave a gap, overlap, or stop short of the last piece.
        case partsDoNotCoverTheWork
        /// The free pieces are empty, repeated, or outside the work.
        case invalidFreePieces
        /// The stage field bounds are not increasing values between zero and one.
        case invalidStageFieldScale
        /// The difficult-word score threshold is not positive.
        case invalidDifficultWordThreshold
        /// The language the work names is not a language tag.
        case invalidLanguage(String)
        /// A piece is cut for a stage that does not exist.
        case cutsForUnknownStage(piece: Int, stage: String)
        /// A piece is cut for the line stage, which is never cut.
        case cutsForLineStage(piece: Int)
        /// A piece has a cut of zero or fewer lines at a stage.
        case emptyCut(piece: Int, stage: String, size: Int)
        /// The cuts of a stage add up to more or fewer lines than the piece has.
        case cutsDoNotCoverThePiece(piece: Int, stage: String, cut: Int, lines: Int)

        /// Reader-facing description naming what is wrong and where.
        public var errorDescription: String? {
            switch self {
            case .partsDoNotCoverTheWork:
                "The parts do not cover the work exactly once."

            case .invalidFreePieces:
                "The list of pieces free to read is empty, repeated, or outside the work."

            case .invalidStageFieldScale:
                "The stage field bounds are not increasing values between zero and one."

            case .invalidDifficultWordThreshold:
                "The difficult-word score threshold must be positive."

            case let .invalidLanguage(value):
                "The work names its language as \"\(Self.shown(value))\", "
                    + "which is not a language tag such as en, eng or en-GB."

            case let .cutsForUnknownStage(piece, stage):
                "Piece \(piece) is cut for a stage called \(stage), which is not a reading stage."

            case let .cutsForLineStage(piece):
                "Piece \(piece) is cut for the line stage, which is read one line at a time."

            case let .emptyCut(piece, stage, size):
                "Piece \(piece) has a \(stage) cut of \(size) lines; a cut holds at least one."

            case let .cutsDoNotCoverThePiece(piece, stage, cut, lines):
                "Piece \(piece) is cut at the \(stage) stage into \(cut) lines, but it has \(lines)."
            }
        }

        private static func shown(_ value: String) -> String {
            value.unicodeScalars.map { scalar in
                (0x20...0x7E).contains(scalar.value) && scalar != "\"" && scalar != "\\"
                    ? String(scalar) : "\\u{\(String(scalar.value, radix: 16, uppercase: true))}"
            }.joined()
        }
    }

    /// Decodes an assembled book YAML document and validates the resulting work.
    ///
    /// - Throws: `DecodingError` when the document is not a book; ``WorkShapeError``
    ///   when a piece's cuts do not divide its lines, or the parts, free pieces,
    ///   thresholds or language are not shaped as a work's must be;
    ///   ``CorpusError`` when the pieces are not numbered from one in order.
    public static func decodeWorkFromBook(_ yaml: String) throws -> Work {
        let work: Work
        do {
            work = try YAMLDecoder().decode(Work.self, from: yaml)
        } catch DecodingError.dataCorrupted(let context) {
            if let shape = context.underlyingError as? WorkShapeError { throw shape }
            throw DecodingError.dataCorrupted(context)
        }
        try validate(work.pieces)
        try validateConfiguration(work)
        return work
    }

    static func validateConfiguration(_ work: Work) throws {
        var next = 1
        for part in work.parts {
            guard part.first == next, part.last >= part.first else {
                throw WorkShapeError.partsDoNotCoverTheWork
            }
            next = part.last + 1
        }
        guard next == work.pieces.count + 1 else { throw WorkShapeError.partsDoNotCoverTheWork }

        let free = Set(work.free)
        let numbered = 1...max(work.pieces.count, 1)
        guard !free.isEmpty, free.count == work.free.count, free.allSatisfy(numbered.contains)
        else {
            throw WorkShapeError.invalidFreePieces
        }

        let scale = work.stageField
        guard scale.untouchedBelow > 0,
            scale.untouchedBelow < scale.begunBelow,
            scale.begunBelow < scale.mostBelow,
            scale.mostBelow <= 1
        else { throw WorkShapeError.invalidStageFieldScale }

        guard work.difficultWords.scoreThreshold > 0 else {
            throw WorkShapeError.invalidDifficultWordThreshold
        }

        guard isLanguageTag(work.language) else {
            throw WorkShapeError.invalidLanguage(work.language)
        }
    }

    private static func isLanguageTag(_ value: String) -> Bool {
        let subtags = Array(value.unicodeScalars).split(
            separator: "-",
            omittingEmptySubsequences: false
        )
        guard let language = subtags.first, (2...3).contains(language.count),
            language.allSatisfy({ ("a"..."z").contains($0) })
        else {
            return false
        }
        return subtags.dropFirst().allSatisfy { subtag in
            (2...8).contains(subtag.count)
                && subtag.allSatisfy {
                    ("a"..."z").contains($0) || ("A"..."Z").contains($0) || ("0"..."9").contains($0)
                }
        }
    }

    static func validateCuts(piece: Int, lines: Int, cutSizes: [String: [Int]]) throws {
        let labels = cutSizes.sorted {
            $0.key.unicodeScalars.lexicographicallyPrecedes($1.key.unicodeScalars)
        }
        for (label, sizes) in labels {
            guard let stage = ReadingStage.allCases.first(where: { $0.label == label }) else {
                throw WorkShapeError.cutsForUnknownStage(piece: piece, stage: label)
            }
            guard stage != .line else {
                throw WorkShapeError.cutsForLineStage(piece: piece)
            }
            if let empty = sizes.first(where: { $0 <= 0 }) {
                throw WorkShapeError.emptyCut(piece: piece, stage: label, size: empty)
            }
            let cut = sizes.reduce(0) { total, size in
                let (sum, overflow) = total.addingReportingOverflow(size)
                return overflow ? Int.max : sum
            }
            guard cut == lines else {
                throw WorkShapeError.cutsDoNotCoverThePiece(
                    piece: piece,
                    stage: label,
                    cut: cut,
                    lines: lines
                )
            }
        }
    }
}
