// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Diguest",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "Diguest", targets: ["Diguest"])
    ],
    targets: [
        .executableTarget(
            name: "Diguest",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("Speech"),
                .linkedFramework("SwiftUI")
            ]
        )
    ]
)
