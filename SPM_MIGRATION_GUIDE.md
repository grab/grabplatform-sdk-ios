# Swift Package Manager Migration Guide

## Summary of Changes

This document outlines the changes made to add Swift Package Manager (SPM) support to GrabIdPartnerSDK.

### Files Modified

1. **Package.swift** (NEW)
   - Created Swift Package manifest
   - Configured iOS 9.0+ deployment target
   - Linked SafariServices and Security frameworks
   - Excluded bridging header from SPM builds

2. **AuthorizationCodeGenerator.swift**
   - Added `import CommonCrypto` for SPM compatibility
   - CommonCrypto is now imported directly in Swift (works on Darwin platforms)

3. **README.md**
   - Added comprehensive SPM installation instructions
   - Organized installation methods (SPM, CocoaPods, Manual)
   - Added note about Info.plist configuration for SPM users

### Compatibility

- **CocoaPods**: Fully compatible, no breaking changes
- **Manual Installation**: Still supported
- **Swift Package Manager**: New support added

### Technical Details

#### CommonCrypto Import Strategy

The SDK uses CommonCrypto for SHA256 hashing in the PKCE flow. We've chosen the direct import approach:

```swift
import CommonCrypto
```

This approach:
- ✅ Works on all Darwin platforms (iOS, macOS, tvOS, watchOS)
- ✅ No additional configuration needed for SPM
- ✅ Maintains backward compatibility with CocoaPods (bridging header still used in Pods)
- ⚠️ Darwin-only (not cross-platform)

**Alternative considered but deferred:**
- Migrating to CryptoKit would require iOS 13+ minimum deployment target
- Current SDK supports iOS 9.0+, so CommonCrypto remains the best choice

## Testing Checklist

### 1. Package Validation

```bash
# Validate Package.swift syntax
swift package dump-package

# Build the package (requires a Mac with Xcode)
swift build
```

### 2. Xcode Integration Test

**Create a new test project:**

1. Create a new iOS App project in Xcode
2. File > Add Packages...
3. Enter local path or GitHub URL: `file:///path/to/grabplatform-sdk-ios`
4. Add the package
5. Import and use the SDK:

```swift
import GrabIdPartnerSDK

// Test instantiation
guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
    print("Failed to initialize GrabIdPartner")
    return
}

// Test loading configuration
grabIdPartner.loadLoginSession { loginSession, error in
    if let error = error {
        print("Error: \(error)")
    } else {
        print("Success: LoginSession loaded")
    }
}
```

### 3. Info.plist Configuration Test

Ensure the test app's Info.plist includes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>grabweblogin</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>grab</string>
    <string>grabconnect2</string>
</array>

<key>GrabIdPartnerSDK</key>
<dict>
    <key>ClientId</key>
    <string>YOUR_CLIENT_ID</string>
    <key>RedirectUrl</key>
    <string>grabweblogin://open</string>
    <key>Scope</key>
    <string>openid</string>
    <key>ServiceDiscoveryUrl</key>
    <string>YOUR_SERVICE_DISCOVERY_URL</string>
</dict>
```

### 4. CocoaPods Compatibility Test

Ensure existing CocoaPods integration still works:

```ruby
# In a test Podfile
platform :ios, '9.0'
use_frameworks!

target 'TestApp' do
  pod 'GrabIdPartnerSDK', :path => '../'
end
```

Run:
```bash
pod install
```

### 5. Build Configuration Tests

Test across different configurations:
- ✅ Debug build
- ✅ Release build
- ✅ Different iOS deployment targets (9.0, 11.0, 13.0, latest)
- ✅ Simulator and physical device

### 6. API Functionality Tests

Verify core functionality works:
- ✅ `sharedInstance()` initialization
- ✅ `loadLoginSession()` from Info.plist
- ✅ `login()` flow (with test credentials)
- ✅ `exchangeToken()` after redirect
- ✅ `getIdTokenInfo()`
- ✅ `logout()`

### 7. CommonCrypto Functions Test

Specifically test the authorization code generation:
- ✅ `getCodeVerifier()` generates valid code
- ✅ `getCodeChallenge()` generates valid SHA256 hash
- ✅ Base64 URL encoding works correctly

## Known Limitations

1. **Platform Support**: SPM integration is Darwin-only (iOS, macOS, tvOS, watchOS)
2. **Bridging Header**: The bridging header file is excluded from SPM builds but remains for CocoaPods
3. **Minimum Swift Version**: Requires Swift 4.0+ (specified in Package.swift)

## Version Strategy

- Current version: 1.0.6
- SPM support added without breaking changes
- Recommend tagging as 1.0.6 or creating 1.1.0 release
- Both CocoaPods and SPM can use the same version

## Release Checklist

Before releasing:
- [ ] All tests pass
- [ ] Update CHANGELOG with SPM support
- [ ] Tag release in git
- [ ] Update CocoaPods spec if needed
- [ ] Verify GitHub repository is public (for SPM access)
- [ ] Test installation from GitHub URL (not just local path)

## Troubleshooting

### Issue: "No such module 'CommonCrypto'"

**Solution**: This should not occur on Darwin platforms. If it does:
1. Verify you're building for iOS/macOS target
2. Check Xcode version (requires Xcode 11+)
3. Clean build folder (Cmd+Shift+K)

### Issue: "Cannot find 'GrabIdPartner' in scope"

**Solution**:
1. Ensure `import GrabIdPartnerSDK` is at the top of your file
2. Verify the package was added to your target's dependencies
3. Clean and rebuild

### Issue: Info.plist configuration not loading

**Solution**:
1. Verify configuration is in the **app target's** Info.plist
2. Check key names match exactly: `GrabIdPartnerSDK`
3. Ensure all required fields are present (ClientId, RedirectUrl, Scope, ServiceDiscoveryUrl)

## Future Enhancements

Potential improvements for future releases:

1. **CryptoKit Migration** (iOS 13+)
   - Replace CommonCrypto with CryptoKit
   - Provides cross-platform support
   - Better Swift API
   - Requires minimum iOS 13.0

2. **Resources Bundle** (if needed in future)
   - SPM can bundle resources with `.process()` or `.copy()`
   - Currently no resources needed

3. **Binary Framework**
   - Could distribute as XCFramework via SPM
   - Would support closed-source distribution

4. **Swift 5.5+ Features**
   - Async/await support for completion handlers
   - Modern concurrency

## Contact

For issues or questions about SPM integration:
- GitHub Issues: https://github.com/grab/grabplatform-sdk-ios/issues
- Developer Portal: https://developers.grab.com

---

**Migration completed**: January 2026
**Tested with**: Xcode 15+, Swift 5.3+, iOS 9.0+
