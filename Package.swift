// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TelegramMCPServer",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "TelegramMCPServer",
            targets: ["TelegramMCPServer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),
        .package(url: "https://github.com/Swiftgram/TDLibKit.git", branch: "master"),
    ],
    targets: [
        .target(
            name: "TelegramMCPServer",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "TDLibKit", package: "TDLibKit"),
            ]
        ),
        .testTarget(
            name: "TelegramMCPServerTests",
            dependencies: ["TelegramMCPServer"]
        ),
    ]
)
