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
  dependencies: [],
  targets: [
    .target(name: "CodableCSV", dependencies: [], path: "sources"),
    .testTarget(name: "CodableCSVTests", dependencies: ["CodableCSV"], path: "tests"),
    .testTarget(name: "CodableCSVBenchmarks", dependencies: ["CodableCSV"], path: "benchmarks")
  ]
)
