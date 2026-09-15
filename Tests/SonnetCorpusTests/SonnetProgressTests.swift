import ReadAloudKit
import Testing
@testable import SonnetCorpus

struct SonnetProgressTests {
    @Test("an untouched sonnet is neither started nor complete")
    func untouched() {
        let progress = SonnetProgress(stages: [.untouched, .untouched])

        #expect(!progress.isStarted)
        #expect(!progress.isComplete)
    }

    @Test("a partly read stage starts but does not complete the sonnet")
    func partialStage() {
        let progress = SonnetProgress(stages: [.started, .untouched])

        #expect(progress.isStarted)
        #expect(!progress.isComplete)
    }

    @Test("completing either stage completes the sonnet")
    func eitherStage() {
        #expect(SonnetProgress(stages: [.complete, .started]).isComplete)
        #expect(SonnetProgress(stages: [.started, .complete]).isComplete)
    }
}
