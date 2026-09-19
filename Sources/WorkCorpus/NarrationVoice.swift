import Foundation

/// Stable identifier of a narration voice used in asset names.
public struct NarrationVoice: RawRepresentable, Hashable, Sendable, Codable {
    /// Identifier used verbatim in generated asset names.
    ///
    /// Callers are responsible for supplying a value that is safe as a path component.
    public let rawValue: String

    /// Creates a voice whose identifier is used verbatim in generated asset names.
    ///
    /// Callers are responsible for supplying a value that is safe as a path component.
    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    /// The built-in Onyx narration voice.
    public static let onyx = Self(rawValue: "onyx")

    /// Built-in narration voices known to this release.
    public static let all: [Self] = [.onyx]
}
