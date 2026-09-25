import Foundation
import Testing

@testable import WorkCorpus

struct ReadingStageTests {
    private func piece(_ number: Int, lines count: Int, cuts: [String: [Int]] = [:]) -> Piece {
        Piece(
            number: number,
            title: "Piece \(number)",
            lines: (1...count).map { "line \($0)" },
            cutSizes: cuts
        )
    }

    @Test("every stage covers the whole piece, in order, with nothing dropped")
    func cutsCoverThePiece() {
        let pieces = [
            piece(1, lines: 14, cuts: ["block": [4, 4, 4, 2]]),
            piece(99, lines: 15, cuts: ["block": [5, 4, 4, 2]]),
            piece(126, lines: 12, cuts: ["block": [4, 4, 4]])
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
    func linesAreTheSmallestCut() {
        let cuts = piece(1, lines: 14).cuts(for: .line)
        #expect(cuts.count == 14)
        #expect(cuts.allSatisfy { $0.count == 1 })
    }

    @Test("a stage is cut the way the work says it is cut")
    func theWorkSaysHowItIsCut() {
        #expect(
            piece(1, lines: 14, cuts: ["block": [4, 4, 4, 2]]).cuts(for: .block).map(\.count) == [
                4, 4, 4, 2
            ]
        )
        #expect(
            piece(99, lines: 15, cuts: ["block": [5, 4, 4, 2]]).cuts(for: .block).map(\.count) == [
                5, 4, 4, 2
            ]
        )
        #expect(
            piece(126, lines: 12, cuts: ["block": [4, 4, 4]]).cuts(for: .block).map(\.count) == [
                4, 4, 4
            ]
        )
    }

    @Test("a stage the work says nothing about is read line by line")
    func anUncutStageIsReadLineByLine() {
        #expect(piece(1, lines: 14).cuts(for: .block).count == 14)
    }

    @Test("lines past the last cut are not dropped")
    func nothingIsLeftBehindTheLastCut() {
        #expect(
            piece(1, lines: 14, cuts: ["block": [4, 4]]).cuts(for: .block).map(\.count) == [4, 4, 6]
        )
    }

    @Test("both stages are offered, and the whole piece is in each")
    func bothStagesCoverThePiece() {
        #expect(ReadingStage.allCases == [.line, .block])
        for stage in ReadingStage.allCases {
            let cuts = piece(1, lines: 14, cuts: ["block": [4, 4, 4, 2]]).cuts(for: stage)
            #expect(cuts.first?.lowerBound == 0)
            #expect(cuts.last?.upperBound == 13)
        }
    }
}
