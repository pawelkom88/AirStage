// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AirStage",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AirStage", targets: ["AirStage"]),
        .executable(name: "AirStageApp", targets: ["AirStageApp"]),
    ],
    targets: [
        .target(
            name: "AirStage",
            path: "Sources/AirStage"
        ),
        .executableTarget(
            name: "AirStageApp",
            dependencies: ["AirStage"],
            path: "Sources/AirStageApp"
        ),
        .testTarget(
            name: "AirStageTests",
            dependencies: ["AirStage"],
            path: "Tests/AirStageTests"
        ),
    ]
)
