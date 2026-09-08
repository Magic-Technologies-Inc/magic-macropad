// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MagicKeysCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "MagicKeysCore", targets: ["MagicKeysCore"]),
    ],
    targets: [
        .target(name: "MagicKeysCore"),
        .testTarget(name: "MagicKeysCoreTests", dependencies: ["MagicKeysCore"]),
    ]
)
