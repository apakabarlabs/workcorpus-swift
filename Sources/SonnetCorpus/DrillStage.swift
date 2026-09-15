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

extension Sonnet {
    public func pieces(for stage: DrillStage) -> [ClosedRange<Int>] {
        switch stage {
        case .line:
            return lines.indices.map { $0...$0 }
        case .block:
            return quatrainsAndClosingCouplet()
        }
    }

    private func quatrainsAndClosingCouplet() -> [ClosedRange<Int>] {
        let sizes: [Int]
        switch number {
        case SonnetCorpus.sonnetOpeningOnFiveLines: sizes = [5, 4, 4, 2]
        case SonnetCorpus.sonnetOfSixCouplets: sizes = [4, 4, 4]
        default: sizes = [4, 4, 4, 2]
        }
        var pieces: [ClosedRange<Int>] = []
        var start = 0
        for size in sizes {
            let end = min(start + size - 1, lines.count - 1)
            guard start <= end else { break }
            pieces.append(start...end)
            start = end + 1
        }
        return pieces
    }
}
