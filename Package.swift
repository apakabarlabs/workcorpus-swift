// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "WorkCorpus",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "WorkCorpus", targets: ["WorkCorpus"])
    ],
    dependencies: [
        .package(url: "https://github.com/apakabarlabs/readaloudkit-swift", from: "0.1.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "6.1.0")
    ],
    targets: [
        .target(
            name: "WorkCorpus",
            dependencies: [
                .product(name: "ReadAloudKit", package: "readaloudkit-swift"),
                "Yams"
            ]),
        .testTarget(
            name: "WorkCorpusTests",
            dependencies: [
                "WorkCorpus",
                .product(name: "ReadAloudKit", package: "readaloudkit-swift")
            ])
    ]
)
