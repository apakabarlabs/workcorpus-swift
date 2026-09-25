import Foundation
import Testing

@testable import WorkCorpus

struct HeldBookTests {
    private let reading = HeldReading(
        untouchedBelow: 0.001,
        begunBelow: 0.5,
        mostBelow: 1.0,
        difficultWordScore: 3,
        free: [1, 2]
    )

    private let pieces = [
        HeldPiece(
            number: 1,
            title: "Sonnet 1",
            lines: ["From fairest creatures we desire increase,"],
            partTitle: "The Procreation Sonnets",
            partShort: "The Procreation",
            partSummary: "Marry, and let your beauty outlive you."
        ),
        HeldPiece(
            number: 2,
            title: "Sonnet 2",
            lines: ["When forty winters shall besiege thy brow,"],
            partTitle: "The Procreation Sonnets",
            partShort: "The Procreation",
            partSummary: "Marry, and let your beauty outlive you."
        ),
        HeldPiece(
            number: 3,
            title: "Sonnet 3",
            lines: ["Look in thy glass and tell the face thou viewest"],
            partTitle: "The Fair Youth",
            partShort: nil,
            partSummary: "The poet writes to the young man."
        )
    ]

    @Test("the pieces come out numbered and in the order they are held")
    func heldPieces() {
        let work = WorkCorpus.assemble(pieces: pieces, reading: reading)

        #expect(work.pieces.map(\.number) == [1, 2, 3])
        #expect(work.pieces[1].lines == ["When forty winters shall besiege thy brow,"])
        #expect(work.pieces[1].title == "Sonnet 2")
    }

    @Test("a part covers the pieces filed under it and keeps its two names")
    func parts() {
        let work = WorkCorpus.assemble(pieces: pieces, reading: reading)

        #expect(work.parts.map(\.title) == ["The Procreation Sonnets", "The Fair Youth"])
        #expect(work.parts[0].shortTitle == "The Procreation")
        #expect(work.parts[0].pieces == 1...2)
        #expect(work.parts[1].shortTitle == "The Fair Youth")
        #expect(work.parts[1].pieces == 3...3)
    }

    @Test("the reading thresholds come off the reading it was given")
    func thresholds() {
        let work = WorkCorpus.assemble(pieces: pieces, reading: reading)

        #expect(work.free == [1, 2])
        #expect(work.stageField.band(for: 0.0005) == .untouched)
        #expect(work.difficultWords.scoreThreshold == 3)
    }

    @Test("a part interrupted and taken up again is two parts, not one spanning the gap")
    func partsAreRunsRatherThanNames() {
        let returning =
            pieces + [
                HeldPiece(
                    number: 4,
                    title: "Sonnet 4",
                    lines: ["Unthrifty loveliness, why dost thou spend"],
                    partTitle: "The Procreation Sonnets",
                    partShort: "The Procreation",
                    partSummary: "Marry, and let your beauty outlive you."
                )
            ]

        let work = WorkCorpus.assemble(pieces: returning, reading: reading)

        #expect(work.parts.map(\.pieces) == [1...2, 3...3, 4...4])
    }

    @Test("a work whose pieces are out of order is refused")
    func heldToTheSameRules() throws {
        let outOfOrder = [pieces[1], pieces[0], pieces[2]]

        #expect(throws: WorkCorpus.CorpusError.outOfOrder(expected: 1, found: 2)) {
            try WorkCorpus.work(pieces: outOfOrder, reading: reading)
        }
    }
}
