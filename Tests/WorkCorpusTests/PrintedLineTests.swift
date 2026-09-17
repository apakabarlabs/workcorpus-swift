import Foundation
import ReadAloudKit
import Testing

@testable import WorkCorpus

struct PrintedLineTests {
    private func publishedPieces() throws -> [Piece] {
        try WorkCorpus.decodeWork(workFixture()).pieces
    }

    @Test("no mark of any printed line is left standing alone")
    func keepsEveryMarkWithAWord() throws {
        for piece in try publishedPieces() {
            for (index, line) in piece.lines.enumerated() {
                let withWords = WordTokenizer.latinScript.segments(in: line).filter { segment in
                    segment.wordIndex != nil
                }

                #expect(
                    withWords.map(\.wordWithMarks).joined()
                        == String(line.filter { !$0.isWhitespace }),
                    "piece \(piece.number), line \(index + 1): \(line)"
                )
            }
        }
    }
}
