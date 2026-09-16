import Foundation
import Testing
@testable import WorkCorpus

struct PartTests {
    private let parts = [
        Part(
            title: "The Procreation Sonnets",
            summary: "Marry, and let your beauty outlive you.",
            first: 1,
            last: 17,
            short: "The Procreation"
        ),
        Part(
            title: "The Fair Youth",
            summary: "Praise, and the verse that outlasts what it praises.",
            first: 18,
            last: 77
        )
    ]

    @Test("a part carries its range and the pieces inside it")
    func partHoldsItsPieces() {
        #expect(parts.first?.pieces == 1...17)
        #expect(parts.first?.contains(piece: 17) == true)
        #expect(parts.first?.contains(piece: 18) == false)
    }

    @Test("the short name stands in for the full one, and the full one fills its place")
    func shortNameFallsBackToTheFullOne() {
        #expect(parts.first?.shortTitle == "The Procreation")
        #expect(parts.last?.shortTitle == "The Fair Youth")
    }

    @Test("a piece finds the part it belongs to")
    func pieceFindsItsPart() {
        #expect(WorkCorpus.part(of: 1, in: parts)?.title == "The Procreation Sonnets")
        #expect(WorkCorpus.part(of: 130, in: parts) == nil)
    }
}
