import Foundation
import Testing
@testable import SonnetCorpus

struct DrillStageTests {
    private func sonnet(_ number: Int, lines count: Int) -> Sonnet {
        Sonnet(number: number, lines: (1...count).map { "line \($0)" })
    }

    @Test("every stage covers the whole poem, in order, with nothing dropped")
    func piecesCoverThePoem() {
        for poem in [sonnet(1, lines: 14), sonnet(99, lines: 15), sonnet(126, lines: 12)] {
            for stage in DrillStage.allCases {
                let pieces = poem.pieces(for: stage)
                #expect(pieces.first?.lowerBound == 0)
                #expect(pieces.last?.upperBound == poem.lines.count - 1)
                for (earlier, later) in zip(pieces, pieces.dropFirst()) {
                    #expect(earlier.upperBound + 1 == later.lowerBound)
                }
            }
        }
    }

    @Test("a line is a piece at the first stage")
    func linesAreTheSmallestPiece() {
        let pieces = sonnet(1, lines: 14).pieces(for: .line)
        #expect(pieces.count == 14)
        #expect(pieces.allSatisfy { $0.count == 1 })
    }

    @Test("quatrains and the closing couplet at the second")
    func blocksAreQuatrainsAndACouplet() {
        #expect(sonnet(1, lines: 14).pieces(for: .block).map(\.count) == [4, 4, 4, 2])
    }

    @Test("the irregular sonnets keep their own shape")
    func irregularSonnetsAreCutTheirOwnWay() {
        #expect(sonnet(99, lines: 15).pieces(for: .block).map(\.count) == [5, 4, 4, 2])
        #expect(sonnet(126, lines: 12).pieces(for: .block).map(\.count) == [4, 4, 4])
    }

    @Test("both stages are offered, and every piece of the poem is in each")
    func bothStagesCoverThePoem() {
        #expect(DrillStage.allCases == [.line, .block])
        for stage in DrillStage.allCases {
            let pieces = sonnet(1, lines: 14).pieces(for: stage)
            #expect(pieces.first?.lowerBound == 0)
            #expect(pieces.last?.upperBound == 13)
        }
    }
}
