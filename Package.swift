// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WebSyncroClient",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "WebSyncroClient",
            targets: ["WebSyncroClient"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "WebSyncroClient",
            dependencies: [],
            path: "Sources/WebSyncroClient"
        ),
        .testTarget(
            name: "WebSyncroClientTests",
            dependencies: ["WebSyncroClient"],
            path: "Tests/WebSyncroClientTests"
        )
    ]
)

