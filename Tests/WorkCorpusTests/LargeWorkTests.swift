import Foundation
import Testing

@testable import WorkCorpus

struct LargeWorkTests {
    private static let pieces = 5000
    private static let budget = Duration.seconds(5)

    private static func book(repeatingIn last: Bool) -> String {
        var book = "language: eng\npieces:\n"
        for number in 1...pieces {
            book += "  - number: \(number)\n    title: Piece \(number)\n"
            if last, number == pieces { book += "    title: Again\n" }
            book += "    lines: [A line of verse.]\n"
        }
        book += "parts:\n  - title: All\n    summary: Every piece.\n    first: 1\n"
        book += "    last: \(pieces)\n"
        book += "free: [1]\n"
        book += "stage_field:\n  untouched_below: 0.001\n  begun_below: 0.5\n  most_below: 1.0\n"
        book += "difficult_words:\n  score_threshold: 3\n"
        return book
    }

    @Test("a large book with a key repeated near its end is refused within the budget")
    func repeatNearTheEnd() {
        let book = Self.book(repeatingIn: true)
        let clock = ContinuousClock()

        let elapsed = clock.measure {
            #expect(throws: WorkCorpus.WorkShapeError.repeatedKey("title")) {
                try WorkCorpus.decodeWorkFromBook(book)
            }
        }
        #expect(elapsed < Self.budget, "took \(elapsed)")
    }

    @Test("a large book without a repeat is read within the budget")
    func readWithinTheBudget() throws {
        let book = Self.book(repeatingIn: false)
        let clock = ContinuousClock()
        var count = 0

        let elapsed = try clock.measure {
            count = try WorkCorpus.decodeWorkFromBook(book).pieces.count
        }
        #expect(count == Self.pieces)
        #expect(elapsed < Self.budget, "took \(elapsed)")
    }
}
