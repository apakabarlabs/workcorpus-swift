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

    @Test("the stem is written as it is, even where it looks like a format")
    func stemIsNotAFormat() {
        let percent = PieceAsset(stem: "100%d-%@")

        #expect(percent.name(4) == "100%d-%@-004")
        #expect(percent.number(inName: "100%d-%@-004.mp3") == 4)
    }

    @Test("the largest 32-bit number is written in full, and nothing past it is read")
    func largeNumbers() {
        #expect(asset.name(2_147_483_647) == "sonnet-2147483647")
        #expect(asset.name(-4) == "sonnet--04")
        #expect(asset.number(inName: "sonnet-2147483647.mp3") == 2_147_483_647)
        #expect(asset.number(inName: "sonnet-2147483648.mp3") == nil)
        #expect(
            asset.sharedReading(piece: 2_147_483_647, line: 3, heard: nil) == "s2147483647-l03"
        )
    }

    @Test("a stem and a name spelled with combining marks still match")
    func normalizedNames() {
        let composed = PieceAsset(stem: "caf\u{E9}")
        let decomposed = PieceAsset(stem: "cafe\u{301}")

        #expect(composed.number(inName: "cafe\u{301}-004.mp3") == 4)
        #expect(decomposed.number(inName: "caf\u{E9}-004.mp3") == 4)
    }

    @Test("only ASCII digits are read as the digits of a number")
    func asciiDigits() {
        let stem = PieceAsset(stem: "s")

        #expect(stem.number(inName: "s-12三") == 12)
        #expect(stem.number(inName: "s-\u{0663}") == nil)
        #expect(stem.voice(inName: "s-001-三") == NarrationVoice(rawValue: "三"))
        #expect(stem.voice(inName: "s-001-\u{0663}") == NarrationVoice(rawValue: "\u{0663}"))
        #expect(stem.voice(inName: "s-001-042") == nil)
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
