import Foundation
import ReadAloudKit
import Testing

@testable import WorkCorpus

struct PrintedLineTests {
    @Test("no mark of any printed line is left standing alone")
    func keepsEveryMarkWithAWord() throws {
        let work = try WorkCorpus.decodeWork(workFixture())
        let tokenizer = WordTokenizer(interiorMarks: CharacterSet(charactersIn: work.interiorMarks))
        for piece in work.pieces {
            for (index, line) in piece.lines.enumerated() {
                let withWords = tokenizer.segments(in: line).filter { segment in
                    segment.wordIndex != nil
                }

                #expect(
                    withWords.map { $0.wordWithMarks }.joined()
                        == String(line.filter { !$0.isWhitespace }),
                    "piece \(piece.number), line \(index + 1): \(line)"
                )
            }
        }
    }
}
