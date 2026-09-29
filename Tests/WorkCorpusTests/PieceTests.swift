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

    @Test("a number or cut size held past 32 bits is refused, naming the piece")
    func refusesNumbersPast32Bits() {
        let past = Int(Int32.max) + 1

        #expect(throws: WorkCorpus.WorkShapeError.invalidNumber(place: "piece \(past)")) {
            try Piece(number: past, title: "Far", lines: ["A line of verse,"])
        }
        #expect(throws: WorkCorpus.WorkShapeError.invalidNumber(place: "piece 1 block cut")) {
            try piece(cuts: ["block": [past]])
        }
    }

    @Test("a piece held with cuts that do not divide its lines is refused as a decoded one is")
    func heldPieceIsHeldToTheCutRules() {
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
    }
}
