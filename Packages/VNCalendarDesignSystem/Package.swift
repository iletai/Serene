// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarDesignSystem",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarDesignSystem",
            targets: ["VNCalendarDesignSystem"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarDomain")
    ],
    targets: [
        .target(
            name: "VNCalendarDesignSystem",
            dependencies: [
                .product(name: "VNCalendarDomain", package: "VNCalendarDomain")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VNCalendarDesignSystemTests",
            dependencies: ["VNCalendarDesignSystem"]
        )
    ]
)
