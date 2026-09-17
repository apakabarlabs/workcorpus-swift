import Foundation

public struct NarrationVoice: RawRepresentable, Hashable, Sendable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let onyx = Self(rawValue: "onyx")

    public static let all: [Self] = [.onyx]
}
