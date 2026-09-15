import Foundation

public struct HeldPiece: Sendable {
    public let number: Int
    public let lines: [String]
    public let partTitle: String
    public let partShort: String?
    public let partSummary: String

    public init(number: Int, lines: [String], partTitle: String, partShort: String?, partSummary: String) {
        self.number = number
        self.lines = lines
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

extension SonnetCorpus {
    public static func book(pieces: [HeldPiece], reading: HeldReading) throws -> SonnetBook {
        let book = assemble(pieces: pieces, reading: reading)
        try validate(book.sonnets)
        try validateConfiguration(book)
        return book
    }

    static func assemble(pieces: [HeldPiece], reading: HeldReading) -> SonnetBook {
        struct Part {
            let title: String
            let short: String?
            let summary: String
            let first: Int
            var last: Int
        }

        var parts: [Part] = []
        for piece in pieces {
            if var open = parts.last, open.title == piece.partTitle, open.last + 1 == piece.number {
                open.last = piece.number
                parts[parts.count - 1] = open
            } else {
                parts.append(Part(
                    title: piece.partTitle,
                    short: piece.partShort,
                    summary: piece.partSummary,
                    first: piece.number,
                    last: piece.number
                ))
            }
        }

        return SonnetBook(
            sonnets: pieces.map { Sonnet(number: $0.number, lines: $0.lines) },
            groups: parts.map {
                SonnetGroup(title: $0.title, summary: $0.summary, first: $0.first, last: $0.last, short: $0.short)
            },
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
}
