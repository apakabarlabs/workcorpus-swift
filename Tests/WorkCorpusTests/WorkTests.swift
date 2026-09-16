import Testing
@testable import WorkCorpus

struct WorkTests {
    @Test("configuration is validated from the YAML model itself")
    func acceptsConfiguration() throws {
        try WorkCorpus.validateConfiguration(work())
    }

    @Test("difficult words need a positive score threshold")
    func refusesInvalidDifficultWordThreshold() {
        #expect(throws: WorkCorpus.WorkShapeError.invalidDifficultWordThreshold) {
            try WorkCorpus.validateConfiguration(work(threshold: 0))
        }
    }

    @Test("parts have to cover the whole work")
    func refusesGapBetweenParts() {
        let parts = [
            Part(title: "First", summary: "", first: 1, last: 10),
            Part(title: "Second", summary: "", first: 12, last: 20)
        ]
        #expect(throws: WorkCorpus.WorkShapeError.partsDoNotCoverTheWork) {
            try WorkCorpus.validateConfiguration(work(parts: parts))
        }
    }

    @Test("the pieces free to read have to be unique members of the work")
    func refusesInvalidFreePieces() {
        #expect(throws: WorkCorpus.WorkShapeError.invalidFreePieces) {
            try WorkCorpus.validateConfiguration(work(free: [1, 1]))
        }
    }

    @Test("an attempt has a length, and it is shorter than a line")
    func refusesInvalidListeningThresholds() {
        #expect(throws: WorkCorpus.WorkShapeError.invalidListeningThresholds) {
            try WorkCorpus.validateConfiguration(work(shortestAttempt: 0))
        }
        #expect(throws: WorkCorpus.WorkShapeError.invalidListeningThresholds) {
            try WorkCorpus.validateConfiguration(work(shortestAttempt: 200))
        }
    }

    @Test("a tap is told from a line by its length")
    func readsAttemptsAgainstTheThresholds() {
        let thresholds = ListeningThresholds(shortestAttemptSeconds: 0.2)
        #expect(thresholds.isAccidentalTap(seconds: 0.2))
        #expect(!thresholds.isAccidentalTap(seconds: 0.21))
    }

    private func work(
        threshold: Int = 3,
        parts: [Part]? = nil,
        free: [Int] = [1],
        shortestAttempt: Double = 0.2
    ) -> Work {
        let pieces = (1...20).map { Piece(number: $0, title: "Piece \($0)", lines: ["A line of verse,"]) }
        return Work(
            pieces: pieces,
            parts: parts ?? [Part(title: "The work", summary: "", first: 1, last: pieces.count)],
            free: free,
            stageField: StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1),
            difficultWords: DifficultWordsConfiguration(scoreThreshold: threshold),
            listening: ListeningThresholds(shortestAttemptSeconds: shortestAttempt)
        )
    }
}
