// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import PackageDescription

let package = Package(
    name: "GrabIdPartnerSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "GrabIdPartnerSDK",
            targets: ["GrabIdPartnerSDK"]
        )
    ],
    dependencies: [
        // CryptoSwift with Library Evolution enabled
        // Using Grab's official fork: https://github.com/bangnguyengrab/CryptoSwift
        .package(url: "https://github.com/bangnguyengrab/CryptoSwift.git", branch: "1.9.0_library_evolution")
    ],
    targets: [
        .target(
            name: "GrabIdPartnerSDK",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift")
            ],
            path: "GrabIdPartnerSDK/Classes",
            exclude: [
                "GrabIdPartnerSDK-Bridging-Header.h"
            ],
            resources: [
                .copy("../Assets/PrivacyInfo.xcprivacy")
            ],
            swiftSettings: [
                .unsafeFlags(["-enable-library-evolution"])
            ],
            linkerSettings: [
                .linkedFramework("SafariServices"),
                .linkedFramework("Security")
            ]
        )
    ]
)
