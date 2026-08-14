// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NanoBanana",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "NanoBanana",
            path: "Sources/NanoBanana"
        )
    ]
)
