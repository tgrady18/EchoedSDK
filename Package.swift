// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "Echoed",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "Echoed",
            targets: ["Echoed"]
        ),
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "Echoed",
            dependencies: [],
            path: "Sources/Echoed"
        ),
        .testTarget(
            name: "EchoedTests",
            dependencies: ["Echoed"],
            path: "EchoedTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)
