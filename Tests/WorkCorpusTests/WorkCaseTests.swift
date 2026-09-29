import Foundation
import Testing
import Yams

@testable import WorkCorpus

struct WorkCase: Decodable, Sendable, CustomTestStringConvertible {
    let name: String
    let source: String
    let replace: String?
    let with: String?
    let error: String?
    let refused: String?
    let read: WorkReadingCase?
    let breaks: String?

    var testDescription: String { name }

    private enum CodingKeys: String, CodingKey {
        case name = "case"
        case source = "fixture"
        case replace
        case with
        case error
        case refused
        case read
        case breaks
    }

    static func all() throws -> [Self] {
        try WorkCases.shared().cases
    }

    func document() throws -> String {
        let base = source == "json-book" ? try WorkCases.shared().jsonBook : try fixture(source)
        var document = base
        if let replace {
            #expect(
                base.components(separatedBy: replace).count == 2,
                "\(replace) is not in \(source) once"
            )
            document = base.replacingOccurrences(of: replace, with: with ?? "")
        }
        guard let breaks else { return document }
        return document.split(separator: "\n", omittingEmptySubsequences: false)
            .joined(separator: breaks)
    }

    func read(_ document: String) throws -> Work {
        switch source {
        case "work": try WorkCorpus.decodeWork(document)
        case "book-with-listening": try WorkCorpus.decodeWorkFromBook(document)
        case "json-book": try Self.decodeJSONBook(document)
        default: throw UnknownFixture(name: source)
        }
    }

    private static func decodeJSONBook(_ document: String) throws -> Work {
        let work = try JSONDecoder().decode(Work.self, from: Data(document.utf8))
        try WorkCorpus.validate(work.pieces)
        try WorkCorpus.validateConfiguration(work)
        return work
    }
}

struct WorkReadingCase: Decodable, Sendable {
    let numbers: [Int]?
    let titles: [String]?
    let lines: [String]?
    let parts: [[Int]]?
    let free: [Int]?
    let bands: [Double]?
    let threshold: Int?
    let language: String?
    let cuts: [String: [Int]]?
    let shortTitles: [String]?
    let summaries: [String]?

    func check(_ work: Work) {
        checkPieces(work.pieces)
        checkParts(work.parts)
        if let language { #expect(work.language == language) }
        if let free { #expect(work.free == free) }
        if let bands {
            let scale = work.stageField
            #expect([scale.untouchedBelow, scale.begunBelow, scale.mostBelow] == bands)
        }
        if let threshold { #expect(work.difficultWords.scoreThreshold == threshold) }
    }

    private func checkPieces(_ pieces: [Piece]) {
        if let numbers { #expect(pieces.map(\.number) == numbers) }
        if let titles { #expect(pieces.map(\.title) == titles) }
        if let lines { #expect(pieces.first?.lines == lines) }
        if let cuts { #expect(pieces.first?.cutSizes == cuts) }
    }

    private func checkParts(_ parts: [Part]) {
        if let ranges = self.parts { #expect(parts.map { [$0.first, $0.last] } == ranges) }
        if let shortTitles { #expect(parts.map(\.shortTitle) == shortTitles) }
        if let summaries { #expect(parts.map(\.summary) == summaries) }
    }
}

private struct WorkCases: Decodable {
    let jsonBook: String
    let cases: [WorkCase]

    private enum CodingKeys: String, CodingKey {
        case jsonBook = "json-book"
        case cases
    }

    static func shared() throws -> Self {
        try YAMLDecoder().decode(Self.self, from: fixture("work-cases"))
    }
}

private struct UnknownFixture: Error, CustomStringConvertible {
    let name: String

    var description: String {
        "A shared case names \(name), which is no fixture a work is read from."
    }
}

struct WorkCaseTests {
    @Test(
        "a work is read, or refused, as the shared cases say",
        arguments: try WorkCase.all()
    )
    func sharedCase(_ shared: WorkCase) throws {
        #expect((shared.error == nil) != (shared.read == nil), "a case is read or refused")
        #expect(shared.error != nil || shared.refused == nil, "only a refusal says a text")
        #expect(
            shared.refused != nil || shared.error == nil || shared.error == "documentError",
            "a refusal says its text, unless it is the parser's own"
        )
        let document = try shared.document()
        do {
            let work = try shared.read(document)
            #expect(shared.error == nil, "read, though the case expects \(shared.error ?? "")")
            shared.read?.check(work)
        } catch let refusal as WorkCorpus.WorkShapeError {
            expect(refusal, named: shared)
        } catch let refusal as WorkCorpus.CorpusError {
            expect(refusal, named: shared)
        } catch let refusal as WorkCorpus.WorkError {
            expect(refusal, named: shared)
        } catch let refusal as DecodingError {
            #expect(shared.error == "documentError", "refused by the parser: \(refusal)")
            if let refused = shared.refused, case let .dataCorrupted(context) = refusal {
                #expect(context.debugDescription == refused)
            }
        }
    }

    private func expect(_ refusal: some LocalizedError, named shared: WorkCase) {
        #expect(String(String(describing: refusal).prefix { $0 != "(" }) == shared.error)
        #expect(refusal.errorDescription == shared.refused)
    }
}
