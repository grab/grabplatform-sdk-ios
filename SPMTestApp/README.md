# SPM Test App - Simple Setup

## Quick 3-Step Test (5 minutes)

### Step 1: Create Xcode Project

1. Open Xcode
2. **File > New > Project**
3. Choose **iOS > App**
4. Settings:
   - **Product Name**: `GrabIdSPMTest`
   - **Team**: Select your team
   - **Organization Identifier**: `com.grab.test`
   - **Interface**: **Storyboard** (important!)
   - **Language**: **Swift**
   - **Location**: Choose anywhere (e.g., Desktop)
5. Click **Create**

### Step 2: Add SPM Package

1. In Project Navigator, select the **project** (top item)
2. Select **GrabIdSPMTest** target
3. Go to **General** tab
4. Scroll to **Frameworks, Libraries, and Embedded Content**
5. Click **+** button
6. Click **Add Package Dependency...**
7. Click **Add Local...**
8. Navigate to: `/Users/edmund.lui/dev/grabplatform-sdk-ios`
9. Click **Add Package**
10. Ensure **GrabIdPartnerSDK** is checked
11. Click **Add Package**

### Step 3: Replace Code Files

**Replace `ViewController.swift` with this:**

Copy from: `SPMTestApp/ViewController.swift`

**Replace `AppDelegate.swift` with this:**

Copy from: `SPMTestApp/AppDelegate.swift`

**Add to `Info.plist`:**

Copy configuration from: `SPMTestApp/InfoPlistAdditions.txt`

### Step 4: Build and Run

1. **Build**: Press `Cmd+B`
   - ✅ Should build without errors
   - ✅ No "No such module" errors

2. **Run**: Press `Cmd+R`
   - ✅ App should launch
   - ✅ Shows "GrabId SPM Test" screen

3. **Test**: Tap "Test SDK"
   - ✅ Console shows success messages

## Expected Console Output

```
✅ SPM Test App Started
✅ SDK initialized successfully
✅ Configuration loaded from Info.plist
✅ SPM Integration Test: PASSED ✅
```

## Troubleshooting

### "No such module 'GrabIdPartnerSDK'"
- Go to Project > Target > General > Frameworks
- Remove and re-add the package
- Clean build: `Shift+Cmd+K`
- Build again: `Cmd+B`

### Build succeeds but app crashes
- Check Info.plist has `GrabIdPartnerSDK` configuration
- Verify all keys are correct

### Login doesn't work
- Normal - staging credentials may not work
- SDK initialization test is the important part

## What This Tests

✅ Package.swift is valid  
✅ SPM integration works  
✅ Module imports correctly  
✅ CommonCrypto import works  
✅ SDK initializes  
✅ Configuration loads from Info.plist

## Success Criteria

If you see "SPM Integration Test: PASSED" in the console, the SPM implementation is working correctly and ready for production use.
