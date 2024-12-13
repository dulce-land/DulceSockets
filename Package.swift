// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

var DepCDulce : String?

#if os(Linux)
    DepCDulce = "./Sources/CDulceSockets/linux"
#elseif os(macOS)
    DepCDulce = "./Sources/CDulceSockets/macos"
#elseif os(FreeBSD)
    DepCDulce = "./Sources/CDulceSockets/freebsd"
#elseif os(Windows)
    DepCDulce = "./Sources/CDulceSockets/windows"
#else
    DepCDulce = "./Sources/CDulceSockets/someoneelse"
#endif

let package = Package(
    name: "DulceSockets",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DulceSockets",
            type: .dynamic,
            targets: ["DulceSockets"]
            ),
        .library(
            name: "CDulceSockets",
            type: .dynamic,
            targets: ["CDulceSockets"]
            ),
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "DulceSockets", dependencies: ["CDulceSockets"]),
        .target(
            name: "CDulceSockets", path: DepCDulce),
    ]
)
