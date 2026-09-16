import Foundation

public struct StageFieldScale: Decodable, Sendable, Equatable {
    public let untouchedBelow: Double
    public let begunBelow: Double
    public let mostBelow: Double

    private enum CodingKeys: String, CodingKey {
        case untouchedBelow = "untouched_below"
        case begunBelow = "begun_below"
        case mostBelow = "most_below"
    }

    public init(untouchedBelow: Double, begunBelow: Double, mostBelow: Double) {
        self.untouchedBelow = untouchedBelow
        self.begunBelow = begunBelow
        self.mostBelow = mostBelow
    }

    public func band(for fraction: Double) -> Band {
        switch fraction {
        case ..<untouchedBelow: .untouched
        case ..<begunBelow: .begun
        case ..<mostBelow: .most
        default: .whole
        }
    }

    public enum Band: Sendable, Equatable {
        case untouched
        case begun
        case most
        case whole
    }
}
