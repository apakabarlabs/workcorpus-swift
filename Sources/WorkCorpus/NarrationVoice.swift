import Foundation

public struct NarrationVoice: RawRepresentable, Hashable, Sendable, Codable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }
}

extension NarrationVoice {
    public static let onyx = NarrationVoice(rawValue: "onyx")

    public static let all: [NarrationVoice] = [.onyx]
}
