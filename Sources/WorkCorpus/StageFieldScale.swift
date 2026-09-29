import Foundation

/// Divides a stage-completion fraction into display bands.
public struct StageFieldScale: Decodable, Sendable, Equatable {
    /// Upper bound of the untouched band.
    public let untouchedBelow: Double
    /// Upper bound of the begun band.
    public let begunBelow: Double
    /// Upper bound of the mostly-complete band.
    public let mostBelow: Double

    private enum CodingKeys: String, CodingKey {
        case untouchedBelow = "untouched_below"
        case begunBelow = "begun_below"
        case mostBelow = "most_below"
    }

    /// Creates a scale without validating the order of its bounds.
    public init(untouchedBelow: Double, begunBelow: Double, mostBelow: Double) {
        self.untouchedBelow = untouchedBelow
        self.begunBelow = begunBelow
        self.mostBelow = mostBelow
    }

    /// Decodes a scale without validating the order of its bounds.
    ///
    /// - Throws: `DecodingError` when a bound is missing;
    ///   ``WorkCorpus/WorkShapeError`` naming the bound when it is not a number written
    ///   in plain decimal digits.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        untouchedBelow = try values.decode(Fraction.self, forKey: .untouchedBelow).value
        begunBelow = try values.decode(Fraction.self, forKey: .begunBelow).value
        mostBelow = try values.decode(Fraction.self, forKey: .mostBelow).value
    }

    /// Returns the display band containing `fraction`.
    public func band(for fraction: Double) -> Band {
        switch fraction {
        case ..<untouchedBelow: .untouched
        case ..<begunBelow: .begun
        case ..<mostBelow: .most
        default: .whole
        }
    }

    /// A coarse display state for a stage-completion fraction.
    public enum Band: Sendable, Equatable {
        /// Below the first configured bound.
        case untouched
        /// Between the first and second bounds.
        case begun
        /// Between the second and third bounds.
        case most
        /// At or above the third bound.
        case whole
    }
}
