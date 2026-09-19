import Foundation

/// Time limits used to distinguish a reading attempt from an accidental tap.
public struct ListeningThresholds: Decodable, Sendable, Equatable {
    /// Attempts at or below this duration, in seconds, are accidental taps.
    public let shortestAttemptSeconds: Double

    private enum CodingKeys: String, CodingKey {
        case shortestAttemptSeconds = "shortest_attempt_seconds"
    }

    /// Creates thresholds without validating them against a work.
    public init(shortestAttemptSeconds: Double) {
        self.shortestAttemptSeconds = shortestAttemptSeconds
    }

    /// Reports whether an attempt is too short to count as intended listening.
    public func isAccidentalTap(seconds: Double) -> Bool { seconds <= shortestAttemptSeconds }
}
