// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CodableCSV",
    platforms: [
        .iOS(.v12), .tvOS(.v12), .macOS(.v10_14), .watchOS(.v5)
    ],
    products: [
        .library(
            name: "CodableCSV",
            targets: ["CodableCSV"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CodableCSV",
            dependencies: []),
        .testTarget(
            name: "CodableCSVTests",
            dependencies: ["CodableCSV"]),
    ]
)
