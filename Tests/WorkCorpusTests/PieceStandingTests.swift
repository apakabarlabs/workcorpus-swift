import ReadAloudKit
import Testing

@testable import WorkCorpus

struct PieceStandingTests {
    @Test("an untouched piece is neither started nor complete")
    func untouched() {
        let standing = PieceStanding(stages: [.untouched, .untouched])

        #expect(!standing.isStarted)
        #expect(!standing.isComplete)
    }

    @Test("a partly read stage starts but does not complete the piece")
    func partialStage() {
        let standing = PieceStanding(stages: [.started, .untouched])

        #expect(standing.isStarted)
        #expect(!standing.isComplete)
    }

    @Test("completing either stage completes the piece")
    func eitherStage() {
        #expect(PieceStanding(stages: [.complete, .started]).isComplete)
        #expect(PieceStanding(stages: [.started, .complete]).isComplete)
    }

    @Test("stored states are restored for the known stages")
    func restored() throws {
        let standing = try PieceStanding(stored: [2, 1])

        #expect(standing.stages == [.complete, .started])
    }

    @Test("an unknown stored state for a known stage is refused")
    func unknownState() {
        let refusal = #expect(throws: UnknownStageState.self) {
            try PieceStanding(stored: [7, 0])
        }

        #expect(refusal?.raw == 7)
    }

    @Test("a state stored for a stage this release does not know is dropped unread")
    func laterStage() throws {
        let standing = try PieceStanding(stored: [1, 0, 9])

        #expect(standing.stages == [.started, .untouched])
    }
}
