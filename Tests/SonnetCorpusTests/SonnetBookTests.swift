import Testing
@testable import SonnetCorpus

struct SonnetBookTests {
    @Test("configuration is validated from the YAML model itself")
    func acceptsConfiguration() throws {
        try SonnetCorpus.validateConfiguration(book())
    }

    @Test("difficult words need a positive score threshold")
    func refusesInvalidDifficultWordThreshold() {
        #expect(throws: SonnetCorpus.BookError.invalidDifficultWordThreshold) {
            try SonnetCorpus.validateConfiguration(book(threshold: 0))
        }
    }

    @Test("groups have to partition the whole book")
    func refusesGapBetweenGroups() {
        let groups = [
            SonnetGroup(title: "First", summary: "", first: 1, last: 10),
            SonnetGroup(title: "Second", summary: "", first: 12, last: SonnetCorpus.count)
        ]
        #expect(throws: SonnetCorpus.BookError.groupsDoNotPartitionBook) {
            try SonnetCorpus.validateConfiguration(book(groups: groups))
        }
    }

    @Test("free sonnets have to be unique members of the book")
    func refusesInvalidFreeSonnets() {
        #expect(throws: SonnetCorpus.BookError.invalidFreeSonnets) {
            try SonnetCorpus.validateConfiguration(book(free: [1, 1]))
        }
    }

    @Test("an attempt has a length, and it is shorter than a line")
    func refusesInvalidListeningThresholds() {
        #expect(throws: SonnetCorpus.BookError.invalidListeningThresholds) {
            try SonnetCorpus.validateConfiguration(book(shortestAttempt: 0))
        }
        #expect(throws: SonnetCorpus.BookError.invalidListeningThresholds) {
            try SonnetCorpus.validateConfiguration(book(shortestAttempt: 200))
        }
    }

    @Test("a tap is told from a line by its length")
    func readsAttemptsAgainstTheThresholds() {
        let thresholds = ListeningThresholds(shortestAttemptSeconds: 0.2)
        #expect(thresholds.isAccidentalTap(seconds: 0.2))
        #expect(!thresholds.isAccidentalTap(seconds: 0.21))
    }

    private func book(
        threshold: Int = 3,
        groups: [SonnetGroup]? = nil,
        free: [Int] = [1],
        shortestAttempt: Double = 0.2
    ) -> SonnetBook {
        SonnetBook(
            sonnets: [],
            groups: groups ?? [SonnetGroup(
                title: "The book",
                summary: "",
                first: 1,
                last: SonnetCorpus.count
            )],
            free: free,
            stageField: StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: threshold),
            listening: ListeningThresholds(shortestAttemptSeconds: shortestAttempt)
        )
    }
}
