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
    func refusesInvalidDifficultWordThreshold() throws {
        let work = try work(threshold: 0)

        #expect(throws: WorkCorpus.WorkShapeError.invalidDifficultWordThreshold) {
            try WorkCorpus.validateConfiguration(work)
        }
    }

    @Test("parts have to cover the whole work")
    func refusesGapBetweenParts() throws {
        let parts = [
            Part(title: "First", summary: "", first: 1, last: 10),
            Part(title: "Second", summary: "", first: 12, last: 20)
        ]
        let work = try work(parts: parts)

        #expect(throws: WorkCorpus.WorkShapeError.partsDoNotCoverTheWork) {
            try WorkCorpus.validateConfiguration(work)
        }
    }

    @Test("the pieces free to read have to be unique members of the work")
    func refusesInvalidFreePieces() throws {
        let work = try work(free: [1, 1])

        #expect(throws: WorkCorpus.WorkShapeError.invalidFreePieces) {
            try WorkCorpus.validateConfiguration(work)
        }
    }

    @Test("a book carries the language it names")
    func bookLanguage() throws {
        let book = try fixture("book-with-listening")

        #expect(try WorkCorpus.decodeWorkFromBook(book).language == "eng")
    }

    @Test("a book that does not name its language is refused, and says so")
    func bookWithoutLanguage() throws {
        let book = try fixture("book-with-listening").replacingOccurrences(
            of: "language: eng\n",
            with: ""
        )

        #expect(book != (try fixture("book-with-listening")))
        let error = #expect(throws: DecodingError.self) {
            try WorkCorpus.decodeWorkFromBook(book)
        }
        #expect(String(describing: error).contains("language"))
    }

    @Test("a book whose piece is cut short of its lines is refused, naming piece and stage")
    func bookWithShortCuts() throws {
        let book = try fixture("book-with-listening").replacingOccurrences(
            of: "    lines: [The first line.]\n",
            with: "    lines: [The first line., The second line.]\n    cuts:\n      block: [1]\n"
        )

        #expect(book != (try fixture("book-with-listening")))
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 1,
                lines: 2
            )
        ) {
            try WorkCorpus.decodeWorkFromBook(book)
        }
    }

    @Test("a work has to name its language")
    func refusesBlankLanguage() throws {
        let work = try work(language: "")

        #expect(throws: WorkCorpus.WorkShapeError.unnamedLanguage) {
            try WorkCorpus.validateConfiguration(work)
        }
    }

    private func work(
        language: String = "eng",
        threshold: Int = 3,
        parts: [Part]? = nil,
        free: [Int] = [1]
    ) throws -> Work {
        let pieces = try (1...20).map { number in
            try Piece(number: number, title: "Piece \(number)", lines: ["A line of verse,"])
        }
        return Work(
            language: language,
            pieces: pieces,
            parts: parts ?? [Part(title: "The work", summary: "", first: 1, last: pieces.count)],
            free: free,
            stageField: StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: threshold)
        )
    }
}
