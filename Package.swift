// swift-tools-version:6.0.0

import PackageDescription

let package = Package(
    name: "XcodeProj",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "XcodeProj", targets: ["XcodeProj"]),
    ],
    dependencies: [
        .package(url: "https://github.com/tadija/AEXML.git", .upToNextMinor(from: "4.7.0")),
        // Fork-only, NOT part of the upstream patch: upstream PathKit cannot
        // build for musl either (same Glibc/GLOB_BRACE problems patched here),
        // and leaving this pointed at kylef/PathKit makes SwiftPM resolve two
        // packages with the identity "pathkit" — a warning today that SwiftPM
        // says will become an error. The guard-only commit to propose upstream
        // is on the `upstream-musl-guards` branch, without this change.
        .package(
            url: "https://github.com/yellowplushq/PathKit.git",
            revision: "21dd95c468665dc08776aeff362854893ab72195" // musl, from 1.0.1
        ),
    ],
    targets: [
        .target(name: "XcodeProj",
                dependencies: [
                    .product(name: "PathKit", package: "PathKit"),
                    .product(name: "AEXML", package: "AEXML"),
                ],
                swiftSettings: [
                    .enableExperimentalFeature("StrictConcurrency"),
                ]),
        .testTarget(name: "XcodeProjTests", dependencies: ["XcodeProj"]),
    ]
)
