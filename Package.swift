// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LumiKit",
    platforms: [
        .iOS(.v18),
        .macCatalyst(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "LumiKitCore", targets: ["LumiKitCore"]),
        .library(name: "LumiKitUI", targets: ["LumiKitUI"]),
        .library(name: "LumiKitLottie", targets: ["LumiKitLottie"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0"),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.4.0"),
    ],
    targets: [
        // MARK: - Core (Pure Foundation — Zero Dependencies)
        .target(
            name: "LumiKitCore",
            dependencies: [],
            path: "Sources/LumiKitCore"
        ),

        // MARK: - UI (UIKit + SnapKit)
        .target(
            name: "LumiKitUI",
            dependencies: [
                "LumiKitCore",
                .product(name: "SnapKit", package: "SnapKit"),
            ],
            path: "Sources/LumiKitUI"
        ),

        // MARK: - Lottie (Optional Lottie dependency)
        .target(
            name: "LumiKitLottie",
            dependencies: [
                "LumiKitUI",
                .product(name: "Lottie", package: "lottie-spm"),
            ],
            path: "Sources/LumiKitLottie"
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
    ]
)
