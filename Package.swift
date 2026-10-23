// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sonnov",
    platforms: [.macOS(.v13)],
    targets: [.executableTarget(name: "Sonnov", path: "Sources/Sonnov")]
)
