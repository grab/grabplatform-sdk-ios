# Quick Start - Test SPM in 5 Minutes

## What You'll Do

1. Create new iOS app in Xcode (2 min)
2. Add SPM package (1 min)
3. Copy 3 files (1 min)
4. Run and verify (1 min)

---

## Step-by-Step

### 1️⃣ Create Xcode Project

Open Xcode → File > New > Project → iOS App

Settings:
- **Name**: `GrabIdSPMTest`
- **Interface**: `Storyboard` ⚠️ Important!
- **Language**: `Swift`

Click **Create**

---

### 2️⃣ Add Package

In Xcode:
1. Click on **project** in Navigator (top blue icon)
2. Click **GrabIdSPMTest** target
3. Go to **General** tab
4. Scroll to **Frameworks** section
5. Click **+** → **Add Package Dependency**
6. Click **Add Local**
7. Navigate to and select:
   ```
   /Users/edmund.lui/dev/grabplatform-sdk-ios
   ```
8. Click **Add Package** → **Add Package**

✅ Verify: You see "GrabIdPartnerSDK" in Project Navigator under "Swift Package Dependencies"

---

### 3️⃣ Copy Files

Copy these 3 files from `SPMTestApp/` to your Xcode project:

**File 1: ViewController.swift**
- Open your project's `ViewController.swift`
- Delete everything
- Copy content from `SPMTestApp/ViewController.swift`
- Paste into your file

**File 2: AppDelegate.swift**
- Open your project's `AppDelegate.swift`
- Delete everything
- Copy content from `SPMTestApp/AppDelegate.swift`
- Paste into your file

**File 3: Info.plist**
- Right-click `Info.plist` → **Open As** → **Source Code**
- Find the `<dict>` tag
- Copy content from `SPMTestApp/InfoPlistAdditions.txt`
- Paste **inside** the `<dict>` tag (before `</dict>`)
- Save

---

### 4️⃣ Test

**Build**: Press `Cmd+B`
- ✅ Should succeed with no errors

**Run**: Press `Cmd+R`
- ✅ App launches showing "GrabId SPM Test"

**Test**: Tap "Test SDK" button
- ✅ Console shows "PASSED ✅"

---

## Expected Result

In Xcode console (View > Debug Area > Show Debug Area):

```
🧪 Starting SPM Integration Test
✅ PASSED: SDK initialized
✅ PASSED: Configuration loaded
✅ PASSED: LoginSession is valid
🎉 SPM Integration Test: PASSED ✅
```

---

## If Something Goes Wrong

### Build Error: "No such module 'GrabIdPartnerSDK'"
→ Package not added correctly
→ Go back to Step 2, remove package and re-add

### App Crashes on Launch
→ Info.plist not configured
→ Check Step 3, File 3

### Button Does Nothing
→ Check Xcode console for error messages
→ Verify all 3 files were copied correctly

---

## File Locations

All files are in:
```
/Users/edmund.lui/dev/grabplatform-sdk-ios/SPMTestApp/
```

- `ViewController.swift` - Copy to project
- `AppDelegate.swift` - Copy to project
- `InfoPlistAdditions.txt` - Add to Info.plist
- `SETUP_STEPS.md` - Detailed guide
- `README.md` - Full documentation

---

## Success? ✅

If you see "PASSED ✅" in console:
- ✅ SPM integration works!
- ✅ Ready for SPP app
- ✅ Ready for production

---

**Need help?** See `SETUP_STEPS.md` for detailed instructions.
