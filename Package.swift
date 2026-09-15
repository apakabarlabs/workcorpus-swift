// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SonnetCorpus",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "SonnetCorpus", targets: ["SonnetCorpus"])
    ],
    dependencies: [
        .package(url: "https://github.com/apakabarlabs/readaloudkit-swift", from: "0.1.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.1.0")
    ],
    targets: [
        .target(
            name: "SonnetCorpus",
            dependencies: [
                .product(name: "ReadAloudKit", package: "readaloudkit-swift"),
                "Yams"
            ]),
        .testTarget(
            name: "SonnetCorpusTests",
            dependencies: [
                "SonnetCorpus",
                .product(name: "ReadAloudKit", package: "readaloudkit-swift")
            ])
    ]
)
