import Testing
import Yams

@testable import WorkCorpus

struct WorkTests {
    @Test("configuration is validated from the YAML model itself")
    func acceptsConfiguration() throws {
        let book = try YAMLDecoder().decode(Work.self, from: fixture("book-with-listening"))

        try WorkCorpus.validateConfiguration(book)
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
            try Part(title: "First", summary: "", first: 1, last: 10),
            try Part(title: "Second", summary: "", first: 12, last: 20)
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

    @Test("what is wrong with a language is said with the value written out")
    func languageErrorNamesTheValue() {
        #expect(
            WorkCorpus.WorkShapeError.invalidLanguage("\u{200B}").errorDescription
                == "The work names its language as \"\\u{200B}\", "
                + "which is not a language tag such as en, eng or en-GB."
        )
        #expect(
            WorkCorpus.WorkShapeError.invalidLanguage("\u{0085}en").errorDescription
                == "The work names its language as \"\\u{85}en\", "
                + "which is not a language tag such as en, eng or en-GB."
        )
    }

    @Test("what is wrong with a number is said naming the field")
    func numberErrorNamesTheField() {
        #expect(
            WorkCorpus.WorkShapeError.invalidNumber(place: "pieces[0].number").errorDescription
                == "The work's pieces[0].number is not a whole number that fits in 32 bits."
        )
    }

    @Test("a part that runs past the last piece is refused rather than overflowing")
    func refusesPartPastTheWork() throws {
        let last = Int(Int32.max)
        let work = try work(parts: [Part(title: "All", summary: "", first: 1, last: last)])

        #expect(throws: WorkCorpus.WorkShapeError.partOutOfRange(first: 1, last: last)) {
            try WorkCorpus.validateConfiguration(work)
        }
    }

    @Test("a part that ends before it starts, or starts before piece one, cannot be made")
    func refusesBackwardPart() {
        #expect(throws: WorkCorpus.WorkShapeError.partOutOfRange(first: 3, last: 2)) {
            try Part(title: "Back", summary: "", first: 3, last: 2)
        }
        #expect(throws: WorkCorpus.WorkShapeError.partOutOfRange(first: 0, last: 2)) {
            try Part(title: "Early", summary: "", first: 0, last: 2)
        }
    }

    private func work(
        threshold: Int = 3,
        parts: [Part]? = nil,
        free: [Int] = [1]
    ) throws -> Work {
        let pieces = try (1...20).map { number in
            try Piece(number: number, title: "Piece \(number)", lines: ["A line of verse,"])
        }
        return Work(
            language: "eng",
            pieces: pieces,
            parts: try parts
                ?? [Part(title: "The work", summary: "", first: 1, last: pieces.count)],
            free: free,
            stageField: StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: threshold)
        )
    }
}
