// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ZmanimKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .watchOS(.v10),
        .tvOS(.v17)
    ],
    products: [
        .library(name: "ZmanimKit", targets: ["ZmanimKit"])
    ],
    targets: [
        .target(name: "ZmanimKit"),
        .testTarget(name: "ZmanimKitTests", dependencies: ["ZmanimKit"])
    ]
)
