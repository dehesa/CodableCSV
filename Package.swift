// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CodableCSV",
    platforms: [
        .macOS(.v10_13), .iOS(.v10), .tvOS(.v10), .watchOS(.v3)
    ],
    products: [
        .library(name: "CodableCSV", targets: ["CodableCSV"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CodableCSV",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "CodableCSVTests",
            dependencies: ["CodableCSV"]),
    ]
)
