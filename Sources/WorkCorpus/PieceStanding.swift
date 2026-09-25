import ReadAloudKit

/// How far a reader has come through one piece at each reading stage.
public struct PieceStanding: Equatable, Sendable {
    /// One state per known reading stage, in the order of `ReadingStage.allCases`.
    public let stages: [StageState]

    /// Creates standing for the reading stages known to this release.
    ///
    /// Omitted stages are padded with `.untouched`; values beyond the known stages
    /// are discarded.
    public init(stages: [StageState]) {
        self.stages = ReadingStage.allCases.indices.map { index in
            index < stages.count ? stages[index] : .untouched
        }
    }

    /// Restores raw states for the reading stages known to this release.
    ///
    /// Omitted stages are padded with `.untouched`; values beyond the known stages
    /// are discarded.
    /// - Precondition: Every value is a valid `StageState` raw value.
    public init(stored: [Int]) {
        self.init(stages: stored.map(StageState.init(stored:)))
    }

    /// Returns the state associated with a reading stage.
    public func state(of stage: ReadingStage) -> StageState {
        stages[stage.rawValue]
    }

    /// Number of complete stages.
    public var stagesCleared: Int { stages.filter { $0 == .complete }.count }
    /// Number of stages represented by this release.
    public var totalStages: Int { stages.count }
    /// Whether at least one stage is complete.
    public var isComplete: Bool { stages.contains(.complete) }
    /// Whether any stage has been attempted.
    public var isStarted: Bool { stages.contains { $0 != .untouched } }

    /// Standing with every known stage untouched.
    public static let untouched = Self(stages: [])
}
