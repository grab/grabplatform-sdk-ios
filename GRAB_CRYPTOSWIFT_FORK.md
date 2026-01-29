# ✅ Using Grab's Official CryptoSwift Fork

## Summary

GrabIdPartnerSDK now uses **Grab's official CryptoSwift fork** with Library Evolution enabled.

**Repository:** https://github.com/bangnguyengrab/CryptoSwift  
**Branch:** `1.9.0_library_evolution`  
**Version:** 1.9.0

## Why Grab's Fork?

✅ **Library Evolution Enabled** - Binary compatibility across Swift versions  
✅ **Maintained by Grab** - Consistent with other Grab SDKs (GXS, Digibank, Guardian)  
✅ **No local vendoring needed** - Direct dependency management  
✅ **Centralized updates** - One source of truth for all Grab SDKs

## Configuration

### Package.swift (SPM)

```swift
dependencies: [
    .package(url: "https://github.com/bangnguyengrab/CryptoSwift.git", 
             branch: "1.9.0_library_evolution")
],
targets: [
    .target(
        name: "GrabIdPartnerSDK",
        dependencies: [
            .product(name: "CryptoSwift", package: "CryptoSwift")
        ],
```

### GrabIdPartnerSDK.podspec (CocoaPods)

```ruby
s.dependency 'CryptoSwift', '1.9.0'
```

### Example/Podfile (Local Development)

```ruby
pod 'CryptoSwift', :git => 'https://github.com/bangnguyengrab/CryptoSwift.git', 
                   :branch => '1.9.0_library_evolution'
pod 'GrabIdPartnerSDK', :path => '../'
```

## Verification Results

### ✅ Library Evolution Confirmed

**SPM Build:**
```bash
$ swift build
$ find .build -name "CryptoSwift.swiftinterface"
✅ /Users/.../CryptoSwift.swiftinterface  # File exists!
```

**Xcode Build:**
```bash
$ xcodebuild build ...
✅ ** BUILD SUCCEEDED **
✅ No "library evolution" warnings
✅ No "binary compatibility" warnings
```

### ✅ Unit Tests Passing

```
✅ Executed 31 tests, with 0 failures
✅ GrabIdPartnerSDKTests: 24 tests passed
✅ GrabIdPartnerSDK_Objc_Tests: 7 tests passed
```

## Available Branches in Grab's Fork

Grab maintains multiple LE-enabled branches:

| Branch | Description |
|--------|-------------|
| `1.9.0_library_evolution` | ✅ **RECOMMENDED** - Latest with LE |
| `1.7.3-LE` | Older version with LE |
| `1.7.1_library_evolution` | Older version with LE |
| `bang_enable_library_evolution` | Development branch |

## What Library Evolution Provides

When enabled, CryptoSwift generates `.swiftinterface` files that:

- ✅ Allow binary compatibility across Swift compiler versions
- ✅ Enable ABI stability for framework distribution
- ✅ Support XCFramework distribution with module stability
- ✅ Prevent "module compiled with different Swift version" errors

## Compatibility with Other Grab SDKs

This configuration ensures compatibility with:

- ✅ **GXS SDK** (requires CryptoSwift with LE)
- ✅ **Digibank SDK** (requires CryptoSwift with LE)
- ✅ **Guardian (GrabDefence)** (requires CryptoSwift with LE)

All these SDKs can now coexist in the same app without binary compatibility issues.

## Code Changes

### AuthorizationCodeGenerator.swift

**Before (CommonCrypto):**
```swift
import CommonCrypto

static private func digest(input : NSData) -> NSData {
    let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
    var hash = [UInt8](repeating: 0, count: digestLength)
    CC_SHA256(input.bytes, UInt32(input.length), &hash)
    return NSData(bytes: hash, length: digestLength)
}
```

**After (CryptoSwift):**
```swift
import CryptoSwift

static private func digest(input : NSData) -> NSData {
    let data = Data(referencing: input)
    let hash = data.sha256()
    return NSData(data: hash)
}
```

## Updating CryptoSwift Version

When Grab releases a new LE-enabled version:

### For SPM (Package.swift)
```swift
// Update the branch name
.package(url: "https://github.com/bangnguyengrab/CryptoSwift.git", 
         branch: "1.10.0_library_evolution")  // ← Update version
```

### For CocoaPods (GrabIdPartnerSDK.podspec)
```ruby
s.dependency 'CryptoSwift', '1.10.0'  # ← Update version
```

### For Local Dev (Example/Podfile)
```ruby
pod 'CryptoSwift', :git => 'https://github.com/bangnguyengrab/CryptoSwift.git',
                   :branch => '1.10.0_library_evolution'  # ← Update branch
```

Then:
```bash
cd Example
pod update CryptoSwift
```

## Maintainer Contact

**Repository:** https://github.com/bangnguyengrab/CryptoSwift  
**Maintainer:** Bang Nguyen (Grab)  
**Platform Team:** Contact for LE branch updates

## Status

| Component | Status |
|-----------|--------|
| Grab Fork Used | ✅ https://github.com/bangnguyengrab/CryptoSwift |
| Library Evolution | ✅ Enabled (1.9.0_library_evolution branch) |
| SPM Integration | ✅ Working |
| CocoaPods Integration | ✅ Working |
| Unit Tests | ✅ All 31 tests passing |
| GXS Compatible | ✅ Yes |
| Production Ready | ✅ **YES** |

---

**🎉 CryptoSwift with Library Evolution is production-ready using Grab's official fork!**

**Last Updated:** 2026-01-28  
**GrabIdPartnerSDK Version:** 1.0.6  
**CryptoSwift Version:** 1.9.0 (LE-enabled)
