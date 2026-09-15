import Foundation
import Yams

public struct SonnetBook: Decodable, Sendable {
    public let sonnets: [Sonnet]
    public let groups: [SonnetGroup]
    public let free: [Int]
    public let stageField: StageFieldScale
    public let difficultWords: DifficultWordsConfiguration
    public let listening: ListeningThresholds

    private enum CodingKeys: String, CodingKey {
        case sonnets
        case groups
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

extension SonnetCorpus {
    enum BookError: LocalizedError, Equatable {
        case groupsDoNotPartitionBook
        case invalidFreeSonnets
        case invalidStageFieldScale
        case invalidDifficultWordThreshold
        case invalidListeningThresholds

        var errorDescription: String? {
            switch self {
            case .groupsDoNotPartitionBook:
                "The sonnet groups do not cover the book exactly once."
            case .invalidFreeSonnets:
                "The free sonnet list is empty, repeated, or outside the book."
            case .invalidStageFieldScale:
                "The stage field bounds are not increasing values between zero and one."
            case .invalidDifficultWordThreshold:
                "The difficult-word score threshold must be positive."
            case .invalidListeningThresholds:
                "The shortest attempt must be a positive number of seconds, shorter than a line."
            }
        }
    }

    public static func decodeBook(_ yaml: String) throws -> SonnetBook {
        let book = try YAMLDecoder().decode(SonnetBook.self, from: yaml)
        try validate(book.sonnets)
        try validateConfiguration(book)
        return book
    }

    static func validateConfiguration(_ book: SonnetBook) throws {
        var next = 1
        for group in book.groups {
            guard group.first == next, group.last >= group.first else {
                throw BookError.groupsDoNotPartitionBook
            }
            next = group.last + 1
        }
        guard next == count + 1 else { throw BookError.groupsDoNotPartitionBook }

        let free = Set(book.free)
        guard !free.isEmpty, free.count == book.free.count, free.allSatisfy((1...count).contains) else {
            throw BookError.invalidFreeSonnets
        }

        let scale = book.stageField
        guard 0 < scale.untouchedBelow,
              scale.untouchedBelow < scale.begunBelow,
              scale.begunBelow < scale.mostBelow,
              scale.mostBelow <= 1
        else { throw BookError.invalidStageFieldScale }

        guard book.difficultWords.scoreThreshold > 0 else {
            throw BookError.invalidDifficultWordThreshold
        }

        let shorterThanAnyLine = 2.0
        guard 0 < book.listening.shortestAttemptSeconds,
              book.listening.shortestAttemptSeconds < shorterThanAnyLine
        else {
            throw BookError.invalidListeningThresholds
        }
    }
}
