import Foundation
import Yams

struct WorkFile: Decodable, Sendable {
    let slug: String
    let language: String
    let title: String
    let reading: WorkReading
    let sections: [WorkSection]
}

struct WorkReading: Decodable {
    let untouchedBelow: Double
    let begunBelow: Double
    let mostBelow: Double
    let difficultWordScore: Int
    let free: [String]

    private enum CodingKeys: String, CodingKey {
        case untouchedBelow = "untouched_below"
        case begunBelow = "begun_below"
        case mostBelow = "most_below"
        case difficultWordScore = "difficult_word_score"
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
    let cuts: [String: [CutSize]]?
}

extension WorkCorpus {
    /// A work-file piece identifier is not an integer.
    public enum WorkError: LocalizedError, Equatable {
        /// A piece or free-piece identifier cannot be converted to its number.
        case pieceIsNotNumbered(String)

        /// Reader-facing description of the invalid identifier.
        public var errorDescription: String? {
            switch self {
            case .pieceIsNotNumbered(let id):
                "The work calls a piece \(id), which is not a number."
            }
        }
    }

    /// Decodes a nested work-file YAML document and validates the resulting work.
    ///
    /// - Throws: `DecodingError` when the document is not a work file;
    ///   ``WorkError`` when a piece or free-piece identifier is not a number;
    ///   ``WorkShapeError`` when a piece's cuts do not divide its lines, or the parts,
    ///   free pieces, thresholds or language are not shaped as a work's must be;
    ///   ``CorpusError`` when the pieces are not numbered from one in order.
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
                        cutSizes: piece.cuts?.mapValues { $0.map(\.value) } ?? [:]
                    )
                )
            }
        }
        return try assemble(
            language: work.language,
            pieces: pieces,
            reading: HeldReading(
                untouchedBelow: work.reading.untouchedBelow,
                begunBelow: work.reading.begunBelow,
                mostBelow: work.reading.mostBelow,
                difficultWordScore: work.reading.difficultWordScore,
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
