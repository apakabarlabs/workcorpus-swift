import Foundation

/// Names the files of one work: its readings, their word times, and what a reader
/// shares of their own attempt.
///
/// The stem is the work's, because the files of two works sit side by side on a phone
/// and in a bucket, and a name that says only a number says nothing about which work
/// the number belongs to.
public struct PieceAsset: Sendable {
    /// Work-specific prefix placed in every generated asset name.
    public let stem: String

    /// Creates a naming scheme for one work.
    public init(stem: String) {
        self.stem = stem
    }

    /// Returns the zero-padded base name of a numbered piece.
    public func name(_ piece: Int) -> String {
        String(format: "\(stem)-%03d", piece)
    }

    /// Returns the relative MP3 path for a piece and narration voice.
    public func recording(_ piece: Int, voice: NarrationVoice) -> String {
        "\(voice.rawValue)/\(name(piece)).mp3"
    }

    /// Returns the JSON alignment filename for a piece and narration voice.
    public func alignment(_ piece: Int, voice: NarrationVoice) -> String {
        "\(name(piece))-\(voice.rawValue).json"
    }

    /// Returns a stable base name for a shared line attempt.
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

    /// Extracts a piece number from a filename belonging to this work.
    public func number(inName name: String) -> Int? {
        let withoutExtension = URL(fileURLWithPath: name).deletingPathExtension().lastPathComponent
        guard withoutExtension.hasPrefix("\(stem)-") else { return nil }
        return Int(withoutExtension.dropFirst(stem.count + 1).prefix(while: \.isNumber))
    }

    /// Extracts the voice suffix from an alignment filename.
    ///
    /// Pass the filename returned by ``alignment(_:voice:)``. Recording paths and
    /// shared-attempt names do not have the supported shape.
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
