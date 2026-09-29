import Foundation
import Testing
import Yams

@testable import WorkCorpus

struct WorkTests {
    private static let elisions = "elisions:\n  tatter’d: [tattered]\n  th’: [the]\n"

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

    @Test(
        "a book that leaves out the marks inside a word or its elisions is refused, naming the key",
        arguments: ["interior_marks: \"'’-\"\n", Self.elisions]
    )
    func bookWithoutWritingKey(_ left: String) throws {
        let book = try fixture("book-with-listening").replacingOccurrences(of: left, with: "")

        #expect(book != (try fixture("book-with-listening")))
        let error = #expect(throws: DecodingError.self) {
            try WorkCorpus.decodeWorkFromBook(book)
        }
        guard case let .keyNotFound(key, _) = error else {
            Issue.record("refused with \(String(describing: error)) rather than a missing key")
            return
        }
        #expect(left.hasPrefix(key.stringValue + ":"))
    }

    @Test(
        "a book whose marks or elisions are not the kind of value they hold is refused there",
        arguments: [
            ("interior_marks: \"'’-\"\n", "interior_marks: [\"'\"]\n", "interior_marks"),
            (Self.elisions, "elisions:\n  - th’\n", "elisions"),
            (Self.elisions, "elisions: null\n", "elisions"),
            ("  th’: [the]\n", "  th’: the\n", "elisions.th’")
        ]
    )
    func bookWithWritingOfAnotherKind(_ written: String, _ wrong: String, _ place: String) throws {
        let book = try fixture("book-with-listening").replacingOccurrences(of: written, with: wrong)

        #expect(book != (try fixture("book-with-listening")))
        let error = #expect(throws: DecodingError.self) {
            try WorkCorpus.decodeWorkFromBook(book)
        }
        switch error {
        case let .typeMismatch(_, context), let .valueNotFound(_, context):
            #expect(WorkCorpus.place(context.codingPath) == place)
        default:
            Issue.record("refused with \(String(describing: error)) rather than naming \(place)")
        }
    }

    @Test("a JSON work whose elisions are null is refused, naming the key")
    func jsonWithNullElisions() {
        let json = #"{"language": "eng", "interior_marks": "", "elisions": null}"#

        let error = #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(Work.self, from: Data(json.utf8))
        }
        guard case let .valueNotFound(_, context) = error else {
            Issue.record("refused with \(String(describing: error)) rather than a null value")
            return
        }
        #expect(WorkCorpus.place(context.codingPath) == "elisions")
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

    @Test("a part held so that it ends before it starts cannot be made")
    func refusesBackwardPart() {
        #expect(throws: WorkCorpus.WorkShapeError.partOutOfRange(first: 3, last: 2)) {
            try Part(title: "Back", summary: "", first: 3, last: 2)
        }
    }

    private func work(
        threshold: Int = 3,
        free: [Int] = [1]
    ) throws -> Work {
        let pieces = try (1...20).map { number in
            try Piece(number: number, title: "Piece \(number)", lines: ["A line of verse,"])
        }
        return Work(
            writing: Writing(language: "eng", interiorMarks: "'’-", elisions: [:]),
            pieces: pieces,
            parts: [try Part(title: "The work", summary: "", first: 1, last: pieces.count)],
            free: free,
            stageField: StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: threshold)
        )
    }
}
