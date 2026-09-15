import Testing

@testable import SonnetCorpus

struct SonnetAssetTests {
    @Test("the stem is padded so the names sort in the order of the book")
    func stem() {
        #expect(SonnetAsset.name(4) == "sonnet-004")
        #expect(SonnetAsset.name(154) == "sonnet-154")
    }

    @Test("a shared reading is named by sonnet, line and what was heard")
    func sharedReading() {
        #expect(
            SonnetAsset.sharedReading(sonnet: 4, line: 9, heard: "Then beauty is sniggered")
                == "s004-l09-then-beauty-is-sniggered"
        )
    }

    @Test("a shared reading keeps its place when what was heard cannot be used")
    func sharedReadingWithoutWords() {
        #expect(SonnetAsset.sharedReading(sonnet: 1, line: 1, heard: nil) == "s001-l01")
        #expect(SonnetAsset.sharedReading(sonnet: 1, line: 1, heard: "  ") == "s001-l01")
        #expect(
            SonnetAsset.sharedReading(sonnet: 12, line: 13, heard: "O! Then, love/hate?")
                == "s012-l13-o-then-love-hate"
        )
    }

    @Test("a shared reading takes the first eight words of what was heard")
    func sharedReadingLength() {
        let line = "When forty winters shall besiege thy brow and dig deep trenches"
        #expect(
            SonnetAsset.sharedReading(sonnet: 2, line: 1, heard: line)
                == "s002-l01-when-forty-winters-shall-besiege-thy-brow-and"
        )
    }
}
