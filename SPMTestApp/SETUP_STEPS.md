# SPM Test - Setup Steps

## Overview
Create a simple iOS app to test SPM integration. Total time: **5 minutes**.

---

## Step 1: Create New Xcode Project (2 min)

```
1. Open Xcode
2. File > New > Project
3. iOS > App
4. Configure:
   - Product Name: GrabIdSPMTest
   - Interface: Storyboard
   - Language: Swift
   - Location: (anywhere, e.g., Desktop)
5. Click Create
```

---

## Step 2: Add SPM Package (1 min)

```
1. Project Navigator > Select PROJECT (top)
2. Select TARGET "GrabIdSPMTest"
3. General tab
4. Frameworks, Libraries, and Embedded Content section
5. Click + button
6. Add Package Dependency...
7. Add Local...
8. Select: /Users/edmund.lui/dev/grabplatform-sdk-ios
9. Add Package
10. Check "GrabIdPartnerSDK"
11. Add Package
```

**Verify**: Package appears in Project Navigator under "Swift Package Dependencies"

---

## Step 3: Replace Code Files (1 min)

### 3a. Replace ViewController.swift

In your project's `ViewController.swift`, delete all content and paste from:

```
/Users/edmund.lui/dev/grabplatform-sdk-ios/SPMTestApp/ViewController.swift
```

### 3b. Replace AppDelegate.swift

In your project's `AppDelegate.swift`, delete all content and paste from:

```
/Users/edmund.lui/dev/grabplatform-sdk-ios/SPMTestApp/AppDelegate.swift
```

### 3c. Update Info.plist

1. Right-click `Info.plist` > Open As > **Source Code**
2. Find the `<dict>` tag (near top)
3. Copy and paste the content from:

```
/Users/edmund.lui/dev/grabplatform-sdk-ios/SPMTestApp/InfoPlistAdditions.txt
```

4. Paste it **inside** the `<dict>` tag, before `</dict>`

---

## Step 4: Build and Test (1 min)

### Build
```
Press: Cmd+B
Expected: ✅ Build succeeds, no errors
```

If you see errors:
- "No such module 'GrabIdPartnerSDK'" → Package not added correctly, go back to Step 2
- Other errors → Check you copied files correctly in Step 3

### Run
```
Press: Cmd+R
Expected: ✅ App launches, shows "GrabId SPM Test"
```

### Test
```
In the app:
1. Tap "Test SDK" button
2. Check console output (View > Debug Area > Show Debug Area)
3. Expected: See "SPM Integration Test: PASSED ✅"
```

---

## Expected Console Output

```
✅ SPM Test App launched
🧪 Starting SPM Integration Test
Test 1: SDK Initialization...
✅ PASSED: SDK initialized
Test 2: Load Configuration...
✅ PASSED: Configuration loaded
Test 3: Validate LoginSession...
✅ PASSED: LoginSession is valid
🎉 SPM Integration Test: PASSED ✅
✅ SPM implementation is working correctly!
✅ Ready for production use
```

---

## Success Criteria

✅ Build completes without errors  
✅ App launches without crashes  
✅ Console shows "PASSED ✅"  

**Result**: SPM integration is working! Ready for production.

---

## Troubleshooting

### "No such module 'GrabIdPartnerSDK'"
```
1. Project > Target > General > Frameworks
2. Remove GrabIdPartnerSDK if present
3. Clean: Shift+Cmd+K
4. Re-add package (Step 2)
5. Build: Cmd+B
```

### Build succeeds but app crashes
```
1. Check Info.plist has GrabIdPartnerSDK config
2. Verify no typos in config keys
3. Clean build: Shift+Cmd+K
4. Run again: Cmd+R
```

### "Test SDK" button does nothing
```
1. Check console for errors
2. Verify Info.plist configuration is correct
3. Make sure you replaced both Swift files
```

---

## What This Tests

| Test | Purpose |
|------|---------|
| SDK Initialization | Verifies SPM module loads correctly |
| Configuration Load | Tests Info.plist reading |
| LoginSession Validation | Confirms SDK functionality |

---

## Next Steps After Success

1. ✅ Mark SPM test as passed
2. ✅ Integrate into SPP app
3. ✅ Commit SPM changes to git
4. ✅ Deploy to production

---

## Files Reference

```
SPMTestApp/
├── README.md              - This file
├── SETUP_STEPS.md         - Step-by-step guide
├── ViewController.swift   - Copy to Xcode project
├── AppDelegate.swift      - Copy to Xcode project
└── InfoPlistAdditions.txt - Add to Info.plist
```

---

**Quick Check**: If you see "PASSED ✅" in the console, you're done! 🎉
