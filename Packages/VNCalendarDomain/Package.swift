// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarDomain",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarDomain",
            targets: ["VNCalendarDomain"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarLunar")
    ],
    targets: [
        .target(
            name: "VNCalendarDomain",
            dependencies: [
                .product(name: "VNCalendarLunar", package: "VNCalendarLunar")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VNCalendarDomainTests",
            dependencies: ["VNCalendarDomain"]
        )
    ]
)
