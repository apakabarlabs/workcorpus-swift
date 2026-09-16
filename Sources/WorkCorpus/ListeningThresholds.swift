import Foundation

public struct ListeningThresholds: Decodable, Sendable, Equatable {
    public let shortestAttemptSeconds: Double

    private enum CodingKeys: String, CodingKey {
        case shortestAttemptSeconds = "shortest_attempt_seconds"
    }

    public init(shortestAttemptSeconds: Double) {
        self.shortestAttemptSeconds = shortestAttemptSeconds
    }

    public func isAccidentalTap(seconds: Double) -> Bool { seconds <= shortestAttemptSeconds }
}
