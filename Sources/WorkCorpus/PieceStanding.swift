import ReadAloudKit

/// How far a reader has come through one piece: where each stage of the drill stands.
public struct PieceStanding: Equatable, Sendable {
    public let stages: [StageState]

    public init(stages: [StageState]) {
        self.stages = DrillStage.allCases.indices.map {
            $0 < stages.count ? stages[$0] : .untouched
        }
    }

    public init(stored: [Int]) {
        self.init(stages: stored.map(StageState.init(stored:)))
    }

    public func state(of stage: DrillStage) -> StageState {
        stages[stage.rawValue]
    }

    public var stagesCleared: Int { stages.filter { $0 == .complete }.count }
    public var totalStages: Int { stages.count }
    public var isComplete: Bool { stages.contains(.complete) }
    public var isStarted: Bool { stages.contains { $0 != .untouched } }

    public static let untouched = PieceStanding(stages: [])
}
