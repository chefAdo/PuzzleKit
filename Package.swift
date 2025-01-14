// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "PuzzleKit",
    platforms: [
        .iOS(.v14),  // Specify the minimum iOS version
    ],
    products: [
        .library(
            name: "PuzzleKit",
            targets: ["PuzzleKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PuzzleKit",
            dependencies: []),
        .testTarget(
            name: "PuzzleKitTests",
            dependencies: ["PuzzleKit"]),
    ]
)
