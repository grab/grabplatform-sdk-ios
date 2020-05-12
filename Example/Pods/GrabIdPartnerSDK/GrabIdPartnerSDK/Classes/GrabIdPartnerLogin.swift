/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import Foundation
import SafariServices

enum GrantType : String {
  case authorizationCode = "authorization_code"
  case refreshToken = "refresh_token"
}

class GrabIdPartnerSdkLock {}

@objc public protocol GrabIdPartnerProtocol {
  static func sharedInstance() -> GrabIdPartnerProtocol?
  func loadLoginSession(completion: @escaping(LoginSession?, GrabIdPartnerError?) -> Void)
  func login(loginSession: LoginSession, presentingViewController: UIViewController, completion: @escaping(GrabIdPartnerError?) -> Void)
  func exchangeToken(loginSession: LoginSession, url: URL, completion: @escaping (GrabIdPartnerError?) -> Void)
  func getIdTokenInfo(loginSession: LoginSession, completion: @escaping (IdTokenInfo?, GrabIdPartnerError?) -> Void)
  func loginCompleted(loginSession: LoginSession) -> Bool
  func loginCompleted(loginSession: LoginSession, completion:(()->Void)?) -> Bool
  func logout(loginSession: LoginSession, completion: ((GrabIdPartnerError?) -> Void)?)
  func isValidAccessToken(loginSession: LoginSession) -> Bool
  func isValidIdToken(idTokenInfo: IdTokenInfo) -> Bool
}

@objc open class LoginSession : NSObject, NSCoding {
  @objc public let clientId : String
  @objc public let redirectUrl : URL
  @objc public let scope : String
  @objc public let hint : String
  @objc public let idTokenHint : String
  @objc public let prompt : String

  // Used by app for one time transactions scenario - base64 encoded jwt
  @objc public let request : String?
  
  // The OpenID Connect ACR optional parameter to the authorize endpoint will be utilized to pass in
  // service id info and device ID
  @objc public let acrValues : [String:String]?
  
  // setter internal, public get to GrabId Partner SDK
  @objc public fileprivate(set) var code: String? = nil
  @objc public fileprivate(set) var codeVerifier : String? = nil
  @objc public fileprivate(set) var accessTokenExpiresAt : Date? = nil
  @objc public fileprivate(set) var state : String? = nil
  @objc public fileprivate(set) var tokenType : String? = nil
  @objc public fileprivate(set) var nonce : String? = nil

  // don't store the tokens in user defaults, they are stored in the keychain
  @objc public fileprivate(set) var accessToken: String?
  @objc public fileprivate(set) var idToken : String? = nil
  @objc public fileprivate(set) var refreshToken : String? = nil
  @objc public fileprivate(set) var serviceDiscoveryUrl : String

  // internal to GrabId Partner SDK
  fileprivate var safariView : SFSafariViewController? = nil

  fileprivate var codeChallenge : String? = nil

  // end points
  fileprivate var authorizationEndpoint : String?
  fileprivate var tokenEndpoint : String?
  fileprivate var idTokenVerificationEndpoint : String?
  fileprivate var clientPublicInfoEndpoint: String?
 
  @objc public init(clientId : String, redirectUrl : URL, scope: String, request: String? = nil, acrValues: [String:String]? = nil,
                    serviceDiscoveryUrl: String, hint: String = "", idTokenHint: String = "", prompt:String = "") {
    self.clientId = clientId
    self.redirectUrl = redirectUrl
    self.scope = scope
    self.serviceDiscoveryUrl = serviceDiscoveryUrl
    self.request = request
    self.acrValues = acrValues
    self.hint = hint
    self.idTokenHint = idTokenHint
    self.prompt = prompt
    
    super.init()
  }

  @objc public convenience init(clientId : String, redirectUrl : URL, scope: String, request: String? = nil, acrValues: [String:String]? = nil,
                    serviceDiscoveryUrl: String, hint: String = "") {
    self.init(clientId: clientId, redirectUrl:redirectUrl, scope: scope, request: request, acrValues: acrValues,
              serviceDiscoveryUrl: serviceDiscoveryUrl, hint: hint, prompt: "")
  }
  
  public func encode(with aCoder: NSCoder) {
    aCoder.encode(code,forKey: "code")
    aCoder.encode(hint,forKey: "hint")
    aCoder.encode(codeVerifier,forKey: "codeVerifier")
    aCoder.encode(accessTokenExpiresAt, forKey: "accessTokenExpiresAt")
    aCoder.encode(state, forKey: "state")
    aCoder.encode(tokenType, forKey: "tokenType")
    aCoder.encode(nonce, forKey: "nonce")
    aCoder.encode(serviceDiscoveryUrl, forKey: "serviceDiscoveryUrl")
    aCoder.encode(tokenEndpoint, forKey: "tokenEndpoint")
    aCoder.encode(authorizationEndpoint, forKey: "authorizationEndpoint")
    aCoder.encode(idTokenVerificationEndpoint, forKey: "idTokenVerificationEndpoint")
    aCoder.encode(clientPublicInfoEndpoint, forKey: "clientPublicInfoEndpoint")
    aCoder.encode(idTokenHint,forKey: "idTokenHint")
    aCoder.encode(prompt,forKey: "prompt")
  }
  
  public required init?(coder aDecoder: NSCoder) {
    // this is used to get loginSession data from user preference
    // the user will provide the clientId, redirectUrl, scope,
    // request, and acrValues and we don't store them in user
    // preference
    self.clientId = ""
    self.redirectUrl = URL(string: "temp")!
    self.scope = ""
    self.request = ""
    self.acrValues = nil
    
    self.code = aDecoder.decodeObject(forKey:"code") as? String
    self.codeVerifier = aDecoder.decodeObject(forKey:"codeVerifier") as? String
    self.accessTokenExpiresAt = aDecoder.decodeObject(forKey:"accessTokenExpiresAt") as? Date
    self.state = aDecoder.decodeObject(forKey:"state") as? String
    self.tokenType = aDecoder.decodeObject(forKey:"tokenType") as? String
    self.nonce = aDecoder.decodeObject(forKey:"nonce") as? String
    self.serviceDiscoveryUrl = aDecoder.decodeObject(forKey:"serviceDiscoveryUrl") as? String ?? ""
    self.tokenEndpoint = aDecoder.decodeObject(forKey:"tokenEndpoint") as? String
    self.authorizationEndpoint = aDecoder.decodeObject(forKey:"authorizationEndpoint") as? String
    self.idTokenVerificationEndpoint = aDecoder.decodeObject(forKey:"idTokenVerificationEndpoint") as? String
    self.clientPublicInfoEndpoint = aDecoder.decodeObject(forKey:"clientPublicInfoEndpoint") as? String
    self.hint = aDecoder.decodeObject(forKey:"hint") as? String ?? ""
    self.idTokenHint = aDecoder.decodeObject(forKey:"idTokenHint") as? String ?? ""
    self.prompt = aDecoder.decodeObject(forKey:"prompt") as? String ?? ""
  }
}

@objc open class GrabIdPartner : NSObject, GrabIdPartnerProtocol {
  static private var grabIdPartner : GrabIdPartner? = nil
  static private let grabIdPartnerSdkLock = GrabIdPartnerSdkLock()

  private let codeChallengeMethod = "S256"
  private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
  private let authorization_grantType = "authorization_code"
  private let grantType = "refresh_token"
  private let responseType = "code"
  private let endPoints : GrabApi.serviceEndPoints? = nil
  private let urlSession: URLSession?
  private let bundle: Bundle?

  @objc static public func sharedInstance() -> GrabIdPartnerProtocol? {
    objc_sync_enter(GrabIdPartner.grabIdPartnerSdkLock)
    defer { objc_sync_exit(GrabIdPartner.grabIdPartnerSdkLock) }
    
    if grabIdPartner != nil {
      return grabIdPartner
    } else {
      grabIdPartner = GrabIdPartner()
      return grabIdPartner
    }
  }

  @objc public init(bundle: Bundle = Bundle.main) {
    self.urlSession = .shared
    self.bundle = bundle
    super.init()
  }

  @objc public init(urlSession: URLSession = .shared, bundle: Bundle = Bundle.main) {
    self.urlSession = urlSession
    self.bundle = bundle
    super.init()
  }
  
  @objc public func loadLoginSession(completion: @escaping(LoginSession?, GrabIdPartnerError?) -> Void) {
    var clientId : String? = nil
    var scope : String? = nil
    var redirectUrl : String? = nil
    var request : String? = nil
    var serviceDiscoveryUrl : String? = nil
    var loginSession : LoginSession? = nil
    var error : GrabIdPartnerError? = nil
    var acrValues : [String:String]? = nil
    var hint : String = ""
    var idTokenHint : String = ""
    var prompt : String = ""

    guard let bundle = bundle else {
      DispatchQueue.main.async {
        let error = GrabIdPartnerError(code: .invalidAppBundle, localizeMessage:GrabIdPartnerLocalization.invalidAppBundle.rawValue,
                                   domain: .loadConfiguration, serviceError: nil)
        completion(nil, error)
      }
      return
    }
    
    if let infoPlist = bundle.infoDictionary,
       let config = infoPlist["GrabIdPartnerSDK"] as? Dictionary<String, AnyObject> {

      clientId = config["ClientId"] as? String
      redirectUrl = config["RedirectUrl"] as? String
      scope = config["Scope"] as? String
      serviceDiscoveryUrl = config["ServiceDiscoveryUrl"] as? String ?? ""
      request = config["Request"] as? String
      acrValues = config["AcrValues"] as? Dictionary<String, String>
      hint = config["Hint"] as? String ?? ""
      idTokenHint = config["IdTokenHint"] as? String ?? idTokenHint
      prompt = config["prompt"] as? String ?? prompt
      
      (loginSession, error) = createLoginSession(clientId: clientId, redirectUrl: redirectUrl, scope: scope, request: request,
                                                   acrValues: acrValues, serviceDiscoveryUrl: serviceDiscoveryUrl,
                                                   hint: hint, idTokenHint: idTokenHint, prompt: prompt)
    } else {
      error = GrabIdPartnerError(code: .invalidConfiguration, localizeMessage:GrabIdPartnerLocalization.invalidConfiguration.rawValue,
                                 domain: .loadConfiguration, serviceError: nil)
    }

    DispatchQueue.main.async {
      completion(loginSession, error)
    }
  }
  
  public func createLoginSession(clientId: String?, redirectUrl: String?, scope: String?,
                                  request: String? = nil, acrValues: [String:String]? = nil, serviceDiscoveryUrl: String?,
                                  hint: String = "", idTokenHint: String = "", prompt:String = "") -> (LoginSession?, GrabIdPartnerError?) {
    if let appClientId = clientId, !appClientId.isEmpty,
       let appScope = scope, !appScope.isEmpty,
       let appRedirectUrl = redirectUrl,
       let appUrl = URL(string: appRedirectUrl),
       let serviceDiscoveryUrl = serviceDiscoveryUrl {
      var loginSession: LoginSession? = nil
      loginSession = LoginSession(clientId: appClientId,
                                  redirectUrl: appUrl,
                                  scope: appScope,
                                  request: request,
                                  acrValues: acrValues,
                                  serviceDiscoveryUrl: serviceDiscoveryUrl,
                                  hint: hint,
                                  idTokenHint: idTokenHint,
                                  prompt: prompt)
      return (loginSession, nil)
    } else {
      var error : GrabIdPartnerError? = nil
      var errorCode = GrabIdPartnerErrorCode.somethingWentWrong
      var errorMessage = GrabIdPartnerLocalization.somethingWentWrong.rawValue
      if clientId?.isEmpty ?? true {
        errorCode = .invalidClientId
        errorMessage = GrabIdPartnerLocalization.invalidClientId.rawValue
      } else if redirectUrl?.isEmpty ?? true {
        errorCode = .invalidRedirectUrl
        errorMessage = GrabIdPartnerLocalization.invalidRedirectUrl.rawValue
      } else if scope?.isEmpty ?? true {
        errorCode = .invalidScope
        errorMessage = GrabIdPartnerLocalization.invalidScope.rawValue
      }
      
      error = GrabIdPartnerError(code: errorCode, localizeMessage:errorMessage,
                                 domain: .loadConfiguration, serviceError: nil)
      return (nil, error)
    }
  }
  
  @objc public func login(loginSession: LoginSession, presentingViewController: UIViewController, completion: @escaping(GrabIdPartnerError?) -> Void) {
    // Restore loginSession if it is cached. If the refresh token is available, we will refresh the token
    // without going thru the web login flow. However, if refresh token failed, it will use web login flow
    // to get a new set of tokens.
    if loginSession.accessToken == nil {
      // restore loginSession if the token is cached
      _ = restoreLoginSession(loginSession: loginSession)
    }
    
    let now = Date()
    
    if !(loginSession.accessToken?.isEmpty ?? true),
      loginSession.accessTokenExpiresAt ?? now > now {
      completion(nil)
    } else {
      getAuthenticateURL(loginSession: loginSession) { authUrl, loginWithGrabUrl, appStoreLinkUrl, error in
        DispatchQueue.main.async {
          if let error = error  {
            completion(error)
            return
          }

          if #available(iOS 10.0, *) {
            if let loginWithGraburl = loginWithGrabUrl {
              UIApplication.shared.open(loginWithGraburl, options: [:], completionHandler: { [weak self] success in
                guard let strongSelf = self else {
                  DispatchQueue.main.async {
                    completion(GrabIdPartnerError(code: GrabIdPartnerErrorCode.invalidUrl, domain: GrabIdPartnerErrorDomain.authorization))
                  }
                  return
                }
                DispatchQueue.main.async {
                  if !success {
                    if let appStoreLinkUrl = appStoreLinkUrl {
                      let error = strongSelf.sendToAppStore(appStoreLinkUrl: appStoreLinkUrl)
                      completion(error)
                    } else {
                      strongSelf.webLogin(url: authUrl, loginSession: loginSession, presentingViewController: presentingViewController, completion: completion)
                    }
                  } else {
                    completion(nil)
                  }
                }
              })
            } else if let appStoreLinkUrl = appStoreLinkUrl {
              let error = self.sendToAppStore(appStoreLinkUrl: appStoreLinkUrl)
              completion(error)
            } else {
              self.webLogin(url: authUrl, loginSession: loginSession, presentingViewController: presentingViewController, completion: completion)
            }
          } else {
            self.webLogin(url: authUrl, loginSession: loginSession, presentingViewController: presentingViewController, completion: completion)
          }
      }
    }
  }
    }
    
  // if there is an app store link, we will launch into the app store.
  private func sendToAppStore(appStoreLinkUrl: URL) -> GrabIdPartnerError {
    guard #available(iOS 10.0, *), UIApplication.shared.canOpenURL(appStoreLinkUrl) else {
      return GrabIdPartnerError(code: .failedTolaunchAppStoreLink,
                                localizeMessage: appStoreLinkUrl.absoluteString,
                                domain: .appStore,
                                serviceError: nil)
    }

    UIApplication.shared.open(appStoreLinkUrl)

    return GrabIdPartnerError(code: .launchAppStoreLink,
                              localizeMessage: appStoreLinkUrl.absoluteString,
                              domain: .appStore,
                              serviceError: nil)
  }

  private func getLoginWithGrabDeepLink(loginWithGrabDict: [[String:String]]) -> (String?,String?) {
    guard loginWithGrabDict.count > 0 else {
      return (nil, nil)
    }
    
    var loginWithGrab: String? = nil
    var appStoreLink: String? = nil
    for dictItem in loginWithGrabDict {
      // first get the protocol_pax_ios which contains the scheme to check if any app is registered
      // to handle this url scheme (this is for verison validation to avoid launching into a dead link
      if loginWithGrab == nil, let loginUrlScheme = dictItem["protocol_pax_ios"], schemeAvailable(urlScheme: loginUrlScheme) {
        // found an app that can handle the login deeplink
        loginWithGrab = dictItem ["protocol_ios"]
      } else if appStoreLink?.isEmpty ?? true, let item = dictItem["appstore_link_ios"] {
        appStoreLink = item
      }
      if loginWithGrab != nil, appStoreLink != nil {
        // found the links we are looking for
        break
      }
    }
  
    return (loginWithGrab, appStoreLink)
  }

  private func schemeAvailable(urlScheme: String) -> Bool {
    if let url = URL(string: urlScheme) {
      return UIApplication.shared.canOpenURL(url)
    }
    return false
  }
  
  private func webLogin(url: URL?, loginSession: LoginSession, presentingViewController: UIViewController, completion: @escaping(GrabIdPartnerError?) -> Void) {
    guard let url = url else {
      let error = GrabIdPartnerError(code: .invalidUrl,
                                      localizeMessage:loginSession.authorizationEndpoint ?? GrabIdPartnerLocalization.invalidUrl.rawValue,
                                      domain: .authorization,
                                      serviceError: nil)
      completion(error)
      return
    }
      
    loginSession.safariView = SFSafariViewController(url: url)
    if let safariView = loginSession.safariView {
      presentingViewController.present(safariView, animated: true)
      completion(nil)
    }
  }
  
  @objc public func exchangeToken(loginSession: LoginSession, url: URL, completion: @escaping (GrabIdPartnerError?) -> Void) {
    let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
    
    let codeParam = urlComponents?.queryItems?.filter({ $0.name == "code" }).first
    let errorParam = urlComponents?.queryItems?.filter({ $0.name == "error" }).first
    let stateParam = urlComponents?.queryItems?.filter({ $0.name == "state" }).first
    
    guard errorParam?.value == nil else {
      let error = GrabIdPartnerError(code: .securityValidationFailed,
                                      localizeMessage: GrabIdPartnerLocalization.securityValidationFailed.rawValue,
                                      domain: .exchangeToken,
                                      serviceError: nil)
      DispatchQueue.main.async {
        completion(error)
      }
      return
    }
    
    guard let code = codeParam?.value,
          let state = stateParam?.value,
          state == loginSession.state else {
      let error = GrabIdPartnerError(code: .securityValidationFailed,
                                       localizeMessage:GrabIdPartnerLocalization.securityValidationFailed.rawValue,
                                       domain: .exchangeToken,
                                       serviceError: nil)
      DispatchQueue.main.async {
        completion(error)
      }
      return
    }
    
    // read token from keychain, return token from cache if it hasn't expired
    if restoreLoginSession(loginSession: loginSession),
        let accessTokenExpiresAt = loginSession.accessTokenExpiresAt,
        accessTokenExpiresAt > Date() {
      // cached loginSession contains valid access token.
      DispatchQueue.main.async {
        completion(nil)
      }
    } else {
      loginSession.code = code
      getAccessToken(loginSession: loginSession, completion: completion);
    }
  }
  
  private func getAccessToken(loginSession: LoginSession, completion: @escaping (GrabIdPartnerError?) -> Void) {
    guard let tokenEndpoint = loginSession.tokenEndpoint,
      let codeVerifier = loginSession.codeVerifier else {
        return
    }
    
    // access token is invalid or expired, if we have a refresh token, use it to get the access token.
    GrabApi.fetchToken(session: urlSession ?? .shared, exchangeTokenEndPoint: tokenEndpoint, clientID: loginSession.clientId,
                       code: loginSession.code ?? "", codeVerifier: codeVerifier,
                       grantType: GrantType.authorizationCode, refreshToken: loginSession.refreshToken ?? "",
                       redirectUri: loginSession.redirectUrl.absoluteString, state: loginSession.state ?? "") { results, error in
      guard error == nil, let results = results else {
        _ = GrabIdPartner.removeLoginSession(loginSession: loginSession)
        DispatchQueue.main.async {
          completion(error)
        }
        return
      }
                        
      // Extract results from Dictionary
      let accessToken = results["access_token"] as? String
      let expiresIn = results["expires_in"] as? Int
      let idToken = results["id_token"] as? String
      let refreshToken : String? = results["refresh_token"] as? String ?? ""
      let tokenType = results["token_type"] as? String
      
      guard
        let accessTokenValue = accessToken,
        let expiresInValue = expiresIn,
        let idTokenValue = idToken,
        let refreshTokenValue = refreshToken,
        let tokenTypeValue = tokenType
        else {
          let error = GrabIdPartnerError(code: .invalidResponse, localizeMessage:GrabIdPartnerLocalization.invalidResponse.rawValue,
                                         domain: .exchangeToken, serviceError: nil)
          DispatchQueue.main.async {
            completion(error)
          }
          return
      }
      
      guard
        !accessTokenValue.isEmpty,
        !String(expiresInValue).isEmpty
        else {
          let error = GrabIdPartnerError(code: .invalidResponse, localizeMessage:GrabIdPartnerLocalization.invalidResponse.rawValue,
                                         domain: .exchangeToken, serviceError: nil)
          DispatchQueue.main.async {
            completion(error)
          }
          return
      }
      
      loginSession.accessTokenExpiresAt = Date(timeIntervalSinceNow: Double(expiresInValue))
      loginSession.accessToken = accessTokenValue
      loginSession.refreshToken = refreshTokenValue
      loginSession.tokenType = tokenTypeValue
      loginSession.idToken = idTokenValue
      
      self.saveLoginSession(loginSession: loginSession)
      
      DispatchQueue.main.async {
        completion(nil)
      }
    }
  }
  
  @objc public func logout(loginSession: LoginSession, completion: ((GrabIdPartnerError?) -> Void)? = nil) {
    loginSession.accessToken = nil
    loginSession.idToken = nil
    loginSession.refreshToken = nil
    loginSession.authorizationEndpoint = nil
    loginSession.idTokenVerificationEndpoint = nil
    loginSession.tokenEndpoint = nil

    _ = loginCompleted(loginSession: loginSession)
    
    if GrabIdPartner.removeLoginSession(loginSession: loginSession),
      let completion = completion {
      DispatchQueue.main.async {
        completion(nil)
      }
    } else {
      let error = GrabIdPartnerError(code: .logoutFailed, localizeMessage:GrabIdPartnerLocalization.logoutFailed.rawValue,
                                     domain: .logout, serviceError: nil)
      if let completion = completion {
        DispatchQueue.main.async {
          completion(error)
        }
      }
    }
  }

  @objc public func getIdTokenInfo(loginSession: LoginSession, completion: @escaping (IdTokenInfo?, GrabIdPartnerError?) -> Void) {
    guard let idToken = loginSession.idToken,
          let idTokenVerificationEndpoint = loginSession.idTokenVerificationEndpoint else {
          let error = GrabIdPartnerError(code: .invalidIdToken, localizeMessage:GrabIdPartnerLocalization.invalidIdToken.rawValue,
                                         domain: .getIdTokenInfo, serviceError: nil)
      DispatchQueue.main.async {
        completion(nil, error)
      }
      return
    }
    
    guard let nonce = loginSession.nonce else {
      let error = GrabIdPartnerError(code: .invalidNonce, localizeMessage:GrabIdPartnerLocalization.invalidNonce.rawValue,
                                     domain: .getIdTokenInfo, serviceError: nil)
      DispatchQueue.main.async {
        completion(nil, error)
      }
      return
    }
    
    if let idTokenInfo = IdTokenInfo.restoreIdToken(loginSession: loginSession),
      let expirationDate = idTokenInfo.expiration,
      expirationDate > Date() {
      // found valid idToken, return it
      DispatchQueue.main.async {
        completion(idTokenInfo, nil)
      }
      return
    } else {
      // delete the cache token and get a new one
      UserDefaults.standard.removeObject(forKey: nonce)
    }
    
    GrabApi.fetchGetIdTokenInfo(session: urlSession ?? .shared, getIdTokenInfoEndpoint: idTokenVerificationEndpoint, clientId: loginSession.clientId, idToken: idToken, nonce: nonce) { (results, error) in
      guard error == nil,
        let results = results else {
          DispatchQueue.main.async {
            completion(nil, error)
          }
          _ = GrabIdPartner.removeLoginSession(loginSession: loginSession)
          return
      }

      // Extract results from Dictionary
      let audience = results["audience"] as? String
      let expiresAt = results["expires_at"] as? Double
      let issueAt = results["issue_at"] as? Double
      let issuer = results["issuer"] as? String
      let notValidBefore = results["notValidBefore"] as? Double
      let tokenId = results["tokenId"] as? String
      let nonce = results["nonce"] as? String
      let partnerId = results["partnerId"] as? String
      let partnerUserId = results["partnerUserId"] as? String
      let service = results["service"] as? String
        
      guard let audienceIdValue = audience, !audienceIdValue.isEmpty,
            let expiresAtValue = expiresAt,
            let issuerValue = issuer,
            let issueAtValue = issueAt,
            let notValidBeforeValue = notValidBefore,
            let nonceValue = nonce, !nonceValue.isEmpty,
            let serviceValue = service, !serviceValue.isEmpty,
            let partnerIdValue = partnerId, !partnerIdValue.isEmpty,
            let partnerUserIdValue = partnerUserId, !partnerUserIdValue.isEmpty,
            let tokenIdValue = tokenId, !tokenIdValue.isEmpty,
            nonce == loginSession.nonce else {
        let error = GrabIdPartnerError(code: .invalidNonce, localizeMessage:GrabIdPartnerLocalization.invalidNonce.rawValue,
                                       domain: .getIdTokenInfo, serviceError: nil)
        DispatchQueue.main.async {
          completion(nil, error)
        }
        return
      }
     
      let idTokenInfo = IdTokenInfo(audience: audienceIdValue,
                                    service: serviceValue,
                                    notValidBefore: Date(timeIntervalSince1970: notValidBeforeValue),
                                    expiration: Date(timeIntervalSince1970: expiresAtValue),
                                    issueDate: Date(timeIntervalSince1970: issueAtValue),
                                    issuer: issuerValue,
                                    tokenId: tokenIdValue,
                                    partnerId: partnerIdValue,
                                    partnerUserid: partnerUserIdValue,
                                    nonce: nonceValue)

      idTokenInfo.saveIdTokenInfo(loginSession: loginSession)
      
      DispatchQueue.main.async {
        completion(idTokenInfo, nil)
      }
    }
  }

  
  @objc public func loginCompleted(loginSession: LoginSession) -> Bool {
    return loginCompleted(loginSession: loginSession, completion:nil)
  }
  
  @objc public func loginCompleted(loginSession: LoginSession, completion:(()->Void)?) -> Bool {
    guard let safariView = loginSession.safariView else {
      if let dismissHandler = completion {
        DispatchQueue.main.async {
          dismissHandler()
        }
      }
      return false
    }
    
    loginSession.safariView = nil

    safariView.dismiss(animated: true) {
      if let dismissHandler = completion {
        DispatchQueue.main.async {
          dismissHandler()
        }
      }
    }
    
    return true
  }


  // Helper to determine if the accessToken and idToken are valid and not expired.
  @objc public func isValidAccessToken(loginSession: LoginSession) -> Bool {
    let now = Date()
    guard !(loginSession.accessToken?.isEmpty ?? true),
      let accessTokenExpired = loginSession.accessTokenExpiresAt,
      accessTokenExpired > now else {
        GrabIdPartner.removeTokens(loginSession: loginSession)
        return false
    }
    
    return true
  }

  @objc public func isValidIdToken(idTokenInfo: IdTokenInfo) -> Bool {
    guard let nonce = idTokenInfo.nonce else {
      return false
    }
    
    let now = Date()
    guard idTokenInfo.tokenId != nil,
      (idTokenInfo.expiration ?? now) > now,
      now >= (idTokenInfo.notValidBefore ?? Date()) else {
        UserDefaults.standard.removeObject(forKey: nonce)
        return false
    }
    return true
  }
  
  static fileprivate func getUserDefaultKey(loginSession: LoginSession) -> String? {
    let scopeArray = loginSession.scope.lowercased().components(separatedBy: " ")
    let sortedScope = scopeArray.joined(separator: " ")
    guard !sortedScope.isEmpty else { return nil }
    
    return "\(loginSession.clientId).\(sortedScope)"
  }

  private struct Constants {
    struct Localize {
      static let invalidUrl = "Invalid service"
      static let invalidConfiguration = "Invalid configuration"
      static let invalidClientId = "Invalid client id"
      static let invalidRedirectUrl = "Invalid redirect url"
      static let invalidScope = "Invalid scope"
      static let somethingWentWrong = "Something went wrong."
      static let invalidAuthorizationUrl = "Invalid authorization url"
    }
    struct keyChainKeys {
      static let accessToken = "accessToken"
      static let idToken = "idToken"            // signed idToken
      static let tokenId = "tokenId"            // unsigned idToken
      static let refreshToken = "refreshToken"
    }
  }

  // MARK: private functions
  private func getTokens(loginSession: LoginSession) -> Bool {
    let keyChain = KeychainTokenItem(service: loginSession.clientId)
    
    // read token from keychain
    let accessToken = keyChain.readToken(id: Constants.keyChainKeys.accessToken, scope: loginSession.scope)
    let idToken = keyChain.readToken(id: Constants.keyChainKeys.idToken, scope: loginSession.scope)
    let refreshToken = keyChain.readToken(id: Constants.keyChainKeys.refreshToken, scope: loginSession.scope)
    
    if !(accessToken?.isEmpty ?? true) {
      loginSession.accessToken = accessToken
      loginSession.idToken = idToken
      loginSession.refreshToken = refreshToken
      return true
    } else {
      _ = GrabIdPartner.removeLoginSession(loginSession: loginSession)
      return false
    }
  }
  
  private func saveTokens(loginSession: LoginSession) -> Bool {
    let keyChain = KeychainTokenItem(service: loginSession.clientId)
    do {
      try keyChain.saveToken(id: Constants.keyChainKeys.accessToken, scope: loginSession.scope, token: loginSession.accessToken ?? "")
      try keyChain.saveToken(id: Constants.keyChainKeys.idToken, scope: loginSession.scope, token: loginSession.idToken ?? "")
      try keyChain.saveToken(id: Constants.keyChainKeys.refreshToken, scope: loginSession.scope, token: loginSession.refreshToken ?? "")
      
      return true
    } catch {
      // delete the tokens from keychain == no caching
      _ = GrabIdPartner.removeLoginSession(loginSession: loginSession)
    }
    
    return false
  }
  
  // remove tokens from key chain
  static fileprivate func removeTokens(loginSession: LoginSession) {
    let keyChain = KeychainTokenItem(service: loginSession.clientId)
    _ = try? keyChain.removeToken(id: Constants.keyChainKeys.accessToken, scope: loginSession.scope)
    _ = try? keyChain.removeToken(id: Constants.keyChainKeys.refreshToken, scope: loginSession.scope)
    _ = try? keyChain.removeToken(id: Constants.keyChainKeys.idToken, scope: loginSession.scope)
    
    loginSession.accessToken = nil
    loginSession.idToken = nil
    loginSession.refreshToken = nil
  }
  
  private func saveLoginSession(loginSession: LoginSession) {
    if saveTokens(loginSession: loginSession) {
      let key = GrabIdPartner.getUserDefaultKey(loginSession: loginSession)
      if let key = key {
        let encodedData = NSKeyedArchiver.archivedData(withRootObject: loginSession)
        UserDefaults.standard.set(encodedData, forKey: key)
      }
    }
  }
  
  // If either idToken or accessToken have expired. We need to delete the cache loginSession
  // and return false and delete the cache login session.
  private func restoreLoginSession(loginSession: LoginSession) -> Bool {
    guard let key = GrabIdPartner.getUserDefaultKey(loginSession: loginSession),
          let cacheLoginSessionData = UserDefaults.standard.data(forKey: key),
          let cacheLoginSession = NSKeyedUnarchiver.unarchiveObject(with: cacheLoginSessionData) as? LoginSession else {
      return false
    }

    // refresh token,access token, and idtoken are stored in the keychain and restored
    // in getTokens
    if getTokens(loginSession: loginSession) {
      loginSession.nonce = cacheLoginSession.nonce
      loginSession.code = cacheLoginSession.code
      loginSession.codeVerifier = cacheLoginSession.codeVerifier
      loginSession.state = cacheLoginSession.state
      loginSession.tokenType = cacheLoginSession.tokenType
      loginSession.serviceDiscoveryUrl = cacheLoginSession.serviceDiscoveryUrl
      loginSession.accessTokenExpiresAt = cacheLoginSession.accessTokenExpiresAt
      loginSession.tokenEndpoint = cacheLoginSession.tokenEndpoint
      loginSession.authorizationEndpoint = cacheLoginSession.authorizationEndpoint
      loginSession.idTokenVerificationEndpoint = cacheLoginSession.idTokenVerificationEndpoint
      
      return true
    }
    
    return false
  }
  
  static internal func removeLoginSession(loginSession: LoginSession) -> Bool {
    
    guard let key = GrabIdPartner.getUserDefaultKey(loginSession: loginSession),
          UserDefaults.standard.data(forKey: key) != nil else {
      return false
    }
    
    // delete token cache
    UserDefaults.standard.removeObject(forKey: key)
    GrabIdPartner.removeTokens(loginSession: loginSession)

    return true
  }
  
  private func getSecurityValues() -> (String?, String?, String?, String?) {
    guard let verifier = AuthorizationCodeGenerator.getCodeVerifier() else {
      return (nil, nil, nil, nil)
    }
    
    guard let codeChallenge = AuthorizationCodeGenerator.getCodeChallenge(verifier: verifier) else {
      return (nil, nil, nil, nil)
    }
    
    let nonce = NSUUID().uuidString.lowercased()
    let state = NSUUID().uuidString.lowercased()
    return (nonce, state, verifier, codeChallenge)
  }
  
  fileprivate static func getAcrValuesString(acrValues : [String:String]?) -> String? {
    var acrValueString : String? = nil
    if let acrValues = acrValues,
        acrValues.count > 0 {
      var acrValueArrays = [String]()
      for (key, value) in acrValues {
        if !key.isEmpty,
            !value.isEmpty {
          acrValueArrays.append("\(key):\(value)")
        }
      }
      acrValueString = acrValueArrays.joined(separator: " ")
    }
    
    return acrValueString
  }

  private func getLoginWithGrabDeeplinkDictionary(clientId: String, clientPublicInfoUri: String?, completion:@escaping([[String:String]],GrabIdPartnerError?) -> Void) {
    if let clientPublicInfoUri = clientPublicInfoUri, !clientPublicInfoUri.isEmpty {
      let fullClientPublicInfoUri = clientPublicInfoUri.replacingOccurrences(of: "{client_id}", with: clientId, options: .literal, range: nil)
      GrabApi.fetchGrabAppDeeplinks(session: urlSession ?? .shared, customProtocolUrl:fullClientPublicInfoUri) { (loginWithGrabDict, error) in
        completion(loginWithGrabDict, error)
      }
    } else {
      // service has no app registered to handle login with Grab
      completion([], nil)
    }
  }
  
  private func getLoginUrls(loginSession: LoginSession,
                            queryParams: [URLQueryItem],
                            completion: @escaping(URL?,URL?,URL?,GrabIdPartnerError?) -> Void) {
    guard let authEndpoint = loginSession.authorizationEndpoint, let authUrl = GrabApi.createUrl(baseUrl: authEndpoint, params: queryParams) else {
      let error = GrabIdPartnerError(code: .invalidUrl, localizeMessage:loginSession.authorizationEndpoint ?? GrabIdPartnerLocalization.invalidResponse.rawValue,
                                     domain: .authorization, serviceError: nil)
      completion(nil, nil, nil, error)
      return
    }

    guard !queryParams.contains(where: { $0.name == "login_hint" || $0.name == "id_token_hint" || $0.name == "prompt" }) else {
      completion(authUrl, nil, nil, nil)
      return
    }
    
    // get the login with grab deeplink (if any),
    var loginWithAppUrl: URL? = nil
    
    // app store link
    var appStoreLinkUrl: URL? = nil
    
    getLoginWithGrabDeeplinkDictionary(clientId: loginSession.clientId, clientPublicInfoUri: loginSession.clientPublicInfoEndpoint) { [weak self] loginWithGrabDict, error in
      DispatchQueue.main.async {
        if error == nil {
          let (loginDeeplink, appStoreLink) = self?.getLoginWithGrabDeepLink(loginWithGrabDict: loginWithGrabDict) ?? (nil, nil)
          
          if let loginDeeplink = loginDeeplink {
            var params = queryParams
            params.append(URLQueryItem(name: "auth_endpoint", value: authEndpoint))
            loginWithAppUrl = GrabApi.createUrl(baseUrl: loginDeeplink, params: params)
          }
          
          if let appStoreLink = appStoreLink {
            appStoreLinkUrl = URL(string: appStoreLink)
          }
        }
        
        completion(authUrl, loginWithAppUrl, appStoreLinkUrl, nil)
      }
    }
  }
  
  private func getAuthenticateURL(loginSession: LoginSession, completion: @escaping(URL?,URL?,URL?,GrabIdPartnerError?) -> Void) {
    let (nonce, state, codeVerifier, codeChallenge) = getSecurityValues()
    guard nonce != nil,
          state != nil,
          codeVerifier != nil,
          codeChallenge != nil else {
      let error = GrabIdPartnerError(code: .authorizationInitializationFailure, localizeMessage:GrabIdPartnerLocalization.authorizationInitializationFailure.rawValue, domain: .authorization, serviceError: nil)
            completion(nil, nil, nil, error)
      return
    }
    
    loginSession.nonce = nonce
    loginSession.state = state
    loginSession.codeVerifier = codeVerifier
    loginSession.codeChallenge = codeChallenge
    
    var queryParams = [
      URLQueryItem(name: "client_id", value: loginSession.clientId),
      URLQueryItem(name: "code_challenge", value: codeChallenge),
      URLQueryItem(name: "code_challenge_method", value: codeChallengeMethod),
      URLQueryItem(name: "device_id", value: deviceId),
      URLQueryItem(name: "nonce", value: nonce),
      URLQueryItem(name: "redirect_uri", value: loginSession.redirectUrl.absoluteString),
      URLQueryItem(name: "response_type", value: responseType),
      URLQueryItem(name: "state", value: state),
      URLQueryItem(name: "scope", value: loginSession.scope)
    ]
    
    if !loginSession.hint.isEmpty {
      queryParams.append(URLQueryItem(name: "login_hint", value: loginSession.hint))
    }

    if !loginSession.idTokenHint.isEmpty {
      queryParams.append(URLQueryItem(name: "id_token_hint", value: loginSession.idTokenHint))
    }

    if !loginSession.prompt.isEmpty {
      queryParams.append(URLQueryItem(name: "prompt", value: loginSession.prompt))
    }

    // handle optional parameters
    if let request = loginSession.request,
      !request.isEmpty {
      queryParams.append(URLQueryItem(name: "request", value: request))
    }
    
    if let acrValueString = GrabIdPartner.getAcrValuesString(acrValues: loginSession.acrValues),
        !acrValueString.isEmpty {
      queryParams.append(URLQueryItem(name:"acr_values", value:acrValueString))
    }

    if let authEndpoint = loginSession.authorizationEndpoint, !authEndpoint.isEmpty {
      getLoginUrls(loginSession: loginSession, queryParams: queryParams, completion:completion)
    } else {
      GrabApi.fetchServiceConfigurations(session: urlSession ?? .shared, serviceDiscoveryUrl:loginSession.serviceDiscoveryUrl) { [weak self](endPoints, error) in
        guard error == nil, let strongSelf = self else {
          completion(nil, nil, nil, error)
          return
        }

        // Extract results from Dictionary
        loginSession.authorizationEndpoint = endPoints.loginUri
        loginSession.tokenEndpoint = endPoints.exchangeUri
        loginSession.idTokenVerificationEndpoint = endPoints.verify
        loginSession.clientPublicInfoEndpoint = endPoints.clientPublicInfoUri
        
        strongSelf.getLoginUrls(loginSession: loginSession, queryParams: queryParams, completion:completion)
      }
    }
  }
}
