import Foundation

public struct SonnetGroup: Decodable, Identifiable, Sendable, Equatable {
    public let title: String
    public let summary: String
    public let first: Int
    public let last: Int
    private let short: String?

    public var shortTitle: String { short ?? title }

    public var sonnets: ClosedRange<Int> { first...last }

    public var id: Int { first }

    public func contains(sonnet: Int) -> Bool { sonnets.contains(sonnet) }

    public init(title: String, summary: String, first: Int, last: Int, short: String? = nil) {
        self.title = title
        self.summary = summary
        self.first = first
        self.last = last
        self.short = short
    }
}

extension SonnetCorpus {
    public static func group(of sonnet: Int, in groups: [SonnetGroup]) -> SonnetGroup? {
        groups.first { $0.contains(sonnet: sonnet) }
    }
}
