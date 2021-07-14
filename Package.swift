// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription


// Get the values we need to populate the LIBTIDY_VERSION and RELEASE_DATE macros later.
let PWD = (#filePath as NSString).deletingLastPathComponent
let VERSION_FILE = NSString.path(withComponents: [PWD, "Sources", "CLibTidy", "version.txt"])
var CONTENTS:[String]
do {
    CONTENTS = try String(contentsOfFile: VERSION_FILE).components(separatedBy: "\n")
}

let package = Package(
    name: "SwLibTidy",
    products: [

        .library(
            name: "SwLibTidy",
            targets: ["SwLibTidy"]),
        
        .executable(
            name: "Console",
            targets: ["Console"]),
    ],
    
    dependencies: [],
    
    targets: [

        .target(
            name: "CLibTidy"
            , dependencies: []
            , path: "Sources/CLibTidy"
            , exclude: [
                "CMakeLists.txt",
                "tidy.pc.cmake.in",
                "README.md",
                "version.txt",
                "build",
                "console",
                "experimental",
                "localize",
                "man",
                "README",
                "regression_testing",
                "include/buffio.h",
                "include/platform.h",
            ]
            , sources: ["src"]
            , publicHeadersPath: "include"
            , cSettings: [
                .define("LIBTIDY_VERSION", to: "\"\(CONTENTS[0])\"", nil),
                .define("RELEASE_DATE", to: "\"\(CONTENTS[1])\"", nil)
            ]
        ),
        
        .target(
            name: "SwLibTidy",
            dependencies: ["CLibTidy"],
            path: "Sources/SwLibTidy"
        ),
        
        .target(
            name: "Console",
            dependencies: ["SwLibTidy"],
            path: "Sources/Console"
        ),
        
        .testTarget(
            name: "SwLibTidyTests",
            dependencies: ["CLibTidy", "SwLibTidy"],
            resources: [
                .process("Resources/")
            ]
        ),
    ],
    
    cLanguageStandard: CLanguageStandard.gnu89
)
