import Foundation
import ReadAloudKit
import Testing

@testable import WorkCorpus

struct PrintedLineTests {
    private func publishedPieces() throws -> [Piece] {
        let server =
            ProcessInfo.processInfo.environment["FLOWBOT"]
            .map { URL(filePath: $0, directoryHint: .isDirectory) }
            ?? URL.homeDirectory.appending(path: "Developer/flowbot")
        let work =
            server
            .appending(path: "src/flowbot/shadowing/data/shakespeare-sonnets/work.yaml")
        return try WorkCorpus.decodeWork(String(contentsOf: work, encoding: .utf8)).pieces
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
