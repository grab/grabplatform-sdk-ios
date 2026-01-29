/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import GrabIdPartnerSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("✅ SPM Test App launched")
        print("✅ GrabIdPartnerSDK module imported successfully")
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        print("📱 Received URL callback: \(url.absoluteString)")
        
        // Forward to ViewController for handling
        if let viewController = window?.rootViewController as? ViewController {
            viewController.handleRedirect(url: url)
        }
        
        return true
    }
}
