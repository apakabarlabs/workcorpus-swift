import Foundation
import Yams

/// A reading work and the configuration used to present it.
///
/// Decode through ``WorkCorpus/decodeWork(_:)`` or
/// ``WorkCorpus/decodeWorkFromBook(_:)`` to validate the complete work before use.
/// Decoding this type directly does not validate relationships between its fields.
public struct Work: Decodable, Sendable {
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
    /// Time limits used while listening to attempts.
    public let listening: ListeningThresholds

    private enum CodingKeys: String, CodingKey {
        case pieces
        case parts
        case free
        case stageField = "stage_field"
        case difficultWords = "difficult_words"
        case listening
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
        case invalidListeningThresholds

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

            case .invalidListeningThresholds:
                "The shortest attempt must be a positive number of seconds, shorter than a line."
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

        let shorterThanAnyLine = 2.0
        guard work.listening.shortestAttemptSeconds > 0,
            work.listening.shortestAttemptSeconds < shorterThanAnyLine
        else {
            throw WorkShapeError.invalidListeningThresholds
        }
    }
}
