import Foundation
import Yams

/// A reading work and the configuration used to present it.
///
/// Decode through ``WorkCorpus/decodeWork(_:)`` or
/// ``WorkCorpus/decodeWorkFromBook(_:)`` to validate the complete work before use.
/// Decoding this type directly does not validate relationships between its fields.
///
/// Every number a work carries, from piece numbers to cut sizes, is a YAML integer that
/// fits in 32 bits, written as plain decimal digits: `0`, or digits that do not start
/// with `0` after an optional `-`. A `+`, `-0`, underscores, `0x`, `0o` or `0b`
/// prefixes and sexagesimal `1:30` are refused, so that every port reads a number the
/// same way.
///
/// Decoded from JSON, a number is a JSON number whose value is a whole number that fits
/// in 32 bits, so `5` and `5.0` both read as 5. A string such as `"5"`, a boolean,
/// null, a fraction, a value past 32 bits and `-0` are refused as in YAML. The value
/// is taken exactly as written, so `5.000000000000000001` is a fraction.
///
/// The stage field bounds are fractions held to the same one writing: in YAML, plain
/// decimal digits with an optional `-` and fractional part, such as `0.001` or `1`,
/// and never quoted, with `_`, an exponent or as sexagesimal; in JSON, a JSON number.
///
/// A work is written out in full. A YAML anchor, an alias or a `<<` merge key, quoted
/// or not, is refused with ``WorkCorpus/WorkShapeError/yamlReference(place:)``, since
/// YAML readers do not resolve them alike.
public struct Work: Decodable, Sendable {
    /// Language the work is written in, as the work names it: a language tag such as
    /// `en`, `eng` or `en-GB`.
    ///
    /// It arrives with the work rather than being assumed, because the same reading
    /// mechanics carry works in other languages.
    public let language: String
    /// Reading pieces, expected to be numbered from one and ordered by number.
    public let pieces: [Piece]
    /// Parts, expected to cover the pieces consecutively and exactly once.
    public let parts: [Part]
    /// Piece numbers intended to be available without purchase.
    public let free: [Int]
    /// Thresholds used to display stage progress.
    public let stageField: StageFieldScale
    /// Threshold used to identify difficult words.
    public let difficultWords: DifficultWordsConfiguration

    private enum CodingKeys: String, CodingKey {
        case language
        case pieces
        case parts
        case free
        case stageField = "stage_field"
        case difficultWords = "difficult_words"
    }

    init(
        language: String,
        pieces: [Piece],
        parts: [Part],
        free: [Int],
        stageField: StageFieldScale,
        difficultWords: DifficultWordsConfiguration
    ) {
        self.language = language
        self.pieces = pieces
        self.parts = parts
        self.free = free
        self.stageField = stageField
        self.difficultWords = difficultWords
    }

    /// Decodes a work without validating the relationships between its fields.
    ///
    /// - Throws: `DecodingError` when a field is missing or is not text where text
    ///   belongs; ``WorkCorpus/WorkShapeError`` naming the field when a number is not a
    ///   whole number within 32 bits, a fraction is not written in plain digits, a text
    ///   is null, or when a piece or part is out of shape.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        language = try values.decode(Text.self, forKey: .language).value
        pieces = try values.decode([Piece].self, forKey: .pieces)
        parts = try values.decode([Part].self, forKey: .parts)
        free = try values.decode([WholeNumber].self, forKey: .free).map(\.value)
        stageField = try values.decode(StageFieldScale.self, forKey: .stageField)
        difficultWords = try values.decode(
            DifficultWordsConfiguration.self,
            forKey: .difficultWords
        )
    }
}

/// Configuration for classifying repeatedly missed words.
public struct DifficultWordsConfiguration: Decodable, Sendable {
    /// Minimum accumulated score at which a word is difficult.
    public let scoreThreshold: Int

    private enum CodingKeys: String, CodingKey {
        case scoreThreshold = "score_threshold"
    }

    /// Creates a threshold without validating it against a work.
    public init(scoreThreshold: Int) {
        self.scoreThreshold = scoreThreshold
    }

    /// Decodes a threshold.
    ///
    /// - Throws: `DecodingError` when the threshold is missing;
    ///   ``WorkCorpus/WorkShapeError`` naming the field when it is not a YAML integer
    ///   within 32 bits.
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scoreThreshold = try values.decode(WholeNumber.self, forKey: .scoreThreshold).value
    }
}

extension WorkCorpus {
    /// The work, or one of its pieces, is not shaped the way a work has to be.
    public enum WorkShapeError: LocalizedError, Equatable {
        /// The parts leave a gap, overlap, or stop short of the last piece.
        case partsDoNotCoverTheWork
        /// A part does not start at piece one or later, ends before it starts, or runs
        /// past the last piece of the work.
        case partOutOfRange(first: Int, last: Int)
        /// The free pieces are empty, repeated, or outside the work.
        case invalidFreePieces
        /// The stage field bounds are not increasing values between zero and one.
        case invalidStageFieldScale
        case invalidDifficultWordThreshold
        /// A field that holds a number holds something else: a quoted string, a float,
        /// a boolean, null, a list or a mapping, an integer that does not fit in 32 bits,
        /// or one not written as plain decimal digits.
        case invalidNumber(place: String)
        case invalidLanguage(String)
        case cutsForUnknownStage(piece: Int, stage: String)
        /// A piece is cut for the line stage, which is never cut.
        case cutsForLineStage(piece: Int)
        /// A piece has a cut of zero or fewer lines at a stage.
        case emptyCut(piece: Int, stage: String, size: Int)
        case cutsDoNotCoverThePiece(piece: Int, stage: String, cut: Int, lines: Int)
        /// A value is given a YAML anchor, taken from an alias, or merged in with a `<<`
        /// key. YAML readers resolve these differently, so a work writes every value out
        /// where it belongs; the place is the anchored value or the merging mapping.
        case yamlReference(place: String)
        /// A field that holds text is null: written as `~`, `null` or left empty. Empty
        /// text is written as `""`.
        case nullText(place: String)
        /// A field that holds a fraction holds something else: a quoted string, a
        /// boolean, null, or in YAML a number written other than as plain decimal digits
        /// with an optional fractional part, such as `0.5_0`, `.5`, `5e-1` or `1:00`.
        case invalidFraction(place: String)
        /// A YAML mapping names the same key more than once.
        case repeatedKey(String)

        /// Reader-facing description naming what is wrong and where.
        public var errorDescription: String? {
            switch self {
            case .partsDoNotCoverTheWork:
                "The parts do not cover the work exactly once."

            case let .partOutOfRange(first, last):
                "A part runs from piece \(first) to piece \(last), "
                    + "which is not a range of pieces in the work."

            case .invalidFreePieces:
                "The list of pieces free to read is empty, repeated, or outside the work."

            case .invalidStageFieldScale:
                "The stage field bounds are not increasing values between zero and one."

            case .invalidDifficultWordThreshold:
                "The difficult-word score threshold must be positive."

            case let .invalidNumber(place):
                "The work's \(place) is not a whole number that fits in 32 bits."

            case let .invalidLanguage(value):
                "The work names its language as \"\(Self.shown(value))\", "
                    + "which is not a language tag such as en, eng or en-GB."

            case let .cutsForUnknownStage(piece, stage):
                "Piece \(piece) is cut for a stage called \(stage), which is not a reading stage."

            case let .cutsForLineStage(piece):
                "Piece \(piece) is cut for the line stage, which is read one line at a time."

            case let .emptyCut(piece, stage, size):
                "Piece \(piece) has a \(stage) cut of \(size) lines; a cut holds at least one."

            case let .cutsDoNotCoverThePiece(piece, stage, cut, lines):
                "Piece \(piece) is cut at the \(stage) stage into \(cut) lines, but it has \(lines)."

            case let .yamlReference(place):
                "The work's \(place) is written with a YAML anchor, alias or merge key; "
                    + "a work writes each value out where it belongs."

            case let .nullText(place):
                "The work's \(place) is null where text belongs; "
                    + "an empty text is written as \"\"."

            case let .invalidFraction(place):
                "The work's \(place) is not a decimal number written as plain digits."

            case let .repeatedKey(key):
                "The work names \(key) more than once in one mapping."
            }
        }

        private static func shown(_ value: String) -> String {
            value.unicodeScalars.map { scalar in
                (0x20...0x7E).contains(scalar.value) && scalar != "\"" && scalar != "\\"
                    ? String(scalar) : "\\u{\(String(scalar.value, radix: 16, uppercase: true))}"
            }.joined()
        }
    }

    /// Decodes an assembled book YAML document and validates the resulting work.
    ///
    /// - Throws: `DecodingError` when the document is not YAML, or a field is missing
    ///   or is not text where text belongs; ``WorkShapeError`` when a number is not a
    ///   YAML integer within 32 bits, a fraction is not written in plain digits, a text
    ///   is null, a key is repeated, a value is written with a YAML anchor, alias or
    ///   merge key, a piece's cuts do not divide its lines, or the parts, free pieces,
    ///   thresholds or language are not shaped as a work's must be; ``CorpusError``
    ///   when the pieces are not numbered from one in order.
    public static func decodeWorkFromBook(_ yaml: String) throws -> Work {
        let work = try decodeYAML(Work.self, from: yaml)
        try validate(work.pieces)
        try validateConfiguration(work)
        return work
    }

    static func decodeYAML<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        try decoding {
            let parser: Parser
            let root: Node
            do {
                parser = try Parser(yaml: yaml, resolver: Resolver.basic.appending(.merge))
                root = try parser.singleRoot() ?? ""
            } catch YamlError.duplicatedKeysInMapping(let duplicates, _) {
                throw WorkShapeError.repeatedKey(duplicates.sorted().first ?? "")
            } catch let error as YamlError {
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [],
                        debugDescription: "The given data was not valid YAML.",
                        underlyingError: error
                    )
                )
            }
            return try withExtendedLifetime(parser) {
                try refuseReferences(in: root, at: "")
                return try YAMLDecoder().decode(type, from: root)
            }
        }
    }

    private static func refuseReferences(in node: Node, at place: String) throws {
        guard node.anchor == nil else {
            throw WorkShapeError.yamlReference(place: place.isEmpty ? "top level" : place)
        }
        switch node {
        case .mapping(let mapping):
            for (key, value) in mapping {
                guard key.anchor == nil, key.string != "<<" else {
                    throw WorkShapeError.yamlReference(place: place.isEmpty ? "top level" : place)
                }
                let name = key.string ?? ""
                try refuseReferences(in: value, at: place.isEmpty ? name : "\(place).\(name)")
            }
        case .sequence(let sequence):
            for (index, item) in sequence.enumerated() {
                try refuseReferences(in: item, at: "\(place)[\(index)]")
            }
        default:
            break
        }
    }

    static func decoding<T>(_ decode: () throws -> T) throws -> T {
        do {
            return try decode()
        } catch DecodingError.dataCorrupted(let context) {
            if let shape = context.underlyingError as? WorkShapeError { throw shape }
            throw DecodingError.dataCorrupted(context)
        }
    }

    static func place(_ path: [CodingKey]) -> String {
        path.enumerated().map { index, key in
            if let position = key.intValue, key.stringValue.hasPrefix("Index ") {
                return "[\(position)]"
            }
            return index == 0 ? key.stringValue : ".\(key.stringValue)"
        }.joined()
    }

    static func fitsIn32Bits(_ number: Int) -> Bool {
        (Int(Int32.min)...Int(Int32.max)).contains(number)
    }

    static func validateConfiguration(_ work: Work) throws {
        var next = 1
        for part in work.parts {
            guard part.first == next, part.last >= part.first else {
                throw WorkShapeError.partsDoNotCoverTheWork
            }
            guard part.last <= work.pieces.count else {
                throw WorkShapeError.partOutOfRange(first: part.first, last: part.last)
            }
            next = part.last + 1
        }
        guard next == work.pieces.count + 1 else { throw WorkShapeError.partsDoNotCoverTheWork }

        let free = Set(work.free)
        let numbered = 1..<(work.pieces.count + 1)
        guard !free.isEmpty, free.count == work.free.count, free.allSatisfy(numbered.contains)
        else {
            throw WorkShapeError.invalidFreePieces
        }

        let scale = work.stageField
        guard scale.untouchedBelow > 0,
            scale.untouchedBelow < scale.begunBelow,
            scale.begunBelow < scale.mostBelow,
            scale.mostBelow <= 1
        else { throw WorkShapeError.invalidStageFieldScale }

        guard fitsIn32Bits(work.difficultWords.scoreThreshold) else {
            throw WorkShapeError.invalidNumber(place: "difficult_words.score_threshold")
        }
        guard work.difficultWords.scoreThreshold > 0 else {
            throw WorkShapeError.invalidDifficultWordThreshold
        }

        guard isLanguageTag(work.language) else {
            throw WorkShapeError.invalidLanguage(work.language)
        }
    }

    private static func isLanguageTag(_ value: String) -> Bool {
        let subtags = Array(value.unicodeScalars).split(
            separator: "-",
            omittingEmptySubsequences: false
        )
        guard let language = subtags.first, (2...3).contains(language.count),
            language.allSatisfy({ ("a"..."z").contains($0) })
        else {
            return false
        }
        return subtags.dropFirst().allSatisfy { subtag in
            (2...8).contains(subtag.count)
                && subtag.allSatisfy {
                    ("a"..."z").contains($0) || ("A"..."Z").contains($0) || ("0"..."9").contains($0)
                }
        }
    }

    static func validateCuts(piece: Int, lines: Int, cutSizes: [String: [Int]]) throws {
        let labels = cutSizes.sorted {
            $0.key.unicodeScalars.lexicographicallyPrecedes($1.key.unicodeScalars)
        }
        for (label, sizes) in labels {
            guard let stage = ReadingStage.allCases.first(where: { $0.label == label }) else {
                throw WorkShapeError.cutsForUnknownStage(piece: piece, stage: label)
            }
            guard stage != .line else {
                throw WorkShapeError.cutsForLineStage(piece: piece)
            }
            guard sizes.allSatisfy(fitsIn32Bits) else {
                throw WorkShapeError.invalidNumber(place: "piece \(piece) \(label) cut")
            }
            if let empty = sizes.first(where: { $0 <= 0 }) {
                throw WorkShapeError.emptyCut(piece: piece, stage: label, size: empty)
            }
            let cut = min(sizes.reduce(0, +), Int(Int32.max))
            guard cut == lines else {
                throw WorkShapeError.cutsDoNotCoverThePiece(
                    piece: piece,
                    stage: label,
                    cut: cut,
                    lines: lines
                )
            }
        }
    }
}
