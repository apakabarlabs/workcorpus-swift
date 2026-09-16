import Foundation

public enum DrillStage: Int, CaseIterable, Identifiable, Sendable {
    case line
    case block

    public var id: Int { rawValue }

    public var label: String {
        switch self {
        case .line: return "line"
        case .block: return "block"
        }
    }
}

extension Piece {
    /// The line ranges a reader takes in one attempt at this stage.
    ///
    /// Line by line needs no saying, so a work names only the cuts that group lines,
    /// and it names them itself: how a sonnet falls into quatrains, a stanza into
    /// couplets or a scene into speeches is the work's own shape, not a rule anyone
    /// outside it can compute. A stage a work says nothing about is read line by line.
    public func cuts(for stage: DrillStage) -> [ClosedRange<Int>] {
        guard stage != .line, let sizes = cutSizes[stage.label], !sizes.isEmpty else {
            return lines.indices.map { $0...$0 }
        }

        var ranges: [ClosedRange<Int>] = []
        var start = 0
        for size in sizes {
            let end = min(start + size - 1, lines.count - 1)
            guard start <= end else { break }
            ranges.append(start...end)
            start = end + 1
        }
        if start <= lines.count - 1 {
            ranges.append(start...(lines.count - 1))
        }
        return ranges
    }
}
