import Foundation
import Testing
@testable import SonnetCorpus

struct HeldBookTests {
    private let reading = HeldReading(
        untouchedBelow: 0.001,
        begunBelow: 0.5,
        mostBelow: 1.0,
        difficultWordScore: 3,
        shortestAttemptSeconds: 0.2,
        free: [1, 18]
    )

    private let pieces = [
        HeldPiece(
            number: 1,
            lines: ["From fairest creatures we desire increase,"],
            partTitle: "The Procreation Sonnets",
            partShort: "The Procreation",
            partSummary: "Marry, and let your beauty outlive you."
        ),
        HeldPiece(
            number: 2,
            lines: ["When forty winters shall besiege thy brow,"],
            partTitle: "The Procreation Sonnets",
            partShort: "The Procreation",
            partSummary: "Marry, and let your beauty outlive you."
        ),
        HeldPiece(
            number: 3,
            lines: ["Look in thy glass and tell the face thou viewest"],
            partTitle: "The Fair Youth",
            partShort: nil,
            partSummary: "The poet writes to the young man."
        ),
    ]

    @Test("the sonnets come out numbered and in the order they are held")
    func sonnets() throws {
        let book = SonnetCorpus.assemble(pieces: pieces, reading: reading)

        #expect(book.sonnets.map(\.number) == [1, 2, 3])
        #expect(book.sonnets[1].lines == ["When forty winters shall besiege thy brow,"])
    }

    @Test("a part covers the sonnets filed under it and keeps its two names")
    func parts() throws {
        let book = SonnetCorpus.assemble(pieces: pieces, reading: reading)

        #expect(book.groups.map(\.title) == ["The Procreation Sonnets", "The Fair Youth"])
        #expect(book.groups[0].shortTitle == "The Procreation")
        #expect(book.groups[0].sonnets == 1...2)
        #expect(book.groups[1].shortTitle == "The Fair Youth")
        #expect(book.groups[1].sonnets == 3...3)
    }

    @Test("the numbers the drill reads come off the reading it was given")
    func thresholds() throws {
        let book = SonnetCorpus.assemble(pieces: pieces, reading: reading)

        #expect(book.free == [1, 18])
        #expect(book.stageField.band(for: 0.0005) == .untouched)
        #expect(book.difficultWords.scoreThreshold == 3)
        #expect(book.listening.shortestAttemptSeconds == 0.2)
    }

    @Test("a part interrupted and taken up again is two parts, not one spanning the gap")
    func partsAreRunsRatherThanNames() throws {
        let returning = pieces + [
            HeldPiece(
                number: 4,
                lines: ["Unthrifty loveliness, why dost thou spend"],
                partTitle: "The Procreation Sonnets",
                partShort: "The Procreation",
                partSummary: "Marry, and let your beauty outlive you."
            ),
        ]

        let book = SonnetCorpus.assemble(pieces: returning, reading: reading)

        #expect(book.groups.map(\.sonnets) == [1...2, 3...3, 4...4])
    }

    @Test("a held book short of the sequence is refused by the rules the file is held to")
    func heldToTheSameRules() throws {
        #expect(throws: SonnetCorpus.CorpusError.wrongSonnetCount(3)) {
            try SonnetCorpus.book(pieces: pieces, reading: reading)
        }
    }
}
