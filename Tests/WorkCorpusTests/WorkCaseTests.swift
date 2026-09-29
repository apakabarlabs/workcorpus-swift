import Foundation
import Testing
import Yams

@testable import WorkCorpus

struct WorkCase: Decodable, Sendable, CustomTestStringConvertible {
    let name: String
    let source: String
    let replace: String?
    let with: String?
    let refused: String?
    let threshold: Int?

    var testDescription: String { name }

    private enum CodingKeys: String, CodingKey {
        case name = "case"
        case source = "fixture"
        case replace
        case with
        case refused
        case threshold
    }

    static func all() throws -> [Self] {
        try YAMLDecoder().decode(WorkCases.self, from: fixture("work-cases")).cases
    }

    func document() throws -> String {
        let base = try fixture(source)
        guard let replace else { return base }
        #expect(
            base.components(separatedBy: replace).count == 2,
            "\(replace) is not in \(source) once"
        )
        return base.replacingOccurrences(of: replace, with: with ?? "")
    }

    func read(_ document: String) throws -> Work {
        switch source {
        case "work": try WorkCorpus.decodeWork(document)
        case "book-with-listening": try WorkCorpus.decodeWorkFromBook(document)
        default: throw UnknownFixture(name: source)
        }
    }
}

private struct WorkCases: Decodable {
    let cases: [WorkCase]
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
        let document = try shared.document()
        do {
            let work = try shared.read(document)
            #expect(shared.refused == nil, "read, though the case expects: \(shared.refused ?? "")")
            if let threshold = shared.threshold {
                #expect(work.difficultWords.scoreThreshold == threshold)
            }
        } catch let refusal as LocalizedError {
            #expect(refusal.errorDescription == shared.refused)
        }
    }
}
