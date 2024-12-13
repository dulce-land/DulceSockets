// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

#if os(Linux)
   let DepCDulce = "./Sources/CDulceSockets/linux"
#elseif os(macOS)
   let DepCDulce = "./Sources/CDulceSockets/macos"
#elseif os(FreeBSD)
   let DepCDulce = "./Sources/CDulceSockets/freebsd"
#elseif os(Windows)
   let DepCDulce = "./Sources/CDulceSockets/windows"
#else
   let DepCDulce = "./Sources/CDulceSockets/someoneelse"
#endif

let package = Package(
    name: "DulceSockets",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "DulceSockets",
            type: .dynamic,
            targets: ["DulceSockets", "CDulceSockets"]
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
            name: "CDulceSockets", path: "\(DepCDulce)"),
    ]
)
