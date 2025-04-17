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
        .package(url: "https://github.com/loopwork-ai/JSONSchema", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-examples", branch: "main"),
    ],
    targets: [
        .target(name: "MLXKit", dependencies: [
            .product(name: "JSONSchema", package: "JSONSchema"),
            .product(name: "MLXLLM", package: "mlx-swift-examples"),
        ]),
    ]
)
