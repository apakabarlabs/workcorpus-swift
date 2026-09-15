import Foundation
import ReadAloudKit
import Testing

@testable import SonnetCorpus

struct PrintedLineTests {
    private func publishedSonnets() throws -> [Sonnet] {
        let server = ProcessInfo.processInfo.environment["FLOWBOT"]
            .map { URL(filePath: $0, directoryHint: .isDirectory) }
            ?? URL.homeDirectory.appending(path: "Developer/flowbot")
        let work = server
            .appending(path: "src/flowbot/shadowing/data/shakespeare-sonnets/work.yaml")
        return try SonnetCorpus.decodeWork(String(contentsOf: work, encoding: .utf8)).sonnets
    }

    @Test("no mark of any printed line is left standing alone")
    func keepsEveryMarkWithAWord() throws {
        for sonnet in try publishedSonnets() {
            for (index, line) in sonnet.lines.enumerated() {
                let withWords = WordTokenizer.latinScript.segments(in: line).filter { $0.wordIndex != nil }

                #expect(
                    withWords.map(\.wordWithMarks).joined() == String(line.filter { !$0.isWhitespace }),
                    "sonnet \(sonnet.number), line \(index + 1): \(line)"
                )
            }
        }
    }
}
