import Foundation

struct WholeNumber: Decodable {
    let value: Int

    init(from decoder: Decoder) throws {
        let place = WorkCorpus.place(decoder.codingPath)
        let container = try decoder.singleValueContainer()
        let number: Int32?
        do {
            if let written = try writtenText(in: container) {
                _ = try container.decode(Int32.self)
                number = Self.isPlainDecimal(written) ? Int32(written) : nil
            } else {
                let sign = try container.decode(Double.self).sign
                let whole = Self.whole(try container.decode(Decimal.self))
                number = whole == 0 && sign == .minus ? nil : whole
            }
        } catch {
            throw WorkCorpus.WorkShapeError.invalidNumber(place: place)
        }
        guard let number else { throw WorkCorpus.WorkShapeError.invalidNumber(place: place) }
        value = Int(number)
    }

    static func isPlainDecimal(_ written: String) -> Bool {
        let scalars = written.unicodeScalars[...]
        let digits = scalars.first == "-" ? scalars.dropFirst() : scalars
        guard let first = digits.first, digits.allSatisfy({ ("0"..."9").contains($0) }) else {
            return false
        }
        return first != "0" || written == "0"
    }

    private static func whole(_ exact: Decimal) -> Int32? {
        var exact = exact
        var rounded = Decimal()
        NSDecimalRound(&rounded, &exact, 0, .plain)
        guard rounded == exact, exact >= Decimal(Int(Int32.min)), exact <= Decimal(Int(Int32.max))
        else {
            return nil
        }
        return NSDecimalNumber(decimal: exact).int32Value
    }
}

struct Fraction: Decodable {
    let value: Double

    init(from decoder: Decoder) throws {
        let place = WorkCorpus.place(decoder.codingPath)
        let container = try decoder.singleValueContainer()
        let written: String?
        do {
            value = try container.decode(Double.self)
            written = try writtenText(in: container)
        } catch {
            throw WorkCorpus.WorkShapeError.invalidFraction(place: place)
        }
        guard value.isFinite, written.map(Self.isPlainFraction) ?? true else {
            throw WorkCorpus.WorkShapeError.invalidFraction(place: place)
        }
    }

    private static func isPlainFraction(_ written: String) -> Bool {
        let parts = written.split(separator: ".", maxSplits: 1, omittingEmptySubsequences: false)
        guard WholeNumber.isPlainDecimal(String(parts[0])) || parts[0] == "-0" else { return false }
        guard parts.count == 2 else { return true }
        return !parts[1].isEmpty && parts[1].unicodeScalars.allSatisfy { ("0"..."9").contains($0) }
    }
}

struct Text: Decodable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        guard !container.decodeNil() else {
            throw WorkCorpus.WorkShapeError.nullText(place: WorkCorpus.place(decoder.codingPath))
        }
        value = try container.decode(String.self)
    }
}

private func writtenText(in container: SingleValueDecodingContainer) throws -> String? {
    do {
        return try container.decode(String.self)
    } catch DecodingError.typeMismatch {
        return nil
    }
}
