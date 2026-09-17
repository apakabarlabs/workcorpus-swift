import Foundation
import Yams

struct WorkFile: Decodable, Sendable {
    let slug: String
    let title: String
    let reading: WorkReading
    let sections: [WorkSection]
}

struct WorkReading: Decodable {
    let untouchedBelow: Double
    let begunBelow: Double
    let mostBelow: Double
    let difficultWordScore: Int
    let shortestAttemptSeconds: Double
    let free: [String]

    private enum CodingKeys: String, CodingKey {
        case untouchedBelow = "untouched_below"
        case begunBelow = "begun_below"
        case mostBelow = "most_below"
        case difficultWordScore = "difficult_word_score"
        case shortestAttemptSeconds = "shortest_attempt_seconds"
        case free
    }
}

struct WorkSection: Decodable {
    let title: String
    let short: String?
    let summary: String?
    let sections: [Self]?
    let pieces: [WorkPiece]?
}

struct WorkPiece: Decodable {
    let id: String
    let title: String
    let lines: [String]
    let cuts: [String: [Int]]?
}

extension WorkCorpus {
    public enum WorkError: LocalizedError, Equatable {
        case pieceIsNotNumbered(String)

        public var errorDescription: String? {
            switch self {
            case .pieceIsNotNumbered(let id):
                "The work calls a piece \(id), which is not a number."
            }
        }
    }

    public static func decodeWork(_ yaml: String) throws -> Work {
        let work = try assembleWork(yaml)
        try validate(work.pieces)
        try validateConfiguration(work)
        return work
    }

    static func assembleWork(_ yaml: String) throws -> Work {
        let work = try YAMLDecoder().decode(WorkFile.self, from: yaml)
        var pieces: [HeldPiece] = []
        for part in parts(of: work.sections) {
            for piece in part.pieces ?? [] {
                guard let number = Int(piece.id) else {
                    throw WorkError.pieceIsNotNumbered(piece.id)
                }
                pieces.append(
                    HeldPiece(
                        number: number,
                        title: piece.title,
                        lines: piece.lines,
                        partTitle: part.title,
                        partShort: part.short,
                        partSummary: part.summary ?? "",
                        cutSizes: piece.cuts ?? [:]
                    )
                )
            }
        }
        return assemble(
            pieces: pieces,
            reading: HeldReading(
                untouchedBelow: work.reading.untouchedBelow,
                begunBelow: work.reading.begunBelow,
                mostBelow: work.reading.mostBelow,
                difficultWordScore: work.reading.difficultWordScore,
                shortestAttemptSeconds: work.reading.shortestAttemptSeconds,
                free: try work.reading.free.map { number in
                    guard let free = Int(number) else { throw WorkError.pieceIsNotNumbered(number) }
                    return free
                }
            )
        )
    }

    private static func parts(of sections: [WorkSection]) -> [WorkSection] {
        sections.flatMap { section in
            section.pieces?.isEmpty == false ? [section] : parts(of: section.sections ?? [])
        }
    }
}
