import Foundation

public enum SonnetAsset {
    public static func name(_ sonnet: Int) -> String {
        String(format: "sonnet-%03d", sonnet)
    }

    public static func recording(_ sonnet: Int, voice: NarrationVoice) -> String {
        "\(voice.rawValue)/\(name(sonnet)).mp3"
    }

    public static func alignment(_ sonnet: Int, voice: NarrationVoice) -> String {
        "\(name(sonnet))-\(voice.rawValue).json"
    }

    public static func sharedReading(sonnet: Int, line: Int, heard: String?) -> String {
        let place = String(format: "s%03d-l%02d", sonnet, line)
        let said = slug(heard ?? "")
        return said.isEmpty ? place : "\(place)-\(said)"
    }

    private static func slug(_ text: String) -> String {
        let wordsWorthReadingInAFileName = 8
        let letters = String(text.lowercased().map { $0.isLetter || $0.isNumber ? $0 : " " })
        return letters.split(separator: " ").prefix(wordsWorthReadingInAFileName).joined(separator: "-")
    }

    public static func number(inName name: String) -> Int? {
        let stem = (name as NSString).deletingPathExtension
        guard stem.hasPrefix("sonnet-") else { return nil }
        return Int(stem.dropFirst("sonnet-".count).prefix { $0.isNumber })
    }

    public static func voice(inName name: String) -> NarrationVoice? {
        let stem = (name as NSString).deletingPathExtension
        guard let dash = stem.lastIndex(of: "-"), dash != stem.startIndex else { return nil }
        let tail = String(stem[stem.index(after: dash)...])
        return tail.allSatisfy(\.isNumber) ? nil : NarrationVoice(rawValue: tail)
    }
}
