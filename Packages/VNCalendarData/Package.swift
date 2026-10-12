// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarData",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarData",
            targets: ["VNCalendarData"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarDomain"),
        .package(path: "../VNCalendarLunar")
    ],
    targets: [
        .target(
            name: "VNCalendarData",
            dependencies: [
                .product(name: "VNCalendarDomain", package: "VNCalendarDomain"),
                .product(name: "VNCalendarLunar", package: "VNCalendarLunar")
            ],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VNCalendarDataTests",
            dependencies: ["VNCalendarData"]
        )
    ]
)
