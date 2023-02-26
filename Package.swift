// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "DropboxUploader",
    platforms: [
       .macOS(.v12)
    ],
    products: [
        .library(
            name: "DropboxUploader",
            targets: ["DropboxUploader"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.9.0"),
    ],
    targets: [
        .target(
            name: "DropboxUploader",
            dependencies: [
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
    ]
)
