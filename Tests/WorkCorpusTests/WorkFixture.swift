import Foundation

func workFixture() throws -> String {
    guard let url = Bundle.module.url(forResource: "work", withExtension: "yaml") else {
        throw CocoaError(.fileNoSuchFile)
    }
    return try String(contentsOf: url, encoding: .utf8)
}
