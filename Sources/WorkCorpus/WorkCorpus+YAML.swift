import Foundation
import Yams

extension WorkCorpus {
    static func decodeYAML<T: Decodable>(_ type: T.Type, from yaml: String) throws -> T {
        try decoding {
            let parser: Parser
            let root: Node
            do {
                parser = try Parser(yaml: yaml, resolver: Resolver.basic.appending(.merge))
                root = try parser.singleRoot() ?? ""
            } catch let error as YamlError {
                if let problem = problem(in: yaml, refusedWith: error) {
                    throw firstProblem(in: yaml, whole: problem)
                }
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
        case refused(WorkShapeError)
        case unreadable
    }

    private static func firstProblem(in yaml: String, whole: WorkShapeError) -> WorkShapeError {
        let lines = yaml.split(separator: "\n", omittingEmptySubsequences: false)
        return firstProblem(in: lines, after: 0, by: lines.count, found: whole)
    }

    private static func firstProblem(
        in lines: [Substring],
        after clean: Int,
        by refused: Int,
        found: WorkShapeError
    ) -> WorkShapeError {
        guard refused - clean > 1 else { return found }
        let middle = (clean + refused) / 2
        for count in middle..<refused {
            switch leading(lines, count) {
            case .refused(let problem):
                return firstProblem(in: lines, after: clean, by: middle, found: problem)
            case .clean:
                return firstProblem(in: lines, after: count, by: refused, found: found)
            case .unreadable:
                continue
            }
        }
        return firstProblem(in: lines, after: clean, by: middle, found: found)
    }

    private static func leading(_ lines: [Substring], _ count: Int) -> Leading {
        let text = lines.prefix(count).joined(separator: "\n")
        do {
            let parser = try Parser(yaml: text, resolver: Resolver.basic.appending(.merge))
            try withExtendedLifetime(parser) {
                try refuseReferences(in: try parser.singleRoot() ?? "", at: "")
            }
            return .clean
        } catch let shape as WorkShapeError {
            return .refused(shape)
        } catch let error as YamlError {
            return problem(in: text, refusedWith: error).map(Leading.refused) ?? .unreadable
        } catch {
            return .unreadable
        }
    }

    private static func problem(in yaml: String, refusedWith error: YamlError) -> WorkShapeError? {
        switch error {
        case let .duplicatedKeysInMapping(duplicates, _):
            duplicates.sorted().first.map(WorkShapeError.repeatedKey)
        case let .composer(_, problem, mark, _) where problem == "found undefined alias":
            .yamlReference(place: aliasPlace(in: yaml, at: mark))
        default:
            nil
        }
    }

    private static func aliasPlace(in yaml: String, at mark: Mark) -> String {
        var lines = yaml.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        let scalars = Array(lines[mark.line - 1].unicodeScalars)
        let start = mark.column - 1
        let ending = " \t,]}".unicodeScalars
        let end = scalars[start...].firstIndex { ending.contains($0) } ?? scalars.count
        var written = String.UnicodeScalarView(scalars[..<start])
        written.append(contentsOf: "~".unicodeScalars)
        written.append(contentsOf: scalars[end...])
        lines[mark.line - 1] = String(written)
        do {
            let parser = try Parser(yaml: lines.joined(separator: "\n"), resolver: .basic)
            let root = try parser.singleRoot() ?? ""
            return place(of: mark, in: root, at: "") ?? "top level"
        } catch {
            return "top level"
        }
    }

    private static func place(of mark: Mark, in node: Node, at place: String) -> String? {
        if node.mark?.line == mark.line, node.mark?.column == mark.column {
            return place.isEmpty ? "top level" : place
        }
        switch node {
        case .mapping(let mapping):
            for (key, value) in mapping {
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
                let name = key.string ?? ""
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
