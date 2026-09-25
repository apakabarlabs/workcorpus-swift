import Testing

@testable import WorkCorpus

struct PieceAssetTests {
    private let asset = PieceAsset(stem: "sonnet")

    @Test("the number is padded so the names sort in the order of the work")
    func stem() {
        #expect(asset.name(4) == "sonnet-004")
        #expect(asset.name(154) == "sonnet-154")
    }

    @Test("the stem is the work's own, so two works do not share a name")
    func stemBelongsToTheWork() {
        #expect(PieceAsset(stem: "onegin").name(4) == "onegin-004")
        #expect(PieceAsset(stem: "onegin").number(inName: "sonnet-004.mp3") == nil)
    }

    @Test("a number is read from a bare name, never from a path")
    func numberInName() {
        #expect(asset.number(inName: "sonnet-004.mp3") == 4)
        #expect(asset.number(inName: "sonnet-004") == 4)
        #expect(asset.number(inName: "sonnet-018-onyx.json") == 18)
        #expect(asset.number(inName: asset.recording(4, voice: .onyx)) == nil)
        #expect(asset.number(inName: "") == nil)
    }

    @Test("a voice is read off the alignment name it was written into")
    func voiceInName() {
        #expect(asset.voice(inName: asset.alignment(18, voice: .onyx)) == .onyx)
        #expect(asset.voice(inName: "sonnet-018.json") == nil)
        #expect(asset.voice(inName: "") == nil)
    }

    @Test("a shared reading is named by piece, line and what was heard")
    func sharedReading() {
        #expect(
            asset.sharedReading(piece: 4, line: 9, heard: "Then beauty is sniggered")
                == "s004-l09-then-beauty-is-sniggered"
        )
    }

    @Test("a shared reading keeps its place when what was heard cannot be used")
    func sharedReadingWithoutWords() {
        #expect(asset.sharedReading(piece: 1, line: 1, heard: nil) == "s001-l01")
        #expect(asset.sharedReading(piece: 1, line: 1, heard: "  ") == "s001-l01")
        #expect(
            asset.sharedReading(piece: 12, line: 13, heard: "O! Then, love/hate?")
                == "s012-l13-o-then-love-hate"
        )
    }

    @Test("a shared reading takes the first eight words of what was heard")
    func sharedReadingLength() {
        let line = "When forty winters shall besiege thy brow and dig deep trenches"
        #expect(
            asset.sharedReading(piece: 2, line: 1, heard: line)
                == "s002-l01-when-forty-winters-shall-besiege-thy-brow-and"
        )
    }
}
