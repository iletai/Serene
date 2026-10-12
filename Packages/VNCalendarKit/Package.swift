// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VNCalendarKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VNCalendarKit",
            targets: ["VNCalendarKit"]
        )
    ],
    dependencies: [
        .package(path: "../VNCalendarDomain"),
        .package(path: "../VNCalendarDesignSystem"),
        .package(path: "../VNCalendarLunar"),
        .package(url: "https://github.com/iletai/SwiftUICalendarView.git", from: "3.1.0")
    ],
    targets: [
        .target(
            name: "VNCalendarKit",
            dependencies: [
                .product(name: "VNCalendarDomain", package: "VNCalendarDomain"),
                .product(name: "VNCalendarDesignSystem", package: "VNCalendarDesignSystem"),
                .product(name: "VNCalendarLunar", package: "VNCalendarLunar"),
                .product(name: "CalendarView", package: "SwiftUICalendarView")
            ],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "VNCalendarKitTests",
            dependencies: ["VNCalendarKit"]
        )
    ]
)
