// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NanoUI",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "NanoUI",
            path: "Sources/NanoUI"
        )
    ]
)
