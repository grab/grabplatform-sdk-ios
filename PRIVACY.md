# Privacy & Data Collection

## Overview

GrabIdPartnerSDK includes a Privacy Manifest (`PrivacyInfo.xcprivacy`) that declares all data collection and API usage in compliance with Apple's App Privacy Requirements.

## What Data Is Collected

### ✅ Data Collected
- **OAuth Tokens** (access token, ID token, refresh token)
  - Purpose: Authentication
  - Storage: iOS Keychain (encrypted)
  - Linked to user: Yes
  - Used for tracking: No

### ❌ Data NOT Collected
- Analytics or telemetry
- Crash reports
- Location data
- Contact information
- Advertising identifiers
- Device fingerprinting

## Privacy Manifest

The SDK includes `PrivacyInfo.xcprivacy` which is **automatically included** when you integrate via:
- Swift Package Manager (SPM)
- CocoaPods
- XCFramework

**No action required** - Xcode will automatically merge the SDK's privacy manifest with your app.

## App Store Privacy Label

When submitting your app, declare the following in App Store Connect:

**Data Collected:**
- ✓ **User ID**
  - Purpose: App Functionality
  - Linked to User: Yes
  - Used for Tracking: No

**Data NOT Collected** (by this SDK):
- Contact Info
- Location
- Browsing History
- Usage Data
- Diagnostics

## Required Info.plist Entries

### Basic OAuth (Required)
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>grab[YOUR_PARTNER_ID]</string>
        </array>
    </dict>
</array>
```

### Login with Grab App (Optional)
If using the Login with Grab app feature:
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>grab</string>
    <string>grabconnect2</string>
</array>
```

## Data Storage

| Data Type | Storage Location | Encryption |
|-----------|------------------|------------|
| OAuth Tokens | iOS Keychain | Yes (iOS) |
| Session Metadata | UserDefaults | Not required (non-sensitive) |

## Data Deletion

Users can delete their data by:
1. **Logout**: Call `GrabIdPartner.logout()` - removes all local tokens
2. **App Deletion**: iOS automatically removes Keychain items

To revoke access permanently, users should revoke authorization through their Grab account settings.

## Security

- ✅ All tokens stored in iOS Keychain (encrypted)
- ✅ OAuth 2.0 with PKCE (Proof Key for Code Exchange)
- ✅ HTTPS for all network communication
- ✅ No plaintext tokens in logs or files

## Privacy Policy Template

Include this in your app's privacy policy:

```
Authentication via Grab ID

Our app uses Grab ID for user authentication. When you sign in with Grab:
- OAuth tokens are securely stored on your device using iOS Keychain
- Tokens are used solely for authentication and API access
- You can revoke access by logging out or through your Grab account settings
- No data is shared with third parties for advertising or analytics
```

## Required Reason APIs

The SDK uses the following Apple-restricted APIs:

| API | Reason Code | Purpose |
|-----|-------------|---------|
| UserDefaults | CA92.1 | Store non-sensitive session metadata |
| Keychain | N/A | Secure token storage |

## Compliance

- ✅ iOS 17+ Privacy Requirements
- ✅ No tracking performed (`NSPrivacyTracking: false`)
- ✅ GDPR compliant (data minimization)
- ✅ CCPA compliant (no sale of personal information)

## Questions?

- Developer Documentation: See [README.md](README.md)
- Developer Portal: https://developers.grab.com

---

**Last Updated**: January 2026  
**SDK Version**: 2.0.1
