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
}
