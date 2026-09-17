import Foundation
import Yams

public struct Work: Decodable, Sendable {
    public let pieces: [Piece]
    public let parts: [Part]
    public let free: [Int]
    public let stageField: StageFieldScale
    public let difficultWords: DifficultWordsConfiguration
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

public struct DifficultWordsConfiguration: Decodable, Sendable {
    public let scoreThreshold: Int

    private enum CodingKeys: String, CodingKey {
        case scoreThreshold = "score_threshold"
    }

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
