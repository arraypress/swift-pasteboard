// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-pasteboard",
    // AppKit's pasteboard is the whole point, so this is Mac-only by nature.
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "Pasteboard", targets: ["Pasteboard"]),
    ],
    targets: [
        .target(name: "Pasteboard"),
        .testTarget(name: "PasteboardTests", dependencies: ["Pasteboard"]),
    ]
)

// Swift 7's import rule, today: a file must import every module whose members
// it uses, rather than leaning on another file's imports.
for target in package.targets where target.type != .system && target.type != .binary && target.type != .plugin {
    target.swiftSettings = (target.swiftSettings ?? []) + [.enableUpcomingFeature("MemberImportVisibility")]
}
