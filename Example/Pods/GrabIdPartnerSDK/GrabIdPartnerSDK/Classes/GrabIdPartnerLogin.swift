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

class GrabIdPartnerSDKLock {}

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
  
  @objc public init(clientId : String, redirectUrl : URL, scope: String, request: String? = nil, acrValues: [String:String]? = nil,
                    serviceDiscoveryUrl: String, hint : String = "") {
    self.clientId = clientId
    self.redirectUrl = redirectUrl
    self.scope = scope
    self.serviceDiscoveryUrl = serviceDiscoveryUrl
    self.request = request
    self.acrValues = acrValues
    self.hint = hint
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
    self.hint = ""
    
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
  }
}

@objc open class GrabIdPartner : NSObject, GrabIdPartnerProtocol {
  static private var grabIdPartner : GrabIdPartner? = nil
  static let grabIdSdkLock = GrabIdPartnerSDKLock()
  
  private let codeChallengeMethod = "S256"
  private let deviceId = UIDevice.current.identifierForVendor?.uuidString ?? ""
  private let authorization_grantType = "authorization_code"
  private let grantType = "refresh_token"
  private let responseType = "code"
  private let endPoints : GrabApi.serviceEndPoints? = nil
  private let urlSession: URLSession?
  private let bundle: Bundle?
  
  @objc static public func sharedInstance() -> GrabIdPartnerProtocol? {
    objc_sync_enter(GrabIdPartner.grabIdSdkLock)
    defer { objc_sync_exit(GrabIdPartner.grabIdSdkLock) }
    if grabIdPartner != nil {
      return grabIdPartner
    } else {
      grabIdPartner = GrabIdPartner()
      printVersion()
      return grabIdPartner
    }
  }
  
  @objc public init(bundle: Bundle = Bundle.main) {
    self.urlSession = .shared
    self.bundle = bundle
  }
  
  @objc public init(urlSession: URLSession = .shared, bundle: Bundle = Bundle.main) {
    self.urlSession = urlSession
    self.bundle = bundle
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
    var hint : String? = nil
    
    guard let bundle = bundle else {
      assertionFailure("failed to load bundle")
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
    } else {
      error = GrabIdPartnerError(code: .invalidConfiguration, localizeMessage:GrabIdPartnerLocalization.invalidConfiguration.rawValue,
                                 domain: .loadConfiguration, serviceError: nil)
    }
    
    if let appClientId = clientId,
      let appScope = scope,
      let appRedirectUrl = redirectUrl,
      let appUrl = URL(string: appRedirectUrl),
      let serviceDiscoveryUrl = serviceDiscoveryUrl,
      let hint = hint {
      loginSession = LoginSession(clientId: appClientId, redirectUrl: appUrl, scope: appScope, request: request, acrValues: acrValues,
                                  serviceDiscoveryUrl: serviceDiscoveryUrl, hint: hint)
    } else {
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
    }
    
    DispatchQueue.main.async {
      completion(loginSession, error)
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
      webLogin(loginSession: loginSession, presentingViewController: presentingViewController, completion: completion)
    }
  }
  
  private func webLogin(loginSession: LoginSession, presentingViewController: UIViewController, completion: @escaping(GrabIdPartnerError?) -> Void) {
    // go through the in-app web authorization flow
    getAuthenticateURL(loginSession: loginSession) { (url, error) in
      if let error = error {
        DispatchQueue.main.async {
          completion(error)
        }
        return
      }
      
      guard let url = url else {
        let error = GrabIdPartnerError(code: .invalidUrl,
                                       localizeMessage:loginSession.authorizationEndpoint ?? GrabIdPartnerLocalization.invalidUrl.rawValue,
                                       domain: .authorization,
                                       serviceError: nil)
        DispatchQueue.main.async {
          completion(error)
        }
        return
      }
      
      DispatchQueue.main.async {
        loginSession.safariView = SFSafariViewController(url: url)
        if let safariView = loginSession.safariView {
          presentingViewController.present(safariView, animated: true)
          DispatchQueue.main.async {
            completion(nil)
          }
        }
      }
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
    
    safariView.dismiss(animated: true) {
      if let dismissHandler = completion {
        DispatchQueue.main.async {
          dismissHandler()
        }
        loginSession.safariView = nil
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
  
  private func getAuthenticateURL(loginSession: LoginSession, completion: @escaping(URL?,GrabIdPartnerError?) -> Void) {
    let (nonce, state, codeVerifier, codeChallenge) = getSecurityValues()
    guard nonce != nil,
      state != nil,
      codeVerifier != nil,
      codeChallenge != nil else {
        let error = GrabIdPartnerError(code: .authorizationInitializationFailure, localizeMessage:GrabIdPartnerLocalization.authorizationInitializationFailure.rawValue, domain: .authorization, serviceError: nil)
        completion(nil, error)
        return
    }
    
    loginSession.nonce = nonce
    loginSession.state = state
    loginSession.codeVerifier = codeVerifier
    loginSession.codeChallenge = codeChallenge
    
    var queryParams = [
      NSURLQueryItem(name: "client_id", value: loginSession.clientId),
      NSURLQueryItem(name: "code_challenge", value: codeChallenge),
      NSURLQueryItem(name: "code_challenge_method", value: codeChallengeMethod),
      NSURLQueryItem(name: "device_id", value: deviceId),
      NSURLQueryItem(name: "nonce", value: nonce),
      NSURLQueryItem(name: "redirect_uri", value: loginSession.redirectUrl.absoluteString),
      NSURLQueryItem(name: "response_type", value: responseType),
      NSURLQueryItem(name: "state", value: state),
      NSURLQueryItem(name: "scope", value: loginSession.scope)
    ]
    
    if !loginSession.hint.isEmpty {
      queryParams.append(NSURLQueryItem(name: "login_hint", value: loginSession.hint))
    }
    
    // handle optional parameters
    if let request = loginSession.request,
      !request.isEmpty {
      queryParams.append(NSURLQueryItem(name: "request", value: request))
    }
    
    if let acrValueString = GrabIdPartner.getAcrValuesString(acrValues: loginSession.acrValues),
      !acrValueString.isEmpty {
      queryParams.append(NSURLQueryItem(name:"acr_values", value:acrValueString))
    }
    
    if loginSession.authorizationEndpoint?.isEmpty ?? true {
      GrabApi.fetchServiceConfigurations(session: urlSession ?? .shared, serviceDiscoveryUrl:loginSession.serviceDiscoveryUrl) { (endPoints, error) in
        guard error == nil else {
          completion(nil, error)
          return
        }
        
        // Extract results from Dictionary
        loginSession.authorizationEndpoint = endPoints.loginUri
        loginSession.tokenEndpoint = endPoints.exchangeUri
        loginSession.idTokenVerificationEndpoint = endPoints.verify
        
        guard let authEndPoint = loginSession.authorizationEndpoint,
          !authEndPoint.isEmpty else {
            let error = GrabIdPartnerError(code: .invalidUrl, localizeMessage:GrabIdPartnerLocalization.invalidUrl.rawValue, domain: .authorization, serviceError: nil)
            completion(nil, error)
            return
        }
        
        if let url = GrabApi.createUrl(baseUrl: authEndPoint, params: queryParams) {
          completion(url, nil)
          return
        }
        
        let error = GrabIdPartnerError(code: .invalidUrl, localizeMessage:authEndPoint, domain: .authorization, serviceError: nil)
        completion(nil, error)
      }
    } else {
      if let loginUri = loginSession.authorizationEndpoint, let url = GrabApi.createUrl(baseUrl: loginUri, params: queryParams) {
        completion(url, nil)
        return
      }
      let error = GrabIdPartnerError(code: .invalidUrl, localizeMessage:loginSession.authorizationEndpoint ?? GrabIdPartnerLocalization.invalidResponse.rawValue,
                                     domain: .authorization, serviceError: nil)
      completion(nil, error)
    }
  }
}

extension GrabIdPartner {
  private static func printVersion() {
    let bundleId = "org.cocoapods.GrabIdPartnerSDK"
    if let version = Bundle(identifier: bundleId)?.infoDictionary?["CFBundleShortVersionString"] as? String {
      print("================================================")
      print("GrabIdPartnerSDK version \(version)")
      print("================================================")
    }
  }
}
