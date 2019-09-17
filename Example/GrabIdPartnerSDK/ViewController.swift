/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import UIKit
import GrabIdPartnerSDK

struct Configuration {
  static let clientId = "350c848f-2580-45ba-8879-69d51d54f2d3"
  static let redirectUri = "grabweblogin://open"
  static let scope = "gid_test_scope_1 gid_test_scope_2 gid_test_scope_3 openid"
}

class ViewController: UIViewController {
  // show different mode using the SDK to create LoginSession
  private let useGrabIdPartnerSDKConfigs = true
  
  private let noCache = false
  
  private(set) var loginSession : LoginSession?

  @IBOutlet weak var grabSignInButton: UIButton!
  @IBOutlet weak var grabSignOutButton: UIButton!
  @IBOutlet weak var getIdTokenInfo: UIButton!
  @IBOutlet weak var testProtectedResourceButton: UIButton!
  @IBOutlet weak var messageScrollView: UIScrollView!
  @IBOutlet weak var messageLabel: UILabel!

  private func setupUI() {
    grabSignInButton.isEnabled = true
    grabSignInButton.backgroundColor = Constants.Styles.grabGreenColor
    
    if !(loginSession?.accessToken?.isEmpty ?? true) {
      getIdTokenInfo.isEnabled = true
      getIdTokenInfo.backgroundColor = Constants.Styles.grabGreenColor
    } else {
      getIdTokenInfo.isEnabled = false
      getIdTokenInfo.backgroundColor = Constants.Styles.lightGray
    }
    
    if getIdTokenInfo.isEnabled {
      testProtectedResourceButton.isEnabled = true
      testProtectedResourceButton.backgroundColor = Constants.Styles.grabGreenColor
    } else {
      testProtectedResourceButton.isEnabled = false
      testProtectedResourceButton.backgroundColor = Constants.Styles.lightGray
    }
  }
  
  private func login(loginSession: LoginSession?) {
    guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
      logMessage(message: "can't instantiate GrabIdPartner")
      return
    }
    
    if let loginSession = loginSession {
      logMessage(message: "Calling login API ->\r", isBold: true)
      grabIdPartner.login(loginSession: loginSession, presentingViewController: self) { [weak self] (error) in
        guard let self = self else {
          return
        }
        if let error = error {
          self.logMessage(message: error.localizeMessage ?? "Grab SignIn failed!!!")
        } else {
          if !(loginSession.accessToken?.isEmpty ?? true) {
            self.logMessage(message: "Obtained loginSession from cache")
            self.printLoginSession(loginSession: loginSession)
          }
        }
        self.setupUI()
      }
    }
    else {
      self.logMessage(message: "Invalid redirection URL")
    }
  }
  
  private func signInWithLoginConfig() {
    guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
      logMessage(message: "can't instantiage GrabIdPartner")
      return
    }
    
    grabIdPartner.loadLoginSession() { [weak self] (loginSession, error) in
      guard let self = self else {
        return
      }
      
      self.loginSession = loginSession
      
      if let error = error {
        self.logMessage(message:error.localizeMessage ?? "Failed to load login configurations")
      } else {
        self.login(loginSession: loginSession)
      }
    }
  }

  private func signIn() {
    let url = URL(string:Configuration.redirectUri)
    if let redirectUrl = url {
      loginSession = LoginSession(clientId: Configuration.clientId, redirectUrl: redirectUrl, scope: Configuration.scope, serviceDiscoveryUrl:"<please obtain this from the GrabId team>")
      login(loginSession: loginSession)
    }
  }
  
  @IBAction func didGrabSignIn(_ sender: Any) {
    if useGrabIdPartnerSDKConfigs {
      // sign in using configurations in plist.
      signInWithLoginConfig()
    } else {
      signIn()
    }
  }

  @IBAction func didGrabSignOut(_ sender: Any) {
    guard let loginSession = loginSession else {
      self.clearLogMessage()
      return
    }
    
    guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
      logMessage(message: "Failed to create GrabIdPartner!")
      return
    }
    
    grabIdPartner.logout(loginSession: loginSession) { [weak self] (error) in
      guard let self = self else {
        return
      }
      if let error = error {
        self.logMessage(message: "logout failed - error \(error.localizeMessage ?? "unknown")")
      } else {
        self.clearLogMessage()
      }
    }
    
    setupUI()
  }

  @IBAction func didGetIdTokenInfo(_ sender: Any) {
    guard let loginSession = loginSession else {
      logMessage(message: "Invalid login session!")
      return
    }
    
    guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
      logMessage(message: "Failed to create GrabIdPartner!")
      return
    }
    
    grabIdPartner.getIdTokenInfo(loginSession: loginSession) { [weak self] (idTokenInfo, error) in
      guard let self = self else {
        return
      }
      
      if let error = error {
        self.logMessage(message: error.localizeMessage ?? "Failed to retreive idToken Info!!!")
      } else if let idTokenInfo = idTokenInfo {
        self.logMessage(message: "Grab Verify idToken success:")
        self.printIdTokenInfo(idTokenInfo: idTokenInfo)
      } else {
        self.logMessage(message: "Failed to retreive idToken Info!!!")
      }
    }
  }

  @IBAction func didAccessTestRes(_ sender: Any) {
    logMessage(message: "Testing access to protect resource -->")
    guard let loginSession = loginSession else {
      logMessage(message: "Invalid login session!")
      return
    }
    
    if Constants.ProtectedResource.testResourceUri.isEmpty {
      if let infoPlist = Bundle.main.infoDictionary,
        let config = infoPlist["GrabIdPartnerSDK"] as? Dictionary<String, AnyObject> {
        Constants.ProtectedResource.testResourceUri = config["TestProtectedResourceUrl"] as? String ?? ""
      }
    }
    
    guard let url = createUrl(baseUrl: Constants.ProtectedResource.testResourceUri) else {
      logMessage(message: "Invalid URL \( Constants.ProtectedResource.testResourceUri) provided to fetchProtectedResource")
      return
    }
    
    guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
      logMessage(message: "Failed to create GrabIdPartner!")
      return
    }
    
    // make sure the token has not expired
    guard grabIdPartner.isValidAccessToken(loginSession: loginSession),
      let accessToken = loginSession.accessToken else {
      // TODO
      // call login to refresh the token
      logMessage(message: "Invalid URL provided to fetchProtectedResource")
      return
    }
    
    fetchProtectedResource(url: url, accessToken: accessToken) { [weak self] (results, error) in
      guard let self = self else {
        return
      }
      
      guard let results = results else {
        self.logMessage(message: "Unexpected results from service \(Constants.ProtectedResource.testResourceUri)")
        return
      }
      
      if let error = error {
        // Retry failed request - if error is auth related, it should call login and retry
        if error.code == .authorizationFailed {
          
          
        } else {
          self.logMessage(message: error.localizeMessage ?? "Service \(Constants.ProtectedResource.testResourceUri) failed!!!")
          self.logMessage(message: "Retrying fetchProtectedResource on error")

          self.retryfetchProtectedResource(url: url, loginSession: loginSession)
        }
        
        return
      }
      
      self.onFetchProtectedResourceSuccess(loginSession: loginSession, results: results)
    }
  }

  private func retryfetchProtectedResource(url: URL, loginSession: LoginSession) {
    guard let accessToken = loginSession.accessToken else {
      return
    }
    self.fetchProtectedResource(url: url, accessToken: accessToken) { [weak self] (results, error) in
      guard let self = self else {
        return
      }
      
      if let error = error {
        self.logMessage(message: "Retry failed with error: \(error.localizeMessage ?? GrabIdPartnerLocalization.somethingWentWrong.rawValue)")
        return
      }
      
      self.onFetchProtectedResourceSuccess(loginSession: loginSession, results: results)
    }
  }

  private func onFetchProtectedResourceSuccess(loginSession: LoginSession, results: [String: Any]?) {
    guard let results = results else {
      return
    }
    self.logMessage(message: "Access \(Constants.ProtectedResource.testResourceUri) success:")
    
    self.logMessage(message: "Results:")
    guard let authMethod = results["authMethod"] else {
      self.logMessage(message: "failed to get authMethod")
      return
    }
    self.logMessage(message: "authMethod: \(authMethod)")
    
    guard let serviceID = results["serviceID"] else {
      self.logMessage(message: "failed to get serviceID")
      return
    }
    self.logMessage(message: "serviceID: \(serviceID)")
    
    guard let userID = results["userID"] else {
      self.logMessage(message: "failed to get userID")
      return
    }
    self.logMessage(message: "userId: \(userID)")
    
    guard let serviceUserID = results["serviceUserID"] else {
      self.logMessage(message: "failed to get serviceUserID")
      return
    }
    self.logMessage(message: "serviceUserID: \(serviceUserID)")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    messageLabel.bounds.size.width = messageScrollView.bounds.width
    messageScrollView.contentSize.width =  messageScrollView.bounds.width

    logMessage(message: "Starting GrabIdPartnerSDK Example:\r")
    
    messageScrollView.contentSize.height =  messageLabel.bounds.size.height
    messageScrollView.setNeedsLayout()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  func exchangeToken(url: URL) {
    guard let grabIdPartner = GrabIdPartner.sharedInstance(),
          let loginSession = loginSession else {
      assertionFailure("Invalid login session!")
      return
    }
    
    logMessage(message: "\rCalling exchangeToken API ->\r", isBold: true)
    logMessage(message: "Redirect Url:")
    logMessage(message: "\(url.absoluteString)")
    grabIdPartner.exchangeToken(loginSession: loginSession, url: url) { (error) in
      DispatchQueue.main.async { [weak self] in
        if let error = error {
          self?.logMessage(message: error.localizeMessage ?? "exchangeToken failed!!!")
        } else {
          self?.printLoginSession(loginSession: loginSession)
        }
        _ = grabIdPartner.loginCompleted(loginSession: loginSession) {
          self?.logMessage(message: error?.localizeMessage ?? "loginCompleted!!!")
        }
        
        self?.setupUI()
      }
    }
  }
  
  func logMessage(message : String, isBold : Bool = false, isItalic: Bool = false) {
    var font : [NSAttributedString.Key : Any]?
    if isBold {
      font = [.font: UIFont.boldSystemFont(ofSize: 12.0)]
    } else if isItalic {
      font = [.font: UIFont.italicSystemFont(ofSize: 12.0)]
    } else {
      font = [.font: UIFont.systemFont(ofSize: 12.0)]
    }

    let attributedString = NSMutableAttributedString(string: "\(message)\r", attributes: font)
    var logMessage : NSMutableAttributedString?
    if let labelAttributedText = messageLabel.attributedText { 
      logMessage = NSMutableAttributedString(attributedString: labelAttributedText)
      logMessage?.append(attributedString)
    }
    if let logMessage = logMessage {
      messageLabel.attributedText = logMessage
    }
    messageLabel.sizeToFit()
    
    if messageLabel.bounds.size.height > messageScrollView.bounds.size.height {
      let bottomOffset = CGPoint(x: 0, y: messageLabel.bounds.size.height - messageScrollView.bounds.size.height)
      messageScrollView.setContentOffset(bottomOffset, animated: true)
    }
  }

  func createUrl(baseUrl: String, params: [NSURLQueryItem]? = nil) -> URL? {
    let urlComponents = NSURLComponents(string: baseUrl)
      
    if let paramsValues = params {
      urlComponents?.queryItems = paramsValues as [URLQueryItem]
    }
      
    return urlComponents?.url
  }

  // this method is to demonstrate calling Grab API with the access token. it is not part of the Grab Id Partner SDK.
  private func fetchProtectedResource(url: URL, accessToken: String = "", completion: @escaping([String: Any]?, GrabIdPartnerError?) -> Void) {
    guard !url.absoluteString.isEmpty else {
      let error = GrabIdPartnerError(code: .somethingWentWrong,
                                     localizeMessage:"invalid url",
                                     domain: .protectedResource,
                                     serviceError: nil)
      completion(nil,error)
      return
    }
    
    var urlRequest = URLRequest(url: url)
    urlRequest.setValue("BEARER \(accessToken)", forHTTPHeaderField: "Authorization")
    urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
    urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    urlRequest.httpMethod = "GET"
    // urlRequest.timeoutInterval = ???
    let session = URLSession.shared
    let task = session.dataTask(with: urlRequest) { (data, response, error) in
      var results : [String: Any]? = nil
      var gradIdPartnerError : GrabIdPartnerError? = nil
      if let error = error {
        gradIdPartnerError = GrabIdPartnerError(code: .serviceError,
                                                localizeMessage:Constants.Localize.testResServiceFailed,
                                                domain: .protectedResource,
                                                serviceError: error)
      } else {
        if let response = response as? HTTPURLResponse,
          !(200...299 ~= response.statusCode) {
          let error = GrabIdPartnerError(code: .idTokenInfoServiceFailed,
                                          localizeMessage:"\(response.statusCode)",
                                          domain: .protectedResource,
                                          serviceError: nil)
          completion(nil, error)
          return
        }

        guard let data = data else {
          let error = GrabIdPartnerError(code: .somethingWentWrong,
                                         localizeMessage:"Response did not return valid JSON",
                                         domain: .protectedResource,
                                         serviceError: error)
          DispatchQueue.main.async {
            completion(nil, error)
          }
          return
        }
        
        do {
          if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let authMethod = json["authMethod"],
              let serviceID = json["serviceID"],
              let userID = json["userID"],
              let serviceUserID = json["serviceUserID"] {
            results = ["authMethod": authMethod,
                           "serviceID": serviceID,
                           "userID": userID,
                           "serviceUserID": serviceUserID]
          } else {
            gradIdPartnerError = GrabIdPartnerError(code: .serviceError,
                                           localizeMessage:Constants.Localize.invalidServiceResponse,
                                           domain: .protectedResource,
                                           serviceError: error)
          }
        } catch let parseError {
          gradIdPartnerError = GrabIdPartnerError(code: .serviceError,
                                         localizeMessage:parseError.localizedDescription,
                                         domain: .protectedResource,
                                         serviceError: parseError)
        }
        
        // Dispatch the result to the UI thread. logMessage and setupUI must be called from UI thread.
        DispatchQueue.main.async {
          completion(results, gradIdPartnerError)
        }
      }
    }
    task.resume()
  }
  
  func printLoginSession(loginSession : LoginSession) {
    if let accessToken = loginSession.accessToken {
      self.logMessage(message: "accessToken:")
      self.logMessage(message: "\(accessToken)\r", isItalic: true)
      if let tokenExpiresAt = loginSession.accessTokenExpiresAt {
        self.logMessage(message: "accessTokenExpiresAt:")
        self.logMessage(message: "\(tokenExpiresAt)\r", isItalic: true)
      }
    }
    
    if let refreshToken = loginSession.refreshToken {
      self.logMessage(message: "refreshToken:")
      self.logMessage(message: "\(refreshToken)", isItalic: true)
    }
    
    if let idToken = loginSession.idToken {
      self.logMessage(message: "idToken:")
      self.logMessage(message: "\(idToken)\r", isItalic: true)
    }

    if let code = loginSession.code {
      self.logMessage(message: "code:")
      self.logMessage(message: "\(code)\r", isItalic: true)
    }
    
    if let state = loginSession.state {
      self.logMessage(message: "state:")
      self.logMessage(message: "\(state)\r", isItalic: true)
    }
    
    if let codeVerifier = loginSession.codeVerifier {
      self.logMessage(message: "code verifier:")
      self.logMessage(message: "\(codeVerifier)\r", isItalic: true)
    }
    
    if let nonce = loginSession.nonce {
      self.logMessage(message: "nonce:")
      self.logMessage(message: "\(nonce)\r", isItalic: true)
    }

    if let tokenType = loginSession.tokenType {
      self.logMessage(message: "tokenType:")
      self.logMessage(message: "\(tokenType)\r", isItalic: true)
    }
  }
  
  private func printIdTokenInfo(idTokenInfo: IdTokenInfo) {
      self.logMessage(message: "Id Token Info:")
    
    if let audience = idTokenInfo.audience {
      self.logMessage(message: "audience:")
      self.logMessage(message: "\(audience)\r", isItalic: true)
    }
    
    if let service = idTokenInfo.service {
      self.logMessage(message: "service:")
      self.logMessage(message: "\(service)\r", isItalic: true)
    }
    
    if let validDate = idTokenInfo.notValidBefore {
      self.logMessage(message: "validDate:")
      self.logMessage(message: "\(validDate)\r", isItalic: true)
    }
    
    if let expiration = idTokenInfo.expiration {
      self.logMessage(message: "expiration:")
      self.logMessage(message: "\(expiration)\r", isItalic: true)
    }
    
    if let issueDate = idTokenInfo.issueDate {
      self.logMessage(message: "issueDate:")
      self.logMessage(message: "\(issueDate)\r", isItalic: true)
    }
    
    if let issuer = idTokenInfo.issuer {
      self.logMessage(message: "issuer:")
      self.logMessage(message: "\(issuer)\r", isItalic: true)
    }
    
    if let tokenId = idTokenInfo.tokenId {
      self.logMessage(message: "tokenId:")
      self.logMessage(message: "\(tokenId)\r", isItalic: true)
    }
    
    if let partnerId = idTokenInfo.partnerId {
      self.logMessage(message: "partnerId:")
      self.logMessage(message: "\(partnerId)\r", isItalic: true)
    }
    
    if let partnerUserId = idTokenInfo.partnerUserId {
      self.logMessage(message: "partnerUserId:")
      self.logMessage(message: "\(partnerUserId)\r", isItalic: true)
    }
    
    if let nonce = idTokenInfo.nonce {
      self.logMessage(message: "nonce:")
      self.logMessage(message: "\(nonce)\r", isItalic: true)
    }
  }
  
  private func clearLogMessage() {
    messageLabel.text = ""
    messageLabel.sizeToFit()
  }

  private struct Constants {
    struct Configuration {
      static let logMessageCharacterLimit = 10000
      static let logMessageCharacterPurge = 7000
    }
    struct ProtectedResource {
      static var testResourceUri : String = ""  // Initialize this with the test endpoint
    }
    struct Styles {
      static let grabGreenColor = UIColor(red:0.00, green:0.69, blue:0.25, alpha:1.0)
      static let lightGray = UIColor.lightGray
    }
    struct Localize {
      // TODO: Add app specific strings to Localizable.strings files.
      // Following are sample errors. App should define their own error messages.
      static let testResServiceFailed = "Test res service failed!"
      static let invalidServiceResponse = "Test res service returned invalid response"
    }
  }
}

