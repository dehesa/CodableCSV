// swift-tools-version:5.3
import PackageDescription

let package = Package(
  name: "CodableCSV",
  platforms: [
    .macOS(.v10_10), .iOS(.v11), .tvOS(.v9), .watchOS(.v2)
  ],
  products: [
    .library(name: "CodableCSV", targets: ["CodableCSV"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.5")
  ],
  targets: [
    .target(name: "CodableCSV", dependencies: [
        .product(name: "Collections", package: "swift-collections")
    ], path: "sources"),
    .testTarget(name: "CodableCSVTests", dependencies: ["CodableCSV"], path: "tests"),
    .testTarget(name: "CodableCSVBenchmarks", dependencies: ["CodableCSV"], path: "benchmarks")
  ]
)
