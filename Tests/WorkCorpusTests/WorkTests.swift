import Testing

@testable import WorkCorpus

struct WorkTests {
    @Test("configuration is validated from the YAML model itself")
    func acceptsConfiguration() throws {
        try WorkCorpus.validateConfiguration(work())
    }

    @Test("a book that still carries listening limits is read as before")
    func olderBook() throws {
        let book = try fixture("book-with-listening")

        #expect(try WorkCorpus.decodeWorkFromBook(book).pieces.map(\.title) == ["First poem"])
    }

    @Test(
        "a book is read whatever it says about listening, or without it",
        arguments: [
            "listening:\n  shortest_attempt_seconds: 0\n",
            "listening:\n  shortest_attempt_seconds: 200\n",
            "listening: {}\n",
            "listening: quick\n",
            ""
        ]
    )
    func listeningIsIgnored(listening: String) throws {
        let book = try fixture("book-with-listening").replacingOccurrences(
            of: "listening:\n  shortest_attempt_seconds: 0.2\n",
            with: listening
        )

        #expect(book.hasSuffix("score_threshold: 3\n\(listening)"))
        #expect(try WorkCorpus.decodeWorkFromBook(book).pieces.map(\.title) == ["First poem"])
    }

    @Test("difficult words need a positive score threshold")
    func refusesInvalidDifficultWordThreshold() {
        #expect(throws: WorkCorpus.WorkShapeError.invalidDifficultWordThreshold) {
            try WorkCorpus.validateConfiguration(work(threshold: 0))
        }
    }

    @Test("parts have to cover the whole work")
    func refusesGapBetweenParts() {
        let parts = [
            Part(title: "First", summary: "", first: 1, last: 10),
            Part(title: "Second", summary: "", first: 12, last: 20)
        ]
        #expect(throws: WorkCorpus.WorkShapeError.partsDoNotCoverTheWork) {
            try WorkCorpus.validateConfiguration(work(parts: parts))
        }
    }

    @Test("the pieces free to read have to be unique members of the work")
    func refusesInvalidFreePieces() {
        #expect(throws: WorkCorpus.WorkShapeError.invalidFreePieces) {
            try WorkCorpus.validateConfiguration(work(free: [1, 1]))
        }
    }

    private func work(
        threshold: Int = 3,
        parts: [Part]? = nil,
        free: [Int] = [1]
    ) -> Work {
        let pieces = (1...20).map { number in
            Piece(number: number, title: "Piece \(number)", lines: ["A line of verse,"])
        }
        return Work(
            pieces: pieces,
            parts: parts ?? [Part(title: "The work", summary: "", first: 1, last: pieces.count)],
            free: free,
            stageField: StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: threshold)
        )
    }
}
