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
            } catch YamlError.duplicatedKeysInMapping(let duplicates, _) {
                throw WorkShapeError.repeatedKey(
                    firstRepeatedKey(in: yaml) ?? duplicates.sorted().first ?? ""
                )
            } catch let error as YamlError {
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

    private static func firstRepeatedKey(in yaml: String) -> String? {
        let lines = yaml.split(separator: "\n", omittingEmptySubsequences: false)
        for count in lines.indices.map({ $0 + 1 }) {
            let leading = lines.prefix(count).joined(separator: "\n")
            let resolver = Resolver.basic.appending(.merge)
            do {
                _ = try Parser(yaml: leading, resolver: resolver).singleRoot()
            } catch YamlError.duplicatedKeysInMapping(let duplicates, _) {
                return duplicates.count == 1 ? duplicates.first : nil
            } catch {
                continue
            }
        }
        return nil
    }

    private static func refuseReferences(in node: Node, at place: String) throws {
        guard node.anchor == nil else {
            throw WorkShapeError.yamlReference(place: place.isEmpty ? "top level" : place)
        }
        switch node {
        case .mapping(let mapping):
            for (key, value) in mapping {
                guard key.anchor == nil, key.string != "<<" else {
                    throw WorkShapeError.yamlReference(place: place.isEmpty ? "top level" : place)
                }
                let name = key.string ?? ""
                try refuseReferences(in: value, at: place.isEmpty ? name : "\(place).\(name)")
            }
        case .sequence(let sequence):
            for (index, item) in sequence.enumerated() {
                try refuseReferences(in: item, at: "\(place)[\(index)]")
            }
        default:
            break
        }
    }
}
