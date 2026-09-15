import Foundation
import Testing
@testable import SonnetCorpus

struct WorkFileTests {
    private let work = """
    slug: shakespeare-sonnets
    language: eng
    title: Shakespeare's Sonnets
    reading:
      untouched_below: 0.001
      begun_below: 0.5
      most_below: 1.0
      difficult_word_score: 3
      shortest_attempt_seconds: 0.2
      free:
      - '1'
      - '18'
    sections:
    - title: The Procreation Sonnets
      short: The Procreation
      summary: Marry, and let your beauty outlive you.
      pieces:
      - id: '1'
        title: Sonnet 1
        lines:
        - From fairest creatures we desire increase,
        - That thereby beauty’s rose might never die,
      - id: '2'
        title: Sonnet 2
        lines:
        - When forty winters shall besiege thy brow,
    - title: The Fair Youth
      summary: The poet writes to the young man.
      pieces:
      - id: '3'
        title: Sonnet 3
        lines:
        - Look in thy glass and tell the face thou viewest
    """

    @Test("the sonnets come out of the work file numbered and in order")
    func sonnets() throws {
        let book = try SonnetCorpus.assembleWork(work)

        #expect(book.sonnets.map(\.number) == [1, 2, 3])
        #expect(book.sonnets[1].lines == ["When forty winters shall besiege thy brow,"])
    }

    @Test("a part covers the sonnets under it and keeps its two names")
    func parts() throws {
        let book = try SonnetCorpus.assembleWork(work)

        #expect(book.groups.map(\.title) == ["The Procreation Sonnets", "The Fair Youth"])
        #expect(book.groups[0].shortTitle == "The Procreation")
        #expect(book.groups[0].sonnets == 1...2)
        #expect(book.groups[1].shortTitle == "The Fair Youth")
    }

    @Test("the numbers the drill reads come off the reading block")
    func thresholds() throws {
        let book = try SonnetCorpus.assembleWork(work)

        #expect(book.free == [1, 18])
        #expect(book.stageField.band(for: 0.0005) == .untouched)
        #expect(book.difficultWords.scoreThreshold == 3)
        #expect(book.listening.shortestAttemptSeconds == 0.2)
    }

    @Test("a piece that is not a numbered poem is refused rather than renumbered")
    func unnumberedPiece() throws {
        let prose = work.replacingOccurrences(of: "id: '3'", with: "id: prologue")

        #expect(throws: SonnetCorpus.WorkError.pieceIsNotASonnet("prologue")) {
            try SonnetCorpus.assembleWork(prose)
        }
    }

    @Test("a work file short of the sequence is refused by the rules the book is held to")
    func heldToTheSameRules() throws {
        #expect(throws: SonnetCorpus.CorpusError.wrongSonnetCount(3)) {
            try SonnetCorpus.decodeWork(work)
        }
    }
}
