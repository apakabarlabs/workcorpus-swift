import Foundation

public struct HeldPiece: Sendable {
    public let number: Int
    public let title: String
    public let lines: [String]
    public let cutSizes: [String: [Int]]
    public let partTitle: String
    public let partShort: String?
    public let partSummary: String

    public init(
        number: Int,
        title: String,
        lines: [String],
        partTitle: String,
        partShort: String?,
        partSummary: String,
        cutSizes: [String: [Int]] = [:]
    ) {
        self.number = number
        self.title = title
        self.lines = lines
        self.cutSizes = cutSizes
        self.partTitle = partTitle
        self.partShort = partShort
        self.partSummary = partSummary
    }
}

public struct HeldReading: Sendable {
    public let untouchedBelow: Double
    public let begunBelow: Double
    public let mostBelow: Double
    public let difficultWordScore: Int
    public let shortestAttemptSeconds: Double
    public let free: [Int]

    public init(
        untouchedBelow: Double,
        begunBelow: Double,
        mostBelow: Double,
        difficultWordScore: Int,
        shortestAttemptSeconds: Double,
        free: [Int]
    ) {
        self.untouchedBelow = untouchedBelow
        self.begunBelow = begunBelow
        self.mostBelow = mostBelow
        self.difficultWordScore = difficultWordScore
        self.shortestAttemptSeconds = shortestAttemptSeconds
        self.free = free
    }
}

extension WorkCorpus {
    private struct OpenPart {
        let title: String
        let short: String?
        let summary: String
        let first: Int
        var last: Int
    }

    public static func work(pieces: [HeldPiece], reading: HeldReading) throws -> Work {
        let work = assemble(pieces: pieces, reading: reading)
        try validate(work.pieces)
        try validateConfiguration(work)
        return work
    }

    static func assemble(pieces: [HeldPiece], reading: HeldReading) -> Work {
        let parts = assembleParts(pieces: pieces)
        return Work(
            pieces: pieces.map(makePiece),
            parts: parts.map(makePart),
            free: reading.free,
            stageField: StageFieldScale(
                untouchedBelow: reading.untouchedBelow,
                begunBelow: reading.begunBelow,
                mostBelow: reading.mostBelow
            ),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: reading.difficultWordScore),
            listening: ListeningThresholds(shortestAttemptSeconds: reading.shortestAttemptSeconds)
        )
    }

    private static func assembleParts(pieces: [HeldPiece]) -> [OpenPart] {
        var parts: [OpenPart] = []
        for piece in pieces {
            if var open = parts.last, open.title == piece.partTitle, open.last + 1 == piece.number {
                open.last = piece.number
                parts[parts.count - 1] = open
            } else {
                parts.append(
                    OpenPart(
                        title: piece.partTitle,
                        short: piece.partShort,
                        summary: piece.partSummary,
                        first: piece.number,
                        last: piece.number
                    )
                )
            }
        }
        return parts
    }

    private static func makePiece(_ piece: HeldPiece) -> Piece {
        Piece(
            number: piece.number,
            title: piece.title,
            lines: piece.lines,
            cutSizes: piece.cutSizes
        )
    }

    private static func makePart(_ part: OpenPart) -> Part {
        Part(
            title: part.title,
            summary: part.summary,
            first: part.first,
            last: part.last,
            short: part.short
        )
    }
}
