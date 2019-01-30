# GrabID Partner SDK - iOS

The GrabId Partner SDK allows users to sign in with their Grab account from third-party apps.

Please visit [our developer site](https://developers.grab.com) for integration instructions, documentation, support information, 
and terms of service.

[![Version](https://img.shields.io/cocoapods/v/GrabIdPartnerSDK.svg?style=flat)](https://cocoapods.org/pods/GrabIdPartnerSDK)
[![License](https://img.shields.io/cocoapods/l/GrabIdPartnerSDK.svg?style=flat)](https://cocoapods.org/pods/GrabIdPartnerSDK)
[![Platform](https://img.shields.io/cocoapods/p/GrabIdPartnerSDK.svg?style=flat)](https://cocoapods.org/pods/GrabIdPartnerSDK)

## Installation
CocoaPods is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate GrabID Partner SDK into your Xcode project using CocoaPods, specify it in your Podfile:

  pod 'GrabIdPartnerSDK', :git => 'https://github.com/grab/grabplatform-sdk-ios.git'

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
- iOS 9.0+
- Xcode 9.0+
- Swift 3.2 / 4.1+
- Objective-C

## Installation the GrabID Partner SDK

In final version, SDK might be hosted as a private pod so that you can use something like: `pod 'GrabIdPartnerSDK'`

For this mock version, please copy/drag the framework to this project. While coping the framework in Project Explorer, check “Copy items if needed”.

Select the Project, Choose Target → Project Name → Select General → Scroll to “Embedded Binaries”. Press “+” and Add the framework.

If there are multiple Framework with same name in “Linked Frameworks and Libraries”, delete other ones, and just keep only one.

## Getting Started

### SDK Configuration
Firstly, you need to register an application to Grab and get credentials for your app from GrabID team.

Then, configure your project with information for the GrabId Partner SDK. Right-click Info.plist file and select Open As -> Source Code.
Add the following snippet, replacing the placeholders within the square brackets (`[]`):

### Setup URLScheme to handle redirect URL
```
<key>CFBundleURLTypes</key>
<array>
<dict>
<key>CFBundleURLSchemes</key>
<array>
<string>grab[PartnerID]</string>
</array>
</dict>
</array>
<key>GrabPartnerID</key>
<string>[PartnerID]</string>
</dict>
```
### Example

```
<key>CFBundleURLTypes</key>
<array>
<dict>
<key>CFBundleTypeRole</key>
<string>Editor</string>
<key>CFBundleURLName</key>
<string>com.grab.grabweblogin</string>
<key>CFBundleURLSchemes</key>
<array>
<string>grabweblogin</string>
</array>
</dict>
</array>
```

### Configure GrabId Partner SDK to login with Grab (Optional, see Create LoginSession)

Partner application should register their RedirectUrl and obtain the Client Id, Scope, and Service Discovery end point from the Grab Id team.

```
<key>GrabIdPartnerSDK</key>
<dict>
<key>ClientId</key>
<string>[client id]</string>
<key>RedirectUrl</key>
<string>grab[PartnerID]://[Partner-Redirect-Uri-Path]</string>
<key>Scope</key>
<string>[Permission scope] [Permission scope] [Permission scope] openid</string>
<key>ServiceDiscoveryUrl</key>
<string>[obtain the service discovery endpoint from the GrabId team]</string>
<-- Optional

<key>Hint</key>
<string>[Hint - set the query parameter id_token_hint for the Authorize end point]</string>

<key>Request</key>
<string>[Pass thru string if specified will add query parameter &request=[request string] to the /authorize service call]</string>

<-- AcrValues if specified will add query parameter "&acr_values=[key]:[value] [key]:[value] ..." to the /authorize service call. 
    e.g. "&acr_values=SERVICE:PASSENGER consent_ctx:countryCode=SG" -->
<dict>AcrValues
<key>[e.g. SERVICE, consent_ctx, etc.]</key>
<string>[e.g. PASSENGER, countryCode=SG, etc.]</String>
</dict>
-->

<-- For testing only. This test resource is used by the Grab Id Example
<key>TestProtectedResourceUrl</key>
<string>replace with test resource url</string>
-->

</dict>
```
### Example

Values provided here are example only. ClientId, ServiceDiscoveryUrl, and TestProtectedResourceUrl are provided for example only. They will not work
with the Example provided. Please obtain the information if you are interested in running the test app.
```
<key>GrabPartnerIdSDK</key>
<dict>
<key>ClientId</key>
<string>e20e3567-3fa3-4b13-a135-b00fd88e3295</string>
<key>Hint</key>
<string>Oxy0dKP4RLbGdksH</string>
<key>RedirectUrl</key>
<string>grabweblogin://open</string>
<key>Scope</key>
<string>gid_test_scope_1 gid_test_scope_2 gid_test_scope_3 openid</string>
<key>ServiceDiscoveryUrl</key>
<string>https://api.grabidpartner.com/authorize</string>
<key>TestProtectedResourceUrl</key>
<string>https://api.grabidpartner.com/testresource</string>
</dict>
```

### Access the GrabId Partner SDK APIs

Obtain a share instance of the GrabIdPartner
```
guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
  // handle failure to get an instance of the GrabIdPartner
  return
}
```

### Login with GrabId service

#### Using the loadLoginSession API to get configurations in the Info plist
```
func signInWithLoginConfig() {
  guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
    // handle failure to instantiate GrabIdPartner
    return
  }
  grabIdPartner.loadLoginSession() { [weak self] (loginSession, error) in
    guard let self = self else {
      return
    }
    self.loginSession = loginSession
    if let error = error {
      // handle failure to load LoginSession configurations
    } else {
      // proceed to login
      grabIdPartner.login(loginSession: loginSession, 
        presentingViewController: [Partner App View]) { [weak self] (error) in
        guard let self = self else {
          return
        }
      }
    }
  }
}
```

#### Using LoginSession
```
func signIn() {
  guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
    // handle failure to instantiate GrabIdPartner
    return
  }
  let url = URL(string:Configuration.redirectUri)
  if let redirectUrl = url {
    loginSession = LoginSession(clientId: "[Partner Client Id]" , 
                                redirectUrl: "[Partner Redirect URL]", 
                                scope: "<scope>"
                                serviceDiscoveryUrl: "<obtain the service disocvery endpoints from GrabId Service team>",
                                Hint:"<serialized JWT token that client already has, if provided, the user will not be prompted to authenticate>")
    grabIdPartner.login(loginSession: loginSession, 
                      presentingViewController: <partner app view>) { [weak self] (error) in
      guard let self = self else {
        return
      }
    }
  }
}
```

### Handling URL redirect after user authenticate with Web login

The login API will trigger the Grab Id in-app web authorization. After the user successfully authenticate and give consent to the partner application access, Grab Id service will validate the redirect URL and the security attributes in the query parameters.  If the redirect URL is registered with Grab Id service, Grab Id service will send the redirect URL to the browser (see "Setup URLScheme for partner application to handle redirect URL")  and partner application  will receive the redirect URL with an authorization code, state, and error (if any) in the query parameters.  

#### Connect App Delegate

Partner application needs to implement a method in their AppDelegate class for the app to respond when their application is launched via the custom URL scheme:


### AppDelegate.swift 

```
import GrabIdPartnerSDK

func application(_ app: UIApplication, 
                  open url: URL, 
                  options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
  guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
    // handle failure to instantiate GrabIdPartner
    return
  }

  ...

  // Partner application must provide the same  loginSession created during login.  
  grabIdPartner.exchangeToken(loginSession: loginSession, url: url) { [weak self] (error) 
    guard let self = self else {
      return
    }

    // Complete the web login flow, close the web browser, etc.
    if !grabIdPartner.loginCompleted(loginSession: loginSession) {
      // handle login completion error (i.e. dismiss the web login view)
      ...
    }       
    guard error != nil else {
      // handle login error
      return
    }

    // login is successful and LoginSession now contains the access token, id token, etc.
  }
}
```
### Get Id Token Information

Partner application can get information about the id token using the getIdTokenInfo API:

```
grabIdPartner.getIdTokenInfo(loginSession: loginSession) { [weak self] (idTokenInfo, error) in 
  guard let self = self else {
    return
  }
}
```

IdToken contains information about the valid time of the token, partner id, partner user id, nonce, issuer, etc

### Check if token is valid

#### Access Token

Application can use the isValidAccessToken API to check if the access token is valid

let isValid = grabIdPartner.isValidAccessToken(loginSession: loginSession)

#### Id Token

Application can use the isValidIdToken API to check if the access token is valid

let isValid = grabIdPartner.isValidIdToken(idTokenInfo: idTokenInfo)


### Logout 

Partner application can logout using the logout API. Currently logout removes cached LoginSession and IdTokenInfo from the keychain and user defaults. It does not support revoking the tokens from Grab Id service. Revoking authorization will be supported in future release.   

```
grabIdPartner.logout(loginSession: loginSession) { [weak self] (error) in 
  guard let self = self else {
    return
  }
}
```

## GrabId Partner SDK API

### LoginSession
```
clientId: String                            Application registered client id.

redirectUrl: URL                            The redirect URL that was used in the initial authorization request.
                                            This URL must register with Grab Id service during Partner registration.

scope: String                               Specify the requested permission scopes.

request: String                             Partner specific request string.

hint: String                                Serialized JWT token that client already has, if provided, the user will 
                                            not be prompted to authenticate. hint will be sent in query parameter id_token_hint in
                                            the authroize call to Grab ID.

acrValues: [String:String]                  Partner specific acr values (name value pairs).

serviceDiscoveryUrl : String                Service discovery Url (please obtain this endpoint from GrabId service team)

READ ONLY PROPERTIES

code: String?                               Unique authorization code (from query parameter in the redirect url). 
                                            This code will be used by the exchangeToken API to obtain the accessToken 
                                            and idToken.

codeVerifier: String?                       The code verifier for the PKCE request, that is generated by the login API 
                                            before the authorization request.

accessTokenExpiresAt: Date?                 Access token expiration date.

state: String?                              The login API generates a unique state paramter during authorization, the
                                            Grab Id service will include the state parameter in the query parameter 
                                            in the redirect URL to mitigate CSRF attacks.

tokenType: String?                          Indicates the grant type of this token request.

nonce: String?                              Unique token generated during login.

accessToken: String?                        Access token to make Grab API requests on behalf of the user.

idToken: String?                            JWT contains user profile information (Signed).

refreshToken: String?                       Used to obtain/renewed access token (current not supported).
```

### IdTokenInfo

```
audience: String?                    Intended recipient of the token.
service: String?                     Service (i.e. PASSENGER).

notValidBefore: Date?                Id token validation start time.

expiration: Date?                    Id token expiration date.             

issuer: String?                      Issuer (i.e. "https://testissuer.grab.com).

tokenId: String?                     Id Token (Unsigned).

partnerId: String?                   Partner Id.

partnerUserId: String?               Partner User id

nonce: String?                       Unique token generated during login. The value should match the 
                                     nonce in the LoginSession.
```

### GrabIdPartnerProtocol
```
sharedInstance() : GrabIdPartnerProtocol

Static function to get a shared instance of GrabIdPartner to access the Grab Id Partner SDK APIs.

Return
  GrabIdPartnerProtocol 
```

```
loadLoginSession(completion: @escaping(LoginSession?, GrabIdPartnerError?)) : Void

Read the ClientId, Scope, Hint, RedirectUrl, serviceDiscoveryUrl, Request (optional), AcrValues (optional) from  the application's info plist and create a LoginSession. Please obtain the serviceDiscoveryDiscoveryUrl production and staging endpoints from the Grab Id team.

Completion Handler
  Receives a LoginSession with nil error if the information in the plist is valid, Otherwise the 
  completion handler will be called with nil LoginSession and a GrabIdPartnerError.
```

```
login(loginSession: LoginSession, 
      presentingViewController: UIViewController, completion: @escaping(GrabIdPartnerError?)) : Void

The login API will attempt to set up the LoginSession with cached LoginSession data. Currently refresh token is not supported. First, the login API will get the Grab Id service end points (i.e. token, token info) from Grab Id discovery service (see configuration above) and generates an unique code verifier, nonce, state as security attributes. The security attributes, redirect URL, request string, and acr values are inlcuded in the query parameters to create the Grab Id authorize service URL.  Then the login API will present the SFSafariViewController and navigate to the Grab Id authorize URL for in-app web authorization. Once the user finished logging in. Grab Id authorize service will redirect back to the app with the redirect url that includes the authorization code, state, and error (if any). Application must handle the URL redirect (see "Handling URL redirect after user authenticate with Web login")

Note:

presentingViewController is used in case that SFSafariViewController will be presented on top of it when logging in with webpage.

Completion Handler
  nil if no error, GrabIdPartnerErroir with error code and message otherwise.
```

```
exchangeToken(loginSession: LoginSession, url: URL, completion: @escaping (GrabIdPartnerError?)) : Void

The exchangeToken API is called when AppDelegates's handleOpenUrl is called to handle redirect after the in-app web authorization. Application should forward the redirect url to the exchangeToken API. The exchangeToken API will check for redirect error, validate the state in the query parameter against the state in the loginSession.  It will send the authorization code to Grab Id token service to get access token, id token, and access token expiration information. The tokens will be saved in the keychain and LoginSession will be saved in user defaults. The exchangeToken API will call loginCompleted internally to dismiss the SFSafariViewContoller that was displayed in login for the in-app web authorization flow.

Completion Handler
  nil if no error, GrabIdPartnerErroir with error code and message otherwise.

```

```
loginCompleted(loginSession: LoginSession) : Bool

Application that handles their own redirect without calling the exchangeToken API must call the loginCompleted API. This  API is required to complete the in-app web authorization flow. It is the only way to dismiss the SFSafariViewController.

Return
  Return true if it is successful in dismissing the web login flow, false otherwise. 

```
```
loginCompleted(loginSession: LoginSession, completion:(()->Void)?) : Bool

Application that handles their own redirect without calling the exchangeToken API must call the loginCompleted API. This  API is required to complete the in-app web authorization flow. It is the only way to dismiss the SFSafariViewController. If you provided a completion handler, the completion handler will be called after SafariViewController is dismissed.

Return
Return true if it is successful in dismissing the web login flow, false otherwise. 

```
```
logout(loginSession: LoginSession, completion: ((GrabIdPartnerError?)) : Void

The logout API will remove cached loginSession and related idTokenInfo.  Calling login after logout or with an expired access token will trigger the in-app web authorization flow. Revoke token support will be added in future release.

Completion Handler
  nil if no error, GrabIdPartnerErroir with error code and message otherwise.

```

```
getIdTokenInfo(loginSession: LoginSession, completion: @escaping (IdTokenInfo?, GrabIdPartnerError?))-> Void

Application can call the getIdTokenInfo API to get the idToken information (i.e. id token expiration date, unsigned Id token, nonce,  audience , partner user id, partner id, etc.). It caches the id token in the key chain and the rest of the Id token information are stored in user defaults. getIdTokenInfo will return IdTokenInfo from cache if the Id token has not expired. getIdTokenInfo API will return error if the Id Token has expired. Application must call the login API to get a new Id Token before calling getIdTokenInfo API to get the IdTokenInfo/

Completion Handler
  If there is no error, idTokenInfo contains id token information, otherwise idTokenInfo will be nil
  If there is error, idTokenInfo will be nil and GrabIdPartnerError will contain the error code and message.
```

```
isValidAccessToken(loginSession: LoginSession) -> Bool

Determine if the access token in the LoginSession is valid (using the access token expiration date).

Return
  true if the access token is valid, false otherwise
```

```
isValidIdToken(idToken: IdTokenInfo) -> Bool

Determine id token in IdTokenInfo is valid (using the id token start time and expiration date).

Return
  true if the id token is valid, false otherwise
```

### Grab Id SDK Error

#### GrabIdPartnerError
```
domain: GrabIdPartnerErrorDomain?   Source of the error
code : GrabIdPartnerErrorCode       Error code
localizeMessage : String?           Error message
serviceError : Error?               System Error
```
##### GrabIdPartnerErrorDomain
```
serviceDiscovery
loadConfiguration
authorization
exchangeToken
getIdTokenInfo
logout
```
##### GrabIdPartnerErrorCode
```
grabIdServiceFailed
discoveryServiceFailed
idTokenInfoServiceFailed
exchangeTokenServiceFailed
authorizationInitializationFailure
securityValidationFailed
logoutFailed
invalidIdToken 
invalidNonce
invalidConfiguration       
somethingWentWrong           
network                      
invalidClientId               
invalidScope               
invalidRedirectUrl        
invalidAuthorizationCode     
invalidUrl                     
invalidPartnerId           
unAuthorized                 
authorizationFailed         
serviceUnavailable             
serviceError                  
invalidAccessToken             
invalidResponse                
invalidServiceDiscoveryUrl
  
partnerAppError = 10000        Application defined errors are 10000 and above
```
## Objective-C Support

For example in using Grab Id Partner SDK with Objective-C. Please follow example in GrabIdPartnerSDKTests-Objc.m in Tests. 

## License

MIT License
