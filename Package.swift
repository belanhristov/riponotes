// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "RipoCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "RipoDomain", targets: ["RipoDomain"]),
        .library(name: "RipoData", targets: ["RipoData"]),
        .library(name: "RipoUseCases", targets: ["RipoUseCases"]),
        .library(name: "RipoAppKit", targets: ["RipoAppKit"]),
        .library(name: "RipoCore", targets: ["RipoCore"])
    ],
    targets: [
        .target(name: "RipoDomain"),
        .target(
            name: "RipoData",
            dependencies: ["RipoDomain"]
        ),
        .target(
            name: "RipoUseCases",
            dependencies: ["RipoDomain"]
        ),
        .target(
            name: "RipoAppKit",
            dependencies: ["RipoDomain", "RipoUseCases"]
        ),
        .target(
            name: "RipoCore",
            dependencies: ["RipoDomain", "RipoData", "RipoUseCases", "RipoAppKit"]
        ),
        .testTarget(
            name: "RipoCoreTests",
            dependencies: ["RipoDomain", "RipoData", "RipoUseCases", "RipoAppKit"]
        )
    ]
)
