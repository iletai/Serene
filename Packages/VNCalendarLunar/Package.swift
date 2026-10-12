// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarLunar",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarLunar",
            targets: ["VNCalendarLunar"]
        )
    ],
    targets: [
        .target(
            name: "VNCalendarLunar",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VNCalendarLunarTests",
            dependencies: ["VNCalendarLunar"]
        )
    ]
)
