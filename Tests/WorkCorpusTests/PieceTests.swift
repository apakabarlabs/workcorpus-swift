import Testing

@testable import WorkCorpus

struct PieceTests {
    private func piece(cuts: [String: [Int]]) throws -> Piece {
        try Piece(
            number: 1,
            title: "Piece 1",
            lines: Array(repeating: "A line of verse,", count: 14),
            cutSizes: cuts
        )
    }

    @Test("cuts that cover the piece exactly are accepted")
    func acceptsCutsThatCoverThePiece() throws {
        #expect(try piece(cuts: ["block": [4, 4, 4, 2]]).cutSizes == ["block": [4, 4, 4, 2]])
    }

    @Test("a stage the piece says nothing about is accepted, and read line by line")
    func acceptsAnUncutStage() throws {
        #expect(try piece(cuts: [:]).cuts(for: .block).count == 14)
    }

    @Test("a piece whose cuts leave lines past the last cut is refused, naming piece and stage")
    func refusesCutsShortOfThePiece() {
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 8,
                lines: 14
            )
        ) {
            try piece(cuts: ["block": [4, 4]])
        }
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 0,
                lines: 14
            )
        ) {
            try piece(cuts: ["block": []])
        }
    }

    @Test("a piece whose cuts run past its lines is refused rather than cut short")
    func refusesOverrunningCuts() {
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 16,
                lines: 14
            )
        ) {
            try piece(cuts: ["block": [4, 4, 4, 4]])
        }
        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: Int.max,
                lines: 14
            )
        ) {
            try piece(cuts: ["block": [Int.max, 1]])
        }
    }

    @Test("a cut of no lines is refused, naming the piece and the stage")
    func refusesEmptyCut() {
        #expect(throws: WorkCorpus.WorkShapeError.emptyCut(piece: 1, stage: "block", size: 0)) {
            try piece(cuts: ["block": [4, 0, 4]])
        }
        #expect(throws: WorkCorpus.WorkShapeError.emptyCut(piece: 1, stage: "block", size: -2)) {
            try piece(cuts: ["block": [-2, 16]])
        }
    }

    @Test("cuts for a stage there is no such thing as are refused rather than ignored")
    func refusesUnknownStage() {
        #expect(throws: WorkCorpus.WorkShapeError.cutsForUnknownStage(piece: 1, stage: "stanza")) {
            try piece(cuts: ["stanza": [7, 7]])
        }
    }

    @Test("cuts for the line stage are refused, since that stage is never cut")
    func refusesLineStageCuts() {
        #expect(throws: WorkCorpus.WorkShapeError.cutsForLineStage(piece: 1)) {
            try piece(cuts: ["line": [2, 2]])
        }
    }

    @Test("what is wrong with a cut is said in words that name the piece and the stage")
    func cutErrorsNameThePlace() {
        let error = WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
            piece: 99,
            stage: "block",
            cut: 16,
            lines: 15
        )

        #expect(
            error.errorDescription
                == "Piece 99 is cut at the block stage into 16 lines, but it has 15."
        )
    }
}
