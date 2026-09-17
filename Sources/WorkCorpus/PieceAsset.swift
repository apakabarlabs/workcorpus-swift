import Foundation

/// Names the files of one work: its readings, their word times, and what a reader
/// shares of their own attempt.
///
/// The stem is the work's, because the files of two works sit side by side on a phone
/// and in a bucket, and a name that says only a number says nothing about which work
/// the number belongs to.
public struct PieceAsset: Sendable {
    public let stem: String

    public init(stem: String) {
        self.stem = stem
    }

    public func name(_ piece: Int) -> String {
        String(format: "\(stem)-%03d", piece)
    }

    public func recording(_ piece: Int, voice: NarrationVoice) -> String {
        "\(voice.rawValue)/\(name(piece)).mp3"
    }

    public func alignment(_ piece: Int, voice: NarrationVoice) -> String {
        "\(name(piece))-\(voice.rawValue).json"
    }

    public func sharedReading(piece: Int, line: Int, heard: String?) -> String {
        let place = String(format: "s%03d-l%02d", piece, line)
        let said = Self.slug(heard ?? "")
        return said.isEmpty ? place : "\(place)-\(said)"
    }

    private static func slug(_ text: String) -> String {
        let wordsWorthReadingInAFileName = 8
        let letters = String(text.lowercased().map { $0.isLetter || $0.isNumber ? $0 : " " })
        return letters.split(separator: " ").prefix(wordsWorthReadingInAFileName).joined(
            separator: "-"
        )
    }

    public func number(inName name: String) -> Int? {
        let withoutExtension = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
        guard withoutExtension.hasPrefix("\(stem)-") else { return nil }
        return Int(withoutExtension.dropFirst(stem.count + 1).prefix(while: \.isNumber))
    }

    public func voice(inName name: String) -> NarrationVoice? {
        let withoutExtension = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
        guard let dash = withoutExtension.lastIndex(of: "-"), dash != withoutExtension.startIndex
        else {
            return nil
        }
        let tail = String(withoutExtension[withoutExtension.index(after: dash)...])
        return tail.allSatisfy(\.isNumber) ? nil : NarrationVoice(rawValue: tail)
    }
}
