// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "MoreClockKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "MoreClockKit", targets: ["MoreClockKit"]),
    ],
    targets: [
        .target(name: "MoreClockKit", resources: [.process("Resources")]),
        .testTarget(name: "MoreClockKitTests", dependencies: ["MoreClockKit"]),
    ]
)
