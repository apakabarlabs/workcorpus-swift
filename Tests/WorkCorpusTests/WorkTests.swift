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

    @Test("a work has to name its language")
    func refusesBlankLanguage() {
        #expect(throws: WorkCorpus.WorkShapeError.unnamedLanguage) {
            try WorkCorpus.validateConfiguration(work(language: ""))
        }
    }

    @Test("cuts that cover the piece exactly are accepted")
    func acceptsCutsThatCoverThePiece() throws {
        try WorkCorpus.validateConfiguration(work(cuts: ["block": [4, 4, 4, 2]]))
    }

    @Test("cuts shorter than the piece are refused rather than given a cut of the rest")
    func refusesCutsShortOfThePiece() {
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 8,
                lines: 14
            )
        ) {
            try WorkCorpus.validateConfiguration(work(cuts: ["block": [4, 4]]))
        }
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 0,
                lines: 14
            )
        ) {
            try WorkCorpus.validateConfiguration(work(cuts: ["block": []]))
        }
    }

    @Test("a stage the work says nothing about is accepted, and read line by line")
    func acceptsAnUncutStage() throws {
        let work = work()

        try WorkCorpus.validateConfiguration(work)
        #expect(work.pieces[0].cuts(for: .block).count == 14)
    }

    @Test("a cut of no lines is refused, naming the piece and the stage")
    func refusesEmptyCut() {
        #expect(throws: WorkCorpus.WorkShapeError.emptyCut(piece: 1, stage: "block", size: 0)) {
            try WorkCorpus.validateConfiguration(work(cuts: ["block": [4, 0, 4]]))
        }
        #expect(throws: WorkCorpus.WorkShapeError.emptyCut(piece: 1, stage: "block", size: -2)) {
            try WorkCorpus.validateConfiguration(work(cuts: ["block": [-2, 16]]))
        }
    }

    @Test("cuts longer than the piece are refused rather than cut short")
    func refusesOverrunningCuts() {
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 16,
                lines: 14
            )
        ) {
            try WorkCorpus.validateConfiguration(work(cuts: ["block": [4, 4, 4, 4]]))
        }
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: Int.max,
                lines: 14
            )
        ) {
            try WorkCorpus.validateConfiguration(work(cuts: ["block": [Int.max, 1]]))
        }
    }

    @Test("cuts for a stage there is no such thing as are refused rather than ignored")
    func refusesUnknownStage() {
        #expect(throws: WorkCorpus.WorkShapeError.cutsForUnknownStage(piece: 1, stage: "stanza")) {
            try WorkCorpus.validateConfiguration(work(cuts: ["stanza": [7, 7]]))
        }
    }

    @Test("cuts for the line stage are refused, since that stage is never cut")
    func refusesLineStageCuts() {
        #expect(throws: WorkCorpus.WorkShapeError.cutsForLineStage(piece: 1)) {
            try WorkCorpus.validateConfiguration(work(cuts: ["line": [2, 2]]))
        }
    }

    @Test("what is wrong with a cut is said in words that name the piece and the stage")
    func cutErrorsNameThePlace() {
        let error = WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
            piece: 99,
            stage: "block",
            cut: 16,
            lines: 15
        )

        #expect(
            error.errorDescription
                == "Piece 99 is cut at the block stage into 16 lines, but it has 15."
        )
    }

    private func work(
        language: String = "eng",
        threshold: Int = 3,
        parts: [Part]? = nil,
        free: [Int] = [1],
        cuts: [String: [Int]] = [:]
    ) -> Work {
        let first = Piece(
            number: 1,
            title: "Piece 1",
            lines: Array(repeating: "A line of verse,", count: 14),
            cutSizes: cuts
        )
        let pieces =
            [first]
            + (2...20).map { number in
                Piece(number: number, title: "Piece \(number)", lines: ["A line of verse,"])
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
