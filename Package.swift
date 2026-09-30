// swift-tools-version: 6.2

import PackageDescription

/// CI exports LUMIKIT_WARNINGS_AS_ERRORS=1 so the package builds warning-free; consumers never
/// inherit the setting (and `unsafeFlags` would make the package ineligible as a dependency).
let warningsAsErrors: [SwiftSetting] =
    Context.environment["LUMIKIT_WARNINGS_AS_ERRORS"] != nil ? [.treatAllWarnings(as: .error)] : []

let package = Package(
    name: "LumiKit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macCatalyst(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "LumiKitCore", targets: ["LumiKitCore"]),
        .library(name: "LumiKitUI", targets: ["LumiKitUI"]),
        .library(name: "LumiKitPhoto", targets: ["LumiKitPhoto"]),
        .library(name: "LumiKitDebug", targets: ["LumiKitDebug"]),
        .library(name: "LumiKitLottie", targets: ["LumiKitLottie"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "6.0.0"),
        // SwiftPM resolves the full dependency graph, so consumers of non-Lottie
        // products still fetch this package's metadata at resolve time. The binary
        // artifact itself downloads only when LumiKitLottie is linked.
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.4.0"),
    ],
    targets: [
        // MARK: - Core (Pure Foundation — Zero Dependencies)

        .target(
            name: "LumiKitCore",
            dependencies: [],
            path: "Sources/LumiKitCore",
            resources: [.process("Resources")],
            swiftSettings: warningsAsErrors
        ),

        // MARK: - UI (UIKit + SnapKit)

        .target(
            name: "LumiKitUI",
            dependencies: [
                "LumiKitCore",
                .product(name: "SnapKit", package: "SnapKit"),
            ],
            path: "Sources/LumiKitUI",
            resources: [.process("Resources")],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ] + warningsAsErrors
        ),

        // MARK: - Photo (PhotosUI-backed browser, grid, crop, metadata, share preview)

        .target(
            name: "LumiKitPhoto",
            dependencies: ["LumiKitCore", "LumiKitUI"],
            path: "Sources/LumiKitPhoto",
            resources: [.process("Resources")],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ] + warningsAsErrors
        ),

        // MARK: - Debug (DEBUG-only network logging + inspector UI)

        // The inspector screens need LumiKitUI (UIKit); the URLProtocol logger is Foundation-only
        // so the target still builds and tests natively on macOS without the UI dependency.
        .target(
            name: "LumiKitDebug",
            dependencies: [
                "LumiKitCore",
                .target(name: "LumiKitUI", condition: .when(platforms: [.iOS, .macCatalyst])),
            ],
            path: "Sources/LumiKitDebug",
            resources: [.process("Resources")],
            swiftSettings: [
                .define("LMK_ENABLE_NETWORK_LOGGING", .when(configuration: .debug)),
            ] + warningsAsErrors
        ),

        // MARK: - Lottie (Optional Lottie dependency)

        .target(
            name: "LumiKitLottie",
            dependencies: [
                "LumiKitUI",
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "Sources/LumiKitLottie",
            resources: [.process("Resources")],
            swiftSettings: [
                .defaultIsolation(MainActor.self),
            ] + warningsAsErrors
        ),

        // MARK: - Tests

        .testTarget(
            name: "LumiKitCoreTests",
            dependencies: ["LumiKitCore"],
            path: "Tests/LumiKitCoreTests"
        ),
        .testTarget(
            name: "LumiKitUITests",
            dependencies: ["LumiKitUI"],
            path: "Tests/LumiKitUITests"
        ),
        .testTarget(
            name: "LumiKitPhotoTests",
            dependencies: ["LumiKitPhoto"],
            path: "Tests/LumiKitPhotoTests"
        ),
        .testTarget(
            name: "LumiKitDebugTests",
            dependencies: ["LumiKitDebug"],
            path: "Tests/LumiKitDebugTests",
            swiftSettings: [
                .define("LMK_ENABLE_NETWORK_LOGGING", .when(configuration: .debug)),
            ]
        ),
        .testTarget(
            name: "LumiKitLottieTests",
            dependencies: ["LumiKitLottie"],
            path: "Tests/LumiKitLottieTests"
        ),
    ]
)
