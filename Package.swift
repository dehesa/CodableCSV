// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "CodableCSV",
    platforms: [
        .macOS(.v10_14), .iOS(.v12), .tvOS(.v12), .watchOS(.v5)
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
