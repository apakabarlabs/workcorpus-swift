import Foundation
import Testing
@testable import SonnetCorpus

struct SonnetSequenceTests {
    private let groups = [
        SonnetGroup(
            title: "The Procreation Sonnets",
            summary: "Marry, and let your beauty outlive you.",
            first: 1,
            last: 17,
            short: "The Procreation"
        ),
        SonnetGroup(
            title: "The Fair Youth",
            summary: "Praise, and the verse that outlasts what it praises.",
            first: 18,
            last: 77
        )
    ]

    @Test("a part carries its range and the sonnets inside it")
    func partHoldsItsSonnets() {
        #expect(groups.first?.sonnets == 1...17)
        #expect(groups.first?.contains(sonnet: 17) == true)
        #expect(groups.first?.contains(sonnet: 18) == false)
    }

    @Test("the short name stands in for the full one, and the full one fills its place")
    func shortNameFallsBackToTheFullOne() {
        #expect(groups.first?.shortTitle == "The Procreation")
        #expect(groups.last?.shortTitle == "The Fair Youth")
    }

    @Test("a sonnet finds the part it belongs to")
    func sonnetFindsItsGroup() {
        #expect(SonnetCorpus.group(of: 1, in: groups)?.title == "The Procreation Sonnets")
        #expect(SonnetCorpus.group(of: 130, in: groups) == nil)
    }
}
