import Foundation
import Testing
@testable import SonnetCorpus

struct SonnetCorpusTests {
    private func sonnets(count: Int = SonnetCorpus.count) -> [Sonnet] {
        (1...count).map { number in
            Sonnet(
                number: number,
                lines: Array(repeating: "A line of verse,", count: SonnetCorpus.expectedLineCount(for: number))
            )
        }
    }

    @Test("the irregular sonnets keep their own length")
    func knowsIrregularSonnets() {
        #expect(SonnetCorpus.expectedLineCount(for: 1) == 14)
        #expect(SonnetCorpus.expectedLineCount(for: 99) == 15)
        #expect(SonnetCorpus.expectedLineCount(for: 126) == 12)
    }

    @Test("a complete corpus validates")
    func acceptsCompleteCorpus() throws {
        try SonnetCorpus.validate(sonnets())
    }

    @Test("a short corpus is refused")
    func refusesMissingSonnets() {
        #expect(throws: SonnetCorpus.CorpusError.wrongSonnetCount(153)) {
            try SonnetCorpus.validate(Array(sonnets().dropLast()))
        }
    }

    @Test("a sonnet of the wrong length is refused")
    func refusesWrongLineCount() {
        var corpus = sonnets()
        corpus[17] = Sonnet(number: 18, lines: ["Shall I compare thee to a summer's day?"])

        #expect(throws: SonnetCorpus.CorpusError.wrongLineCount(sonnet: 18, lines: 1)) {
            try SonnetCorpus.validate(corpus)
        }
    }

    @Test("sonnets out of order are refused")
    func refusesOutOfOrder() {
        var corpus = sonnets()
        corpus.swapAt(0, 1)

        #expect(throws: SonnetCorpus.CorpusError.outOfOrder(expected: 1, found: 2)) {
            try SonnetCorpus.validate(corpus)
        }
    }

    @Test("a sonnet hands its lines to the reading mechanics unchanged")
    func exposesPassage() {
        let sonnet = Sonnet(number: 1, lines: ["From fairest creatures we desire increase,"])

        #expect(sonnet.passage.lines == sonnet.lines)
    }

    @Test("a sonnet names itself by number and by its opening line")
    func namesItself() {
        let sonnet = Sonnet(number: 18, lines: ["Shall I compare thee to a summer’s day?", "Thou art more lovely"])

        #expect(sonnet.title == "Sonnet 18")
        #expect(sonnet.openingLine == "Shall I compare thee to a summer’s day?")
    }
}
