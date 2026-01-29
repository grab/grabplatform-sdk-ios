/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

import UIKit
import GrabIdPartnerSDK

class ViewController: UIViewController {
    private var loginSession: LoginSession?
    private let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        testSDK()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Title
        let titleLabel = UILabel()
        titleLabel.text = "GrabId SPM Test"
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Test Button
        let testButton = UIButton(type: .system)
        testButton.setTitle("Test SDK", for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        testButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        testButton.setTitleColor(.white, for: .normal)
        testButton.layer.cornerRadius = 10
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.addTarget(self, action: #selector(testSDK), for: .touchUpInside)
        view.addSubview(testButton)
        
        // Login Button
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("Test Login", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        loginButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 10
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(testLogin), for: .touchUpInside)
        view.addSubview(loginButton)
        
        // Logout Button
        let logoutButton = UIButton(type: .system)
        logoutButton.setTitle("Test Logout", for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        logoutButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.layer.cornerRadius = 10
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(testLogout), for: .touchUpInside)
        view.addSubview(logoutButton)
        
        // Get ID Token Info Button
        let getIdTokenButton = UIButton(type: .system)
        getIdTokenButton.setTitle("Get ID Token Info", for: .normal)
        getIdTokenButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        getIdTokenButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        getIdTokenButton.setTitleColor(.white, for: .normal)
        getIdTokenButton.layer.cornerRadius = 10
        getIdTokenButton.translatesAutoresizingMaskIntoConstraints = false
        getIdTokenButton.addTarget(self, action: #selector(testGetIdTokenInfo), for: .touchUpInside)
        view.addSubview(getIdTokenButton)
        
        // Test Protected Resource Button
        let testProtectedButton = UIButton(type: .system)
        testProtectedButton.setTitle("Test Protected Resource", for: .normal)
        testProtectedButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        testProtectedButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        testProtectedButton.setTitleColor(.white, for: .normal)
        testProtectedButton.layer.cornerRadius = 10
        testProtectedButton.translatesAutoresizingMaskIntoConstraints = false
        testProtectedButton.addTarget(self, action: #selector(testProtectedResource), for: .touchUpInside)
        view.addSubview(testProtectedButton)
        
        // Log TextView
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        textView.layer.cornerRadius = 8
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray4.cgColor
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        // Layout
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            testButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            testButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            testButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            testButton.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 10),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            logoutButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 10),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            
            getIdTokenButton.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 10),
            getIdTokenButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            getIdTokenButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            getIdTokenButton.heightAnchor.constraint(equalToConstant: 50),
            
            testProtectedButton.topAnchor.constraint(equalTo: getIdTokenButton.bottomAnchor, constant: 10),
            testProtectedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            testProtectedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            testProtectedButton.heightAnchor.constraint(equalToConstant: 50),
            
            textView.topAnchor.constraint(equalTo: testProtectedButton.bottomAnchor, constant: 15),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let logMessage = "[\(timestamp)] \(message)\n"
        
        DispatchQueue.main.async {
            self.textView.text += logMessage
            let bottom = NSRange(location: self.textView.text.count - 1, length: 1)
            self.textView.scrollRangeToVisible(bottom)
        }
        
        print(logMessage)
    }
    
    @objc private func testSDK() {
        log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        log("🧪 Starting SPM Integration Test")
        log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // Test 1: SDK Initialization
        log("Test 1: SDK Initialization...")
        guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
            log("❌ FAILED: Cannot initialize GrabIdPartner")
            return
        }
        log("✅ PASSED: SDK initialized")
        
        // Test 2: Load Configuration
        log("\nTest 2: Load Configuration...")
        grabIdPartner.loadLoginSession { [weak self] (loginSession, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.log("❌ FAILED: \(error.localizeMessage ?? "Unknown error")")
                return
            }
            
            guard let session = loginSession else {
                self.log("❌ FAILED: LoginSession is nil")
                return
            }
            
            self.loginSession = session
            self.log("✅ PASSED: Configuration loaded")
            self.log("  • ClientId: \(session.clientId)")
            self.log("  • RedirectUrl: \(session.redirectUrl.absoluteString)")
            self.log("  • Scope: \(session.scope)")
            
            // Test 3: Validate Session
            self.log("\nTest 3: Validate LoginSession...")
            if !session.clientId.isEmpty && !session.scope.isEmpty {
                self.log("✅ PASSED: LoginSession is valid")
            } else {
                self.log("❌ FAILED: LoginSession validation failed")
                return
            }
            
            // Final Result
            self.log("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            self.log("🎉 SPM Integration Test: PASSED ✅")
            self.log("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            self.log("\n✅ SPM implementation is working correctly!")
            self.log("✅ Ready for production use")
        }
    }
    
    @objc private func testLogin() {
        log("\n🔐 Testing Login Flow...")
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance(),
              let session = loginSession else {
            log("❌ Run 'Test SDK' first")
            return
        }
        
        log("Initiating login (will open Safari/Grab app)...")
        
        grabIdPartner.login(loginSession: session, presentingViewController: self) { [weak self] error in
            if let error = error {
                self?.log("❌ Login failed: \(error.localizeMessage ?? "Unknown")")
            } else {
                self?.log("✅ Login initiated successfully")
                if !(session.accessToken?.isEmpty ?? true) {
                    self?.log("✅ Obtained loginSession from cache")
                    self?.printLoginSession(session: session)
                }
            }
        }
    }
    
    @objc private func testLogout() {
        log("\n🚪 Testing Logout...")
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance(),
              let session = loginSession else {
            log("❌ No active session to logout")
            return
        }
        
        grabIdPartner.logout(loginSession: session) { [weak self] error in
            if let error = error {
                self?.log("❌ Logout failed: \(error.localizeMessage ?? "Unknown")")
            } else {
                self?.log("✅ Logout successful")
                self?.log("Session cleared")
            }
        }
    }
    
    @objc private func testGetIdTokenInfo() {
        log("\n🎫 Testing Get ID Token Info...")
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance(),
              let session = loginSession else {
            log("❌ No active session. Run 'Test Login' first")
            return
        }
        
        grabIdPartner.getIdTokenInfo(loginSession: session) { [weak self] (idTokenInfo, error) in
            if let error = error {
                self?.log("❌ Failed to get ID token info: \(error.localizeMessage ?? "Unknown")")
            } else if let idTokenInfo = idTokenInfo {
                self?.log("✅ ID Token Info retrieved successfully:")
                self?.printIdTokenInfo(idTokenInfo: idTokenInfo)
            } else {
                self?.log("❌ Failed to retrieve ID token info")
            }
        }
    }
    
    @objc private func testProtectedResource() {
        log("\n🔒 Testing Protected Resource Access...")
        
        guard let session = loginSession else {
            log("❌ No active session. Run 'Test Login' first")
            return
        }
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
            log("❌ Failed to get GrabIdPartner instance")
            return
        }
        
        // Check if access token is valid
        guard grabIdPartner.isValidAccessToken(loginSession: session),
              let accessToken = session.accessToken else {
            log("❌ Invalid or expired access token. Please login again")
            return
        }
        
        // Get the test resource URL from Info.plist
        var testResourceUri = ""
        if let infoPlist = Bundle.main.infoDictionary,
           let config = infoPlist["GrabIdPartnerSDK"] as? [String: Any] {
            testResourceUri = config["TestProtectedResourceUrl"] as? String ?? ""
        }
        
        if testResourceUri.isEmpty {
            log("⚠️  TestProtectedResourceUrl not configured in Info.plist")
            log("Add it under GrabIdPartnerSDK -> TestProtectedResourceUrl")
            return
        }
        
        guard let url = URL(string: testResourceUri) else {
            log("❌ Invalid URL: \(testResourceUri)")
            return
        }
        
        log("Calling protected resource: \(testResourceUri)")
        
        fetchProtectedResource(url: url, accessToken: accessToken) { [weak self] (results, error) in
            if let error = error {
                self?.log("❌ Protected resource call failed: \(error.localizeMessage ?? "Unknown")")
            } else if let results = results {
                self?.log("✅ Protected resource accessed successfully:")
                if let authMethod = results["authMethod"] {
                    self?.log("  • authMethod: \(authMethod)")
                }
                if let serviceID = results["serviceID"] {
                    self?.log("  • serviceID: \(serviceID)")
                }
                if let userID = results["userID"] {
                    self?.log("  • userID: \(userID)")
                }
                if let serviceUserID = results["serviceUserID"] {
                    self?.log("  • serviceUserID: \(serviceUserID)")
                }
            }
        }
    }
    
    func handleRedirect(url: URL) {
        log("\n🔄 Handling OAuth redirect...")
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance(),
              let session = loginSession else {
            log("❌ No session available")
            return
        }
        
        grabIdPartner.exchangeToken(loginSession: session, url: url) { [weak self] error in
            if let error = error {
                self?.log("❌ Token exchange failed: \(error.localizeMessage ?? "Unknown")")
            } else {
                self?.log("✅ Token obtained successfully!")
                self?.log("✅ OAuth flow completed!")
                self?.printLoginSession(session: session)
            }
            
          
            _ = grabIdPartner.loginCompleted(loginSession: session)
        }
    }
    
    // MARK: - Helper Methods
    
    private func printLoginSession(session: LoginSession) {
        log("\n📋 Login Session Details:")
        
        if  let tokenType = session.tokenType,
            let accessToken = session.accessToken {
            log(" • tokenType: \(tokenType)\r\n  • accessToken: \(accessToken)")
            if let expiresAt = session.accessTokenExpiresAt {
                log("  • accessTokenExpiresAt: \(expiresAt)")
            }
        } else {
          log("\n📋 Login Session: missing tokenType or accessToken")
        }
        
        if let refreshToken = session.refreshToken {
            log("  • refreshToken: \(refreshToken)")
        }
        
        if let idToken = session.idToken {
            log("  • idToken: \(idToken)")
        }
        
        if let code = session.code {
            log("  • code: \(code)")
        }
        
        if let state = session.state {
            log("  • state: \(state)")
        }
        
        if let codeVerifier = session.codeVerifier {
            log("  • codeVerifier: \(codeVerifier)")
        }
        
        if let nonce = session.nonce {
            log("  • nonce: \(nonce)")
        }
    }
    
    private func printIdTokenInfo(idTokenInfo: IdTokenInfo) {
        if let audience = idTokenInfo.audience {
            log("  • audience: \(audience)")
        }
        
        if let service = idTokenInfo.service {
            log("  • service: \(service)")
        }
        
        if let notValidBefore = idTokenInfo.notValidBefore {
            log("  • notValidBefore: \(notValidBefore)")
        }
        
        if let expiration = idTokenInfo.expiration {
            log("  • expiration: \(expiration)")
        }
        
        if let issueDate = idTokenInfo.issueDate {
            log("  • issueDate: \(issueDate)")
        }
        
        if let issuer = idTokenInfo.issuer {
            log("  • issuer: \(issuer)")
        }
        
        if let tokenId = idTokenInfo.tokenId {
            log("  • tokenId: \(tokenId)")
        }
        
        if let partnerId = idTokenInfo.partnerId {
            log("  • partnerId: \(partnerId)")
        }
        
        if let partnerUserId = idTokenInfo.partnerUserId {
            log("  • partnerUserId: \(partnerUserId)")
        }
        
        if let nonce = idTokenInfo.nonce {
            log("  • nonce: \(nonce)")
        }
    }
    
    private func fetchProtectedResource(url: URL, accessToken: String, completion: @escaping([String: Any]?, GrabIdPartnerError?) -> Void) {
        var urlRequest = URLRequest(url: url)
        urlRequest.setValue("BEARER \(accessToken)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        urlRequest.httpMethod = "GET"
        
        let session = URLSession.shared
        let task = session.dataTask(with: urlRequest) { (data, response, error) in
            DispatchQueue.main.async {
                if let error = error {
                    let grabError = GrabIdPartnerError(code: .serviceError,
                                                       localizeMessage: "Network error: \(error.localizedDescription)",
                                                       domain: .protectedResource,
                                                       serviceError: error)
                    completion(nil, grabError)
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse,
                   !(200...299 ~= httpResponse.statusCode) {
                    let grabError = GrabIdPartnerError(code: .serviceError,
                                                       localizeMessage: "HTTP error: \(httpResponse.statusCode)",
                                                       domain: .protectedResource,
                                                       serviceError: nil)
                    completion(nil, grabError)
                    return
                }
                
                guard let data = data else {
                    let grabError = GrabIdPartnerError(code: .somethingWentWrong,
                                                       localizeMessage: "No data received",
                                                       domain: .protectedResource,
                                                       serviceError: nil)
                    completion(nil, grabError)
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        completion(json, nil)
                    } else {
                        let grabError = GrabIdPartnerError(code: .somethingWentWrong,
                                                           localizeMessage: "Invalid JSON response",
                                                           domain: .protectedResource,
                                                           serviceError: nil)
                        completion(nil, grabError)
                    }
                } catch {
                    let grabError = GrabIdPartnerError(code: .serviceError,
                                                       localizeMessage: "JSON parsing error: \(error.localizedDescription)",
                                                       domain: .protectedResource,
                                                       serviceError: error)
                    completion(nil, grabError)
                }
            }
        }
        task.resume()
    }
}
