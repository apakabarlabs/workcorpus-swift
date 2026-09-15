import Foundation
import Testing
@testable import SonnetCorpus

struct StageFieldScaleTests {
    private let scale = StageFieldScale(untouchedBelow: 0.001, begunBelow: 0.5, mostBelow: 1.0)

    @Test("the configured bounds are exclusive")
    func bands() {
        #expect(scale.band(for: 0) == .untouched)
        #expect(scale.band(for: 0.001) == .begun)
        #expect(scale.band(for: 0.5) == .most)
        #expect(scale.band(for: 1) == .whole)
    }
}
