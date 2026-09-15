import Foundation
import ReadAloudKit

public struct Sonnet: Decodable, Identifiable, Sendable, Equatable {
    public let number: Int
    public let lines: [String]

    public var id: Int { number }

    public var title: String { "Sonnet \(number)" }

    public var openingLine: String { lines.first ?? "" }

    public var passage: Passage { Passage(lines: lines) }

    public init(number: Int, lines: [String]) {
        self.number = number
        self.lines = lines
    }
}

public enum SonnetCorpus {
    public static let count = 154
    static let standardLineCount = 14
    static let sonnetOpeningOnFiveLines = 99
    static let sonnetOfSixCouplets = 126
    static let irregularLineCounts: [Int: Int] = [
        sonnetOpeningOnFiveLines: 15,
        sonnetOfSixCouplets: 12
    ]

    public enum CorpusError: LocalizedError, Equatable {
        case wrongSonnetCount(Int)
        case wrongLineCount(sonnet: Int, lines: Int)
        case outOfOrder(expected: Int, found: Int)

        public var errorDescription: String? {
            switch self {
            case .wrongSonnetCount(let found):
                return "Expected \(SonnetCorpus.count) sonnets, found \(found)."
            case .wrongLineCount(let sonnet, let lines):
                return "Sonnet \(sonnet) has \(lines) lines."
            case .outOfOrder(let expected, let found):
                return "Expected sonnet \(expected), found \(found)."
            }
        }
    }

    public static func validate(_ sonnets: [Sonnet]) throws {
        guard sonnets.count == count else {
            throw CorpusError.wrongSonnetCount(sonnets.count)
        }
        for (index, sonnet) in sonnets.enumerated() {
            let expectedNumber = index + 1
            guard sonnet.number == expectedNumber else {
                throw CorpusError.outOfOrder(expected: expectedNumber, found: sonnet.number)
            }
            let expectedLines = expectedLineCount(for: sonnet.number)
            guard sonnet.lines.count == expectedLines else {
                throw CorpusError.wrongLineCount(sonnet: sonnet.number, lines: sonnet.lines.count)
            }
        }
    }

    public static func expectedLineCount(for sonnet: Int) -> Int {
        irregularLineCounts[sonnet] ?? standardLineCount
    }
}
