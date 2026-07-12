// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NetworkingClient",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "NetworkingClient",
            targets: ["NetworkingClient"]),
    ],
    targets: [
        .target(
            name: "NetworkingClient",
            dependencies: []
        ),
        .testTarget(
            name: "NetworkingClientTests",
            dependencies: ["NetworkingClient"]
        ),
    ]
)

