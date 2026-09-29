import Foundation
import Yams

struct WorkFile: Decodable, Sendable {
    let slug: Text
    let language: Text
    let title: Text
    let reading: WorkReading
    let sections: [WorkSection]
}

struct WorkReading: Decodable {
    let untouchedBelow: Fraction
    let begunBelow: Fraction
    let mostBelow: Fraction
    let difficultWordScore: WholeNumber
    let free: [Text]

    private enum CodingKeys: String, CodingKey {
        case untouchedBelow = "untouched_below"
        case begunBelow = "begun_below"
        case mostBelow = "most_below"
        case difficultWordScore = "difficult_word_score"
        case free
    }
}

struct WorkSection: Decodable {
    let title: Text
    let short: String?
    let summary: String?
    let sections: [Self]?
    let pieces: [WorkPiece]?
}

struct WorkPiece: Decodable {
    let id: Text
    let title: Text
    let lines: [Text]
    let cuts: [String: [WholeNumber]]?
}

extension WorkCorpus {
    /// A work-file piece identifier is not an integer.
    public enum WorkError: LocalizedError, Equatable {
        /// A piece or free-piece identifier is not a number written as a work writes
        /// one: plain decimal digits that fit in 32 bits, as ``Work`` describes.
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
    /// - Throws: `DecodingError` when the document is not YAML, or a field is missing or
    ///   is not text where text belongs; ``WorkError`` when a piece or free-piece
    ///   identifier is not a whole number within 32 bits; ``WorkShapeError`` when a
    ///   number is not a YAML integer within 32 bits, a fraction is not written in plain
    ///   digits, a text is null, a key is repeated, a value is written with a YAML
    ///   anchor, alias or merge key, a piece's cuts do not divide its lines, or the
    ///   parts, free pieces, thresholds or language are not shaped as a work's must be;
    ///   ``CorpusError`` when the pieces are not numbered from one in order.
    public static func decodeWork(_ yaml: String) throws -> Work {
        let work = try assembleWork(yaml)
        try validate(work.pieces)
        try validateConfiguration(work)
        return work
    }

    static func assembleWork(_ yaml: String) throws -> Work {
        let work = try decodeYAML(WorkFile.self, from: yaml)
        var pieces: [HeldPiece] = []
        for part in parts(of: work.sections) {
            for piece in part.pieces ?? [] {
                pieces.append(
                    HeldPiece(
                        number: try numbered(piece.id.value),
                        title: piece.title.value,
                        lines: piece.lines.map(\.value),
                        partTitle: part.title.value,
                        partShort: part.short,
                        partSummary: part.summary ?? "",
                        cutSizes: piece.cuts?.mapValues { $0.map(\.value) } ?? [:]
                    )
                )
            }
        }
        return try assemble(
            language: work.language.value,
            pieces: pieces,
            reading: HeldReading(
                untouchedBelow: work.reading.untouchedBelow.value,
                begunBelow: work.reading.begunBelow.value,
                mostBelow: work.reading.mostBelow.value,
                difficultWordScore: work.reading.difficultWordScore.value,
                free: try work.reading.free.map { try numbered($0.value) }
            )
        )
    }

    private static func numbered(_ id: String) throws -> Int {
        guard WholeNumber.isPlainDecimal(id), let number = Int32(id) else {
            throw WorkError.pieceIsNotNumbered(id)
        }
        return Int(number)
    }

    private static func parts(of sections: [WorkSection]) -> [WorkSection] {
        sections.flatMap { section in
            section.pieces?.isEmpty == false ? [section] : parts(of: section.sections ?? [])
        }
    }
}
