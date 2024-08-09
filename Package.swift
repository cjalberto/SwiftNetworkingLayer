// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetwokingClient",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "NetwokingClient",
            targets: ["NetwokingClient"]),
    ],
    targets: [
        .target(
            name: "NetwokingClient",
            dependencies: [],
            exclude: ["Example"]
        ),
        .testTarget(
            name: "NetwokingClientTests",
            dependencies: ["NetwokingClient"]
        ),
    ]
)

