import Testing
import Yams

@testable import WorkCorpus

struct WorkTests {
    @Test("configuration is validated from the YAML model itself")
    func acceptsConfiguration() throws {
        let book = try YAMLDecoder().decode(Work.self, from: fixture("book-with-listening"))

        try WorkCorpus.validateConfiguration(book)
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

    @Test(
        "a language that is not a language tag is refused, naming the value",
        arguments: ["", " ", "\u{200B}", "\u{0085}", "eng\n", "EN", "e", "english", "en-", "en-GB-"]
    )
    func refusesLanguageThatIsNotATag(language: String) throws {
        let work = try work(language: language)

        #expect(throws: WorkCorpus.WorkShapeError.invalidLanguage(language)) {
            try WorkCorpus.validateConfiguration(work)
        }
    }

    @Test(
        "a language tag of two or three letters and its subtags is accepted",
        arguments: ["en", "eng", "srp", "en-GB", "sr-Latn-RS", "zh-Hant", "es-419"]
    )
    func acceptsLanguageTags(language: String) throws {
        try WorkCorpus.validateConfiguration(work(language: language))
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

    @Test("a book piece whose cuts are null is read as having none")
    func bookWithNullCuts() throws {
        let book = try fixture("book-with-listening").replacingOccurrences(
            of: "    lines: [The first line.]\n",
            with: "    lines: [The first line.]\n    cuts: null\n"
        )

        #expect(book != (try fixture("book-with-listening")))
        #expect(try WorkCorpus.decodeWorkFromBook(book).pieces[0].cutSizes == [:])
    }

    @Test(
        "a book number that is not a YAML integer within 32 bits is refused, naming the field",
        arguments: [
            (
                "    lines: [The first line.]\n",
                "    lines: [The first line.]\n    cuts:\n      block: [2147483648]\n",
                "pieces[0].cuts.block[0]"
            ),
            (
                "    lines: [The first line.]\n",
                "    lines: [The first line.]\n    cuts:\n      block: [99999999999999999999]\n",
                "pieces[0].cuts.block[0]"
            ),
            (
                "    lines: [The first line.]\n",
                "    lines: [The first line.]\n    cuts:\n      block: ['1']\n",
                "pieces[0].cuts.block[0]"
            ),
            (
                "    lines: [The first line.]\n",
                "    lines: [The first line.]\n    cuts:\n      block: [1.0]\n",
                "pieces[0].cuts.block[0]"
            ),
            (
                "    lines: [The first line.]\n",
                "    lines: [The first line.]\n    cuts:\n      block: [true]\n",
                "pieces[0].cuts.block[0]"
            ),
            ("  - number: 1\n", "  - number: '1'\n", "pieces[0].number"),
            ("  - number: 1\n", "  - number: 01\n", "pieces[0].number"),
            ("    last: 1\n", "    last: '1'\n", "parts[0].last"),
            ("free: [1]\n", "free: [2147483648]\n", "free[0]"),
            (
                "  score_threshold: 3\n",
                "  score_threshold: 3.5\n",
                "difficult_words.score_threshold"
            )
        ]
    )
    func bookWithInvalidNumber(written: String, replaced: String, place: String) throws {
        let book = try fixture("book-with-listening").replacingOccurrences(
            of: written,
            with: replaced
        )

        #expect(book != (try fixture("book-with-listening")))
        #expect(throws: WorkCorpus.WorkShapeError.invalidNumber(place: place)) {
            try WorkCorpus.decodeWorkFromBook(book)
        }
    }

    @Test(
        "a number not written as plain decimal digits is refused, whatever YAML makes of it",
        arguments: ["010", "0x4", "0o4", "0b1", "1_0", "+1", "1:30"]
    )
    func refusesNumbersNotWrittenAsPlainDecimal(written: String) throws {
        let fixture = try fixture("book-with-listening")
        let threshold = fixture.replacingOccurrences(
            of: "  score_threshold: 3\n",
            with: "  score_threshold: \(written)\n"
        )
        let cut = fixture.replacingOccurrences(
            of: "    lines: [The first line.]\n",
            with: "    lines: [The first line.]\n    cuts:\n      block: [\(written)]\n"
        )

        #expect(threshold != fixture)
        #expect(cut != fixture)
        let thresholdPlace = "difficult_words.score_threshold"
        let cutPlace = "pieces[0].cuts.block[0]"
        #expect(throws: WorkCorpus.WorkShapeError.invalidNumber(place: thresholdPlace)) {
            try WorkCorpus.decodeWorkFromBook(threshold)
        }
        #expect(throws: WorkCorpus.WorkShapeError.invalidNumber(place: cutPlace)) {
            try WorkCorpus.decodeWorkFromBook(cut)
        }
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
            parts: try parts
                ?? [Part(title: "The work", summary: "", first: 1, last: pieces.count)],
            free: free,
            stageField: StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: threshold)
        )
    }
}
