import Foundation
import Testing

@testable import WorkCorpus

struct ReadingStageTests {
    private func piece(
        _ number: Int,
        lines count: Int,
        cuts: [String: [Int]] = [:]
    ) throws -> Piece {
        try Piece(
            number: number,
            title: "Piece \(number)",
            lines: (1...count).map { "line \($0)" },
            cutSizes: cuts
        )
    }

    @Test("every stage covers the whole piece, in order, with nothing dropped")
    func cutsCoverThePiece() throws {
        let pieces = [
            try piece(1, lines: 14, cuts: ["block": [4, 4, 4, 2]]),
            try piece(99, lines: 15, cuts: ["block": [5, 4, 4, 2]]),
            try piece(126, lines: 12, cuts: ["block": [4, 4, 4]])
        ]
        for poem in pieces {
            for stage in ReadingStage.allCases {
                let cuts = poem.cuts(for: stage)
                #expect(cuts.first?.lowerBound == 0)
                #expect(cuts.last?.upperBound == poem.lines.count - 1)
                for (earlier, later) in zip(cuts, cuts.dropFirst()) {
                    #expect(earlier.upperBound + 1 == later.lowerBound)
                }
            }
        }
    }

    @Test("a line is a cut of its own at the first stage")
    func linesAreTheSmallestCut() throws {
        let cuts = try piece(1, lines: 14).cuts(for: .line)
        #expect(cuts.count == 14)
        #expect(cuts.allSatisfy { $0.count == 1 })
    }

    @Test("a stage is cut the way the work says it is cut")
    func theWorkSaysHowItIsCut() throws {
        #expect(
            try piece(1, lines: 14, cuts: ["block": [4, 4, 4, 2]]).cuts(for: .block).map(\.count)
                == [4, 4, 4, 2]
        )
        #expect(
            try piece(99, lines: 15, cuts: ["block": [5, 4, 4, 2]]).cuts(for: .block).map(\.count)
                == [5, 4, 4, 2]
        )
        #expect(
            try piece(126, lines: 12, cuts: ["block": [4, 4, 4]]).cuts(for: .block).map(\.count)
                == [4, 4, 4]
        )
    }

    @Test("a stage the work says nothing about is read line by line")
    func anUncutStageIsReadLineByLine() throws {
        #expect(try piece(1, lines: 14).cuts(for: .block).count == 14)
    }

    @Test("a work whose cuts leave lines past the last cut is refused, naming piece and stage")
    func linesLeftBehindTheLastCutAreRefused() {
        let short = HeldPiece(
            number: 1,
            title: "Piece 1",
            lines: (1...14).map { "line \($0)" },
            partTitle: "The work",
            partShort: nil,
            partSummary: "",
            cutSizes: ["block": [4, 4]]
        )
        let reading = HeldReading(
            untouchedBelow: 0.001,
            begunBelow: 0.5,
            mostBelow: 1,
            difficultWordScore: 3,
            free: [1]
        )

        #expect(
            throws: WorkCorpus.WorkShapeError.cutsDoNotCoverThePiece(
                piece: 1,
                stage: "block",
                cut: 8,
                lines: 14
            )
        ) {
            try WorkCorpus.work(
                language: "eng",
                interiorMarks: "'’-",
                elisions: [:],
                pieces: [short],
                reading: reading
            )
        }
    }

    @Test("both stages are offered, and the whole piece is in each")
    func bothStagesCoverThePiece() throws {
        #expect(ReadingStage.allCases == [.line, .block])
        for stage in ReadingStage.allCases {
            let cuts = try piece(1, lines: 14, cuts: ["block": [4, 4, 4, 2]]).cuts(for: stage)
            #expect(cuts.first?.lowerBound == 0)
            #expect(cuts.last?.upperBound == 13)
        }
    }
}
