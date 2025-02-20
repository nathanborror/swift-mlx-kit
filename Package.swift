// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-mlx-kit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MLXKit", targets: ["MLXKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/nathanborror/swift-json", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
    ],
    targets: [
        .target(name: "MLXKit", dependencies: [
            .product(name: "JSON", package: "swift-json"),
            .product(name: "MLXLLM", package: "mlx-swift-examples"),
        ]),
    ]
)
