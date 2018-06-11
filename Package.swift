// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "VaporSidekiq",
    products: [
        .library(name: "VaporSidekiq", targets: ["VaporSidekiq"]),
        .library(name: "NIOSidekiq", targets: ["NIOSidekiq"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/core.git", from: "3.0.0"),
        .package(url: "https://github.com/vapor/redis.git", from: "3.0.0-rc"),
        .package(url: "https://github.com/vkill/swift-lite-any.git", .branch("master")),
    ],
    targets: [
        .target(name: "NIOSidekiq", dependencies: ["NIO", "LiteAny", "Async"]),
        .target(name: "VaporSidekiq", dependencies: ["NIOSidekiq", "Redis"]),
        .testTarget(name: "NIOSidekiqTests", dependencies: ["NIOSidekiq"]),
        .testTarget(name: "VaporSidekiqTests", dependencies: ["VaporSidekiq"]),
    ]
)
