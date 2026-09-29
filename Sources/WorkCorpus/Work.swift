import Foundation
import Yams

/// A reading work and the configuration used to present it.
///
/// Decode through ``WorkCorpus/decodeWork(_:)`` or
/// ``WorkCorpus/decodeWorkFromBook(_:)`` to validate the complete work before use.
/// Decoding this type directly does not validate relationships between its fields.
public struct Work: Decodable, Sendable {
    /// Language the work is written in, as the work names it.
    ///
    /// It arrives with the work rather than being assumed, because the same reading
    /// mechanics carry works in other languages, each held to its own alphabet.
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
    enum WorkShapeError: LocalizedError, Equatable {
        case partsDoNotCoverTheWork
        case invalidFreePieces
        case invalidStageFieldScale
        case invalidDifficultWordThreshold
        case unnamedLanguage
        case cutsForUnknownStage(piece: Int, stage: String)
        case cutsForLineStage(piece: Int)
        case emptyCut(piece: Int, stage: String, size: Int)
        case cutsOverrunThePiece(piece: Int, stage: String, cut: Int, lines: Int)

        var errorDescription: String? {
            switch self {
            case .partsDoNotCoverTheWork:
                "The parts do not cover the work exactly once."

            case .invalidFreePieces:
                "The list of pieces free to read is empty, repeated, or outside the work."

            case .invalidStageFieldScale:
                "The stage field bounds are not increasing values between zero and one."

            case .invalidDifficultWordThreshold:
                "The difficult-word score threshold must be positive."

            case .unnamedLanguage:
                "The work does not name the language it is written in."

            case let .cutsForUnknownStage(piece, stage):
                "Piece \(piece) is cut for a stage called \(stage), which is not a reading stage."

            case let .cutsForLineStage(piece):
                "Piece \(piece) is cut for the line stage, which is read one line at a time."

            case let .emptyCut(piece, stage, size):
                "Piece \(piece) has a \(stage) cut of \(size) lines; a cut holds at least one."

            case let .cutsOverrunThePiece(piece, stage, cut, lines):
                "Piece \(piece) is cut at the \(stage) stage into \(cut) lines, but it has \(lines)."
            }
        }
    }

    /// Decodes an assembled book YAML document and validates the resulting work.
    public static func decodeWorkFromBook(_ yaml: String) throws -> Work {
        let work = try YAMLDecoder().decode(Work.self, from: yaml)
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

        guard !work.language.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw WorkShapeError.unnamedLanguage
        }

        for piece in work.pieces {
            try validateCuts(of: piece)
        }
    }

    private static func validateCuts(of piece: Piece) throws {
        for (label, sizes) in piece.cutSizes.sorted(by: { $0.key < $1.key }) {
            guard let stage = ReadingStage.allCases.first(where: { $0.label == label }) else {
                throw WorkShapeError.cutsForUnknownStage(piece: piece.number, stage: label)
            }
            guard stage != .line else {
                throw WorkShapeError.cutsForLineStage(piece: piece.number)
            }
            if let empty = sizes.first(where: { $0 <= 0 }) {
                throw WorkShapeError.emptyCut(piece: piece.number, stage: label, size: empty)
            }
            let cut = sizes.reduce(0, +)
            guard cut <= piece.lines.count else {
                throw WorkShapeError.cutsOverrunThePiece(
                    piece: piece.number,
                    stage: label,
                    cut: cut,
                    lines: piece.lines.count
                )
            }
        }
    }
}
