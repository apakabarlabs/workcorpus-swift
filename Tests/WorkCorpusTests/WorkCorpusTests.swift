import Foundation
import Testing

@testable import WorkCorpus

struct WorkCorpusTests {
    private func pieces(count: Int) -> [Piece] {
        (1...count).map { number in
            Piece(number: number, title: "Piece \(number)", lines: ["A line of verse,"])
        }
    }

    @Test("pieces numbered from one and in order are accepted")
    func acceptsPiecesInOrder() throws {
        try WorkCorpus.validate(pieces(count: 3))
    }

    @Test("pieces out of order are refused")
    func refusesOutOfOrder() {
        var out = pieces(count: 3)
        out.swapAt(0, 1)

        #expect(throws: WorkCorpus.CorpusError.outOfOrder(expected: 1, found: 2)) {
            try WorkCorpus.validate(out)
        }
    }

    @Test("a work of any length is accepted: how many pieces it has is its own business")
    func acceptsAnyLength() throws {
        try WorkCorpus.validate(pieces(count: 1))
        try WorkCorpus.validate(pieces(count: 400))
    }

    @Test("a piece of any length is accepted: how many lines it has is its own business")
    func acceptsAnyPieceLength() throws {
        let uneven = [
            Piece(number: 1, title: "One", lines: ["A single line."]),
            Piece(number: 2, title: "Two", lines: Array(repeating: "A line of verse,", count: 30))
        ]

        try WorkCorpus.validate(uneven)
    }

    @Test("a piece hands its lines to the reading mechanics unchanged")
    func exposesPassage() {
        let piece = Piece(
            number: 1,
            title: "Sonnet 1",
            lines: ["From fairest creatures we desire increase,"]
        )

        #expect(piece.passage.lines == piece.lines)
    }

    @Test("a piece carries the title the work gave it, and its opening line")
    func namesItself() {
        let piece = Piece(
            number: 18,
            title: "Sonnet 18",
            lines: ["Shall I compare thee to a summer’s day?", "Thou art more lovely"]
        )

        #expect(piece.title == "Sonnet 18")
        #expect(piece.openingLine == "Shall I compare thee to a summer’s day?")
    }
}
