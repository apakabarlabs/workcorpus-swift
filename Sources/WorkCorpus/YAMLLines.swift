import Foundation

struct YAMLLines {
    static let breaks: Set<Unicode.Scalar> = ["\n", "\r", "\u{85}", "\u{2028}", "\u{2029}"]

    let scalars: [Unicode.Scalar]
    let ends: [Int]

    init(_ yaml: String) {
        scalars = Array(yaml.unicodeScalars)
        var ends: [Int] = []
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            index += 1
            if scalar == "\r", index < scalars.count, scalars[index] == "\n" {
                index += 1
            }
            if Self.breaks.contains(scalar) {
                ends.append(index)
            }
        }
        if ends.last != scalars.count {
            ends.append(scalars.count)
        }
        self.ends = ends
    }

    var count: Int { ends.count }

    func leading(_ count: Int) -> String {
        String(String.UnicodeScalarView(scalars[..<ends[count - 1]]))
    }

    func index(line: Int, column: Int) -> Int? {
        guard line >= 1, line <= ends.count, column >= 1 else { return nil }
        let index = (line == 1 ? 0 : ends[line - 2]) + column - 1
        return index < ends[line - 1] ? index : nil
    }
}
