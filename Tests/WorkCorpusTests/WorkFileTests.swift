import Foundation
import Testing

@testable import WorkCorpus

struct WorkFileTests {
    @Test("the pieces come out of the work file numbered and in order")
    func pieces() throws {
        let read = try WorkCorpus.assembleWork(workFixture())

        #expect(read.pieces.map(\.number) == [1, 2, 3])
        #expect(read.pieces[1].lines == ["When forty winters shall besiege thy brow,"])
    }

    @Test("a piece carries the title the work gave it")
    func titles() throws {
        let read = try WorkCorpus.assembleWork(workFixture())

        #expect(read.pieces.map(\.title) == ["Sonnet 1", "Sonnet 2", "Sonnet 3"])
    }

    @Test("a piece is cut the way the work file says it is cut")
    func cuts() throws {
        let read = try WorkCorpus.assembleWork(workFixture())

        #expect(read.pieces[0].cuts(for: .block).map(\.count) == [2])
        #expect(read.pieces[1].cuts(for: .block).map(\.count) == [1])
    }

    @Test("a part covers the pieces under it and keeps its two names")
    func parts() throws {
        let read = try WorkCorpus.assembleWork(workFixture())

        #expect(read.parts.map(\.title) == ["The Procreation Sonnets", "The Fair Youth"])
        #expect(read.parts[0].shortTitle == "The Procreation")
        #expect(read.parts[0].pieces == 1...2)
        #expect(read.parts[1].shortTitle == "The Fair Youth")
    }

    @Test("the reading thresholds come off the reading block")
    func thresholds() throws {
        let read = try WorkCorpus.assembleWork(workFixture())

        #expect(read.free == [1, 2])
        #expect(read.stageField.band(for: 0.0005) == .untouched)
        #expect(read.difficultWords.scoreThreshold == 3)
    }

    @Test(
        "a work file that still names a shortest attempt is read, whatever it says",
        arguments: ["0.2", "0", "200"]
    )
    func olderReadingBlock(seconds: String) throws {
        let older = try workFixture().replacingOccurrences(
            of: "  difficult_word_score: 3\n",
            with: "  difficult_word_score: 3\n  shortest_attempt_seconds: \(seconds)\n"
        )

        #expect(older != (try workFixture()))
        #expect(try WorkCorpus.decodeWork(older).pieces.count == 3)
    }

    @Test("a piece that is not numbered is refused rather than renumbered")
    func unnumberedPiece() throws {
        let prose = try workFixture().replacingOccurrences(of: "id: '3'", with: "id: prologue")

        #expect(throws: WorkCorpus.WorkError.pieceIsNotNumbered("prologue")) {
            try WorkCorpus.assembleWork(prose)
        }
    }

    @Test("a work file whose parts leave a gap is refused")
    func heldToTheSameRules() throws {
        let gapped = try workFixture().replacingOccurrences(of: "id: '2'", with: "id: '4'")

        #expect(throws: WorkCorpus.CorpusError.outOfOrder(expected: 2, found: 4)) {
            try WorkCorpus.decodeWork(gapped)
        }
    }
}
