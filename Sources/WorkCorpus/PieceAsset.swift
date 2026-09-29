import Foundation

/// Names the files of one work: its readings, their word times, and what a reader
/// shares of their own attempt.
///
/// The stem is the work's, because the files of two works sit side by side on a phone
/// and in a bucket, and a name that says only a number says nothing about which work
/// the number belongs to.
///
/// Names are compared in Unicode normalization form C, so a stem and a name that spell
/// the same letters with precomposed and combining marks still match. Only the ASCII
/// digits `0` to `9` are read as the digits of a piece number.
public struct PieceAsset: Sendable {
    /// Work-specific prefix placed in every generated asset name.
    public let stem: String

    /// Creates a naming scheme for one work.
    public init(stem: String) {
        self.stem = stem
    }

    /// Returns the zero-padded base name of a numbered piece.
    public func name(_ piece: Int) -> String {
        "\(stem)-" + Self.padded(piece, to: 3)
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
        let place = "s\(Self.padded(piece, to: 3))-l\(Self.padded(line, to: 2))"
        let said = Self.slug(heard ?? "")
        return said.isEmpty ? place : "\(place)-\(said)"
    }

    private static func padded(_ number: Int, to width: Int) -> String {
        let digits = String(number.magnitude)
        let sign = number < 0 ? "-" : ""
        let zeros = String(repeating: "0", count: max(0, width - sign.count - digits.count))
        return sign + zeros + digits
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
        let bare = Self.withoutExtension(name)
        let prefix = Array("\(stem.precomposedStringWithCanonicalMapping)-".unicodeScalars)
        guard bare.starts(with: prefix) else { return nil }
        let digits = bare.dropFirst(prefix.count).prefix(while: Self.isDigit)
        return Int(String(String.UnicodeScalarView(digits)))
    }

    /// Extracts the voice suffix from an alignment filename.
    ///
    /// Pass the filename returned by ``alignment(_:voice:)``. Recording paths and
    /// shared-attempt names do not have the supported shape.
    public func voice(inName name: String) -> NarrationVoice? {
        let bare = Self.withoutExtension(name)
        guard let dash = bare.lastIndex(of: "-"), dash != bare.startIndex else { return nil }
        let tail = bare[(dash + 1)...]
        return tail.allSatisfy(Self.isDigit)
            ? nil : NarrationVoice(rawValue: String(String.UnicodeScalarView(tail)))
    }

    private static func isDigit(_ scalar: Unicode.Scalar) -> Bool {
        ("0"..."9").contains(scalar)
    }

    private static func withoutExtension(_ name: String) -> [Unicode.Scalar] {
        let scalars = Array(name.precomposedStringWithCanonicalMapping.unicodeScalars)
        guard let dot = scalars.lastIndex(of: "."), dot != 0, !scalars[dot...].contains("/")
        else {
            return scalars
        }
        return Array(scalars[..<dot])
    }
}
