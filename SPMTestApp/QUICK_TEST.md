# Quick Test Guide - 5 Minutes

## Option 1: Automated Setup (Recommended)

Run the automated test script:

```bash
cd /Users/edmund.lui/dev/grabplatform-sdk-ios/SPMTestApp
./automated_test.sh
```

This will:
1. Create a new Xcode project
2. Add the SPM package
3. Configure everything
4. Open the project
5. Build and run

## Option 2: Manual Setup (If you prefer)

### 1. Create Xcode Project (2 minutes)

```
1. Open Xcode
2. File > New > Project
3. iOS > App
4. Settings:
   - Name: SPMTestApp
   - Team: [Your team]
   - Organization Identifier: com.grab.test
   - Interface: Storyboard
   - Language: Swift
   - Location: /Users/edmund.lui/dev/grabplatform-sdk-ios/SPMTestApp/
```

### 2. Add Package (1 minute)

```
1. Project Navigator > Select Project
2. Select Target > General tab
3. Frameworks section > + button
4. Add Package Dependency > Add Local
5. Path: /Users/edmund.lui/dev/grabplatform-sdk-ios
6. Add Package
```

### 3. Copy Files (1 minute)

Replace these files in your Xcode project:

- `ViewController.swift` → Copy from `TestViewController.swift`
- `AppDelegate.swift` → Copy from `TestAppDelegate.swift`
- `Info.plist` → Merge with `Info.plist.template`

### 4. Build & Run (1 minute)

```
1. Cmd+B to build
2. Cmd+R to run
3. Tap "Test SDK Initialization"
```

## Expected Results

### ✅ Success Indicators

**In Xcode:**
- No build errors
- Package appears in "Swift Package Dependencies"
- Project builds in < 10 seconds

**In Simulator:**
- App launches
- Shows "GrabId SPM Test App"
- "Test SDK" button is active
- After tap: Console shows green checkmarks ✅

**Console Output:**
```
✅ SPM Test App Started
✅ SDK initialized successfully
✅ Configuration loaded from Info.plist
✅ LoginSession validation: PASSED
✅ SPM Integration Test: PASSED ✅
```

### ❌ Failure Indicators

**Build Errors:**
- "No such module 'GrabIdPartnerSDK'" → Package not added correctly
- "No such module 'CommonCrypto'" → Building for wrong platform (shouldn't happen on iOS)

**Runtime Errors:**
- App crashes on launch → Missing configuration
- SDK init fails → Code issue (shouldn't happen)
- Config load fails → Info.plist missing or incorrect

## What This Tests

| Test | What It Validates |
|------|-------------------|
| Build | Package.swift is valid, sources compile |
| Import | Module can be imported by Swift |
| Initialize | SDK singleton creates successfully |
| Config Load | Info.plist configuration reads correctly |
| Session Create | LoginSession object creates with config |
| CommonCrypto | SHA256 hashing works (PKCE code generation) |

## Test Levels

### Level 1: Build Test ✅ (Critical)
**Time**: 30 seconds  
**What**: Does it compile?  
**How**: Cmd+B  
**Pass Criteria**: No errors

### Level 2: Runtime Test ✅ (Critical)
**Time**: 1 minute  
**What**: Does SDK initialize?  
**How**: Run app, tap "Test SDK"  
**Pass Criteria**: Console shows "PASSED"

### Level 3: OAuth Flow Test 🔶 (Optional)
**Time**: 5 minutes  
**What**: Does login work end-to-end?  
**How**: Tap "Test Login Flow"  
**Pass Criteria**: Can authenticate and get tokens  
**Note**: Requires valid staging credentials

## Quick Validation Checklist

```bash
# Before starting
cd /Users/edmund.lui/dev/grabplatform-sdk-ios
./validate_spm.sh  # Should show all green ✅

# After Xcode project created
# In Xcode:
☐ Package appears in Project Navigator
☐ Build succeeds (Cmd+B)
☐ No "No such module" errors

# After running in simulator
☐ App launches without crash
☐ "Test SDK" button appears
☐ Tapping button shows success messages
☐ Console output matches expected

# Summary
☐ All checks passed
☐ Ready for production use
```

## Troubleshooting

### Package Not Found
```bash
# Verify package is valid
cd /Users/edmund.lui/dev/grabplatform-sdk-ios
swift package dump-package
# Should output JSON without errors
```

### Build Errors
```
1. Clean: Shift+Cmd+K
2. Close Xcode
3. Delete DerivedData:
   rm -rf ~/Library/Developer/Xcode/DerivedData
4. Reopen project
5. Build again
```

### Runtime Errors
```swift
// Check Bundle for debug:
print(Bundle.main.infoDictionary ?? [:])
// Should show GrabIdPartnerSDK key
```

## Time Estimates

| Method | Setup | Test | Total |
|--------|-------|------|-------|
| Automated | 2 min | 1 min | 3 min |
| Manual | 4 min | 1 min | 5 min |

## Next Steps After Success

1. ✅ Mark test as passed in PRODUCTION_READINESS_CHECKLIST.md
2. ✅ Commit SPM changes to git
3. ✅ Tag release: `git tag -a 1.0.6`
4. ✅ Update production apps

## Files Reference

```
SPMTestApp/
├── README.md                 - Full setup guide
├── QUICK_TEST.md            - This file
├── TestViewController.swift - Test UI and logic
├── TestAppDelegate.swift    - App delegate with URL handling
├── Info.plist.template      - Configuration template
└── automated_test.sh        - One-command setup (if created)
```

---

**Ready to test?** Run Option 1 or Option 2 above! ⬆️
