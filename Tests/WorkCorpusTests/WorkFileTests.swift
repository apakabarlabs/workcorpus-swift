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

    @Test("the language comes off the work file as the work names it")
    func language() throws {
        #expect(try WorkCorpus.decodeWork(workFixture()).language == "eng")

        let serbian = try workFixture().replacingOccurrences(
            of: "language: eng\n",
            with: "language: srp\n"
        )
        #expect(try WorkCorpus.decodeWork(serbian).language == "srp")
    }

    @Test("a work file that does not name its language is refused, and says so")
    func withoutLanguage() throws {
        let unnamed = try workFixture().replacingOccurrences(of: "language: eng\n", with: "")

        #expect(unnamed != (try workFixture()))
        let error = #expect(throws: DecodingError.self) {
            try WorkCorpus.decodeWork(unnamed)
        }
        #expect(String(describing: error).contains("language"))
    }

    @Test("a work file whose cuts overrun a piece is refused")
    func overrunningCuts() throws {
        let overrun = try workFixture().replacingOccurrences(
            of: "          block:\n            - 2\n",
            with: "          block:\n            - 3\n"
        )

        #expect(overrun != (try workFixture()))
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 3,
                lines: 2
            )
        ) {
            try WorkCorpus.decodeWork(overrun)
        }
    }

    @Test("a work file whose cuts fall short of a piece is refused")
    func shortCuts() throws {
        let short = try workFixture().replacingOccurrences(
            of: "          block:\n            - 2\n",
            with: "          block:\n            - 1\n"
        )

        #expect(short != (try workFixture()))
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 1,
                lines: 2
            )
        ) {
            try WorkCorpus.decodeWork(short)
        }
    }

    @Test(
        "a work file number that is not a YAML integer within 32 bits is refused, naming the field",
        arguments: [
            (
                "          block:\n            - 2\n",
                "          block:\n            - -99999999999999999999\n",
                "sections[0].pieces[0].cuts.block[0]"
            ),
            (
                "          block:\n            - 2\n",
                "          block:\n            - '2'\n",
                "sections[0].pieces[0].cuts.block[0]"
            ),
            (
                "  difficult_word_score: 3\n",
                "  difficult_word_score: true\n",
                "reading.difficult_word_score"
            )
        ]
    )
    func invalidNumber(written: String, replaced: String, place: String) throws {
        let changed = try workFixture().replacingOccurrences(of: written, with: replaced)

        #expect(changed != (try workFixture()))
        #expect(throws: WorkCorpus.WorkShapeError.invalidNumber(place: place)) {
            try WorkCorpus.decodeWork(changed)
        }
    }

    @Test("a piece identifier past 32 bits is refused as not a number")
    func pieceIdPast32Bits() throws {
        let past = try workFixture().replacingOccurrences(of: "id: '3'", with: "id: '2147483648'")

        #expect(throws: WorkCorpus.WorkError.pieceIsNotNumbered("2147483648")) {
            try WorkCorpus.assembleWork(past)
        }
    }

    @Test("a work file piece whose cuts are null is read as having none")
    func nullCuts() throws {
        let null = try workFixture().replacingOccurrences(
            of: "        cuts:\n          block:\n            - 2\n",
            with: "        cuts: null\n"
        )

        #expect(null != (try workFixture()))
        #expect(try WorkCorpus.decodeWork(null).pieces[0].cutSizes == [:])
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

    @Test("a work file whose pieces skip a number is refused as out of order")
    func skippedPieceNumber() throws {
        let skipped = try workFixture().replacingOccurrences(of: "id: '2'", with: "id: '4'")

        #expect(throws: WorkCorpus.CorpusError.outOfOrder(expected: 2, found: 4)) {
            try WorkCorpus.decodeWork(skipped)
        }
    }
}
