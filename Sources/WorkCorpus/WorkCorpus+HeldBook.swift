import Foundation

/// Piece and part values already held by a caller, before assembling a ``Work``.
public struct HeldPiece: Sendable {
    /// One-based piece number.
    public let number: Int
    /// Piece title.
    public let title: String
    /// Printed lines in reading order.
    public let lines: [String]
    /// Per-stage sizes of consecutive line groups.
    public let cutSizes: [String: [Int]]
    /// Full title of the containing part.
    public let partTitle: String
    /// Optional compact title of the containing part.
    public let partShort: String?
    /// Summary of the containing part.
    public let partSummary: String

    /// Creates held values for one piece.
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

/// Reading configuration already held by a caller before assembling a ``Work``.
public struct HeldReading: Sendable {
    /// Upper bound of the untouched progress band.
    public let untouchedBelow: Double
    /// Upper bound of the begun progress band.
    public let begunBelow: Double
    /// Upper bound of the mostly-complete progress band.
    public let mostBelow: Double
    /// Difficult-word score threshold.
    public let difficultWordScore: Int
    /// Upper duration, in seconds, that is still treated as an accidental tap.
    public let shortestAttemptSeconds: Double
    /// Piece numbers available without purchase.
    public let free: [Int]

    /// Creates held reading configuration.
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

    /// Assembles held values into a work and validates its complete shape.
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
