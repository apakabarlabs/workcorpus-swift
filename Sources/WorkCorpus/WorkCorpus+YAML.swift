import Foundation
import Yams

extension WorkCorpus {
    static let unreadableRunsToStepOver = 8

    static func decodeYAML<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        try decoding {
            let parser: Parser
            let root: Node
            do {
                parser = try Parser(yaml: yaml, resolver: Resolver.basic.appending(.merge))
                root = try parser.singleRoot() ?? ""
            } catch let error as YamlError {
                let lines = YAMLLines(yaml)
                if let problem = problem(in: lines, refusedWith: error) {
                    throw firstProblem(in: lines, after: 0, by: lines.count, found: problem)
                }
                if let earlier = problem(in: lines, before: error) { throw earlier }
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: [],
                        debugDescription: "The given data was not valid YAML.",
                        underlyingError: error
                    )
                )
            }
            return try withExtendedLifetime(parser) {
                try refuseReferences(in: root, at: "")
                return try YAMLDecoder().decode(type, from: root)
            }
        }
    }

    private enum Leading {
        case clean
        case refused(any Error)
        case unreadable
    }

    private static func firstProblem(
        in lines: YAMLLines,
        after clean: Int,
        by refused: Int,
        found: any Error
    ) -> any Error {
        guard refused - clean > 1 else { return found }
        let middle = (clean + refused) / 2
        for count in middle..<min(refused, middle + unreadableRunsToStepOver) {
            switch leading(lines, count) {
            case .refused(let problem):
                return firstProblem(in: lines, after: clean, by: middle, found: problem)
            case .clean:
                return firstProblem(in: lines, after: count, by: refused, found: found)
            case .unreadable:
                continue
            }
        }
        return found
    }

    private static func problem(in lines: YAMLLines, before error: YamlError) -> (any Error)? {
        let mark: Mark
        switch error {
        case let .scanner(_, _, found, _), let .parser(_, _, found, _),
            let .composer(_, _, found, _):
            mark = found
        default:
            return nil
        }
        let before = min(mark.line - 1, lines.count)
        for count in stride(from: before, to: max(0, before - unreadableRunsToStepOver), by: -1) {
            switch leading(lines, count) {
            case .refused(let problem):
                return firstProblem(in: lines, after: 0, by: count, found: problem)
            case .clean:
                return nil
            case .unreadable:
                continue
            }
        }
        return nil
    }

    private static func leading(_ lines: YAMLLines, _ count: Int) -> Leading {
        let text = lines.leading(count)
        do {
            let parser = try Parser(yaml: text, resolver: Resolver.basic.appending(.merge))
            try withExtendedLifetime(parser) {
                try refuseReferences(in: try parser.singleRoot() ?? "", at: "")
            }
            return .clean
        } catch let error as YamlError {
            let problem = problem(in: YAMLLines(text), refusedWith: error)
            return problem.map(Leading.refused) ?? .unreadable
        } catch {
            return .refused(error)
        }
    }

    private static func problem(
        in lines: YAMLLines,
        refusedWith error: YamlError
    ) -> WorkShapeError? {
        switch error {
        case let .duplicatedKeysInMapping(duplicates, _):
            duplicates.sorted().first.map(WorkShapeError.repeatedKey)
        case let .composer(_, problem, mark, _) where problem == "found undefined alias":
            .yamlReference(place: aliasPlace(in: lines, at: mark))
        default:
            nil
        }
    }

    private static func aliasPlace(in lines: YAMLLines, at mark: Mark) -> String {
        guard let start = lines.index(line: mark.line, column: mark.column) else {
            return "top level"
        }
        let ending = YAMLLines.breaks.union(" \t,]}".unicodeScalars)
        let end = lines.scalars[start...].firstIndex { ending.contains($0) } ?? lines.scalars.count
        var written = String.UnicodeScalarView(lines.scalars[..<start])
        written.append(contentsOf: "~".unicodeScalars)
        written.append(contentsOf: lines.scalars[end...])
        do {
            let parser = try Parser(yaml: String(written), resolver: .basic)
            return place(of: mark, in: try parser.singleRoot() ?? "", at: "") ?? "top level"
        } catch {
            return "top level"
        }
    }

    private static func place(of mark: Mark, in node: Node, at place: String) -> String? {
        let shown = place.isEmpty ? "top level" : place
        if node.mark?.line == mark.line, node.mark?.column == mark.column { return shown }
        switch node {
        case .mapping(let mapping):
            for (key, value) in mapping {
                if key.mark?.line == mark.line, key.mark?.column == mark.column { return shown }
                let name = key.string ?? ""
                let entry = place.isEmpty ? name : "\(place).\(name)"
                if let found = Self.place(of: mark, in: value, at: entry) { return found }
            }
        case .sequence(let sequence):
            for (index, item) in sequence.enumerated() {
                if let found = Self.place(of: mark, in: item, at: "\(place)[\(index)]") {
                    return found
                }
            }
        default:
            break
        }
        return nil
    }

    private static func refuseReferences(in node: Node, at place: String) throws {
        let shown = place.isEmpty ? "top level" : place
        guard node.anchor == nil else { throw WorkShapeError.yamlReference(place: shown) }
        guard !isTagged(node) else { throw WorkShapeError.explicitTag(place: shown) }
        switch node {
        case .mapping(let mapping):
            for (key, value) in mapping {
                guard key.anchor == nil, key.string != "<<" else {
                    throw WorkShapeError.yamlReference(place: shown)
                }
                guard let name = key.scalar?.string else {
                    let text = "The work's \(shown) has a key that is not text."
                    throw DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: text))
                }
                let entry = place.isEmpty ? name : "\(place).\(name)"
                guard key.scalar?.tag.rawValue == Tag.Name.str.rawValue else {
                    throw WorkShapeError.explicitTag(place: entry)
                }
                try refuseReferences(in: value, at: entry)
            }
        case .sequence(let sequence):
            for (index, item) in sequence.enumerated() {
                try refuseReferences(in: item, at: "\(place)[\(index)]")
            }
        default:
            break
        }
    }

    private static func isTagged(_ node: Node) -> Bool {
        switch node {
        case .scalar(let scalar):
            let tag = scalar.tag.rawValue
            return !tag.isEmpty && (scalar.style == .plain || tag != Tag.Name.str.rawValue)
        case .mapping(let mapping):
            return !mapping.tag.rawValue.isEmpty
        case .sequence(let sequence):
            return !sequence.tag.rawValue.isEmpty
        default:
            return false
        }
    }
}
