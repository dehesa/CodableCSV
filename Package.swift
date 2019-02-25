// swift-tools-version:4.2
import PackageDescription

let package = Package(
    name: "CodableCSV",
    products: [
        .library(
            name: "CodableCSV",
            targets: ["CodableCSV"])
    ],
    targets: [
        .target(
            name: "CodableCSV",
            path: "Souces")
    ]
)
