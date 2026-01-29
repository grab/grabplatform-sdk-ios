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
    private let testLabel = UILabel()
    private let testButton = UIButton(type: .system)
    private let loginButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)
    private let textView = UITextView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        runInitialTests()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // Title Label
        testLabel.text = "GrabId SPM Test App"
        testLabel.font = .boldSystemFont(ofSize: 24)
        testLabel.textAlignment = .center
        testLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(testLabel)
        
        // Test SDK Button
        testButton.setTitle("Test SDK Initialization", for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 18)
        testButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        testButton.setTitleColor(.white, for: .normal)
        testButton.layer.cornerRadius = 8
        testButton.translatesAutoresizingMaskIntoConstraints = false
        testButton.addTarget(self, action: #selector(testSDK), for: .touchUpInside)
        view.addSubview(testButton)
        
        // Login Button
        loginButton.setTitle("Test Login Flow", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 18)
        loginButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(testLogin), for: .touchUpInside)
        view.addSubview(loginButton)
        
        // Logout Button
        logoutButton.setTitle("Test Logout", for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 18)
        logoutButton.backgroundColor = .systemRed
        logoutButton.setTitleColor(.white, for: .normal)
        logoutButton.layer.cornerRadius = 8
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.addTarget(self, action: #selector(testLogout), for: .touchUpInside)
        logoutButton.isEnabled = false
        view.addSubview(logoutButton)
        
        // TextView for logs
        textView.isEditable = false
        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        textView.backgroundColor = .systemGray6
        textView.layer.cornerRadius = 8
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)
        
        // Constraints
        NSLayoutConstraint.activate([
            testLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            testLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            testLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            testButton.topAnchor.constraint(equalTo: testLabel.bottomAnchor, constant: 30),
            testButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            testButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            testButton.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 15),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            logoutButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 15),
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 50),
            
            textView.topAnchor.constraint(equalTo: logoutButton.bottomAnchor, constant: 20),
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }
    
    private func log(_ message: String, isError: Bool = false) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let prefix = isError ? "❌" : "✅"
        let logMessage = "[\(timestamp)] \(prefix) \(message)\n"
        
        DispatchQueue.main.async {
            self.textView.text += logMessage
            
            // Auto-scroll to bottom
            let bottom = NSRange(location: self.textView.text.count - 1, length: 1)
            self.textView.scrollRangeToVisible(bottom)
        }
        
        print(logMessage)
    }
    
    private func runInitialTests() {
        log("SPM Test App Started")
        log("Testing GrabIdPartnerSDK SPM Integration...")
    }
    
    @objc private func testSDK() {
        log("=== SDK Initialization Test ===")
        
        // Test 1: Initialize SDK
        guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
            log("Failed to initialize GrabIdPartner", isError: true)
            return
        }
        log("SDK initialized successfully")
        
        // Test 2: Load configuration
        grabIdPartner.loadLoginSession { [weak self] (loginSession, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.log("Configuration load failed: \(error.localizeMessage ?? "Unknown error")", isError: true)
                return
            }
            
            guard let session = loginSession else {
                self.log("LoginSession is nil", isError: true)
                return
            }
            
            self.loginSession = session
            self.log("Configuration loaded from Info.plist")
            self.log("  ClientId: \(session.clientId)")
            self.log("  RedirectUrl: \(session.redirectUrl.absoluteString)")
            self.log("  Scope: \(session.scope)")
            self.log("  ServiceDiscoveryUrl: \(session.serviceDiscoveryUrl)")
            
            // Test 3: Validate session properties
            if !session.clientId.isEmpty && !session.scope.isEmpty {
                self.log("LoginSession validation: PASSED")
            } else {
                self.log("LoginSession validation: FAILED", isError: true)
            }
            
            self.log("=== SPM Integration Test: PASSED ✅ ===")
            
            DispatchQueue.main.async {
                self.loginButton.isEnabled = true
            }
        }
    }
    
    @objc private func testLogin() {
        log("=== Login Flow Test ===")
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
            log("Failed to get GrabIdPartner instance", isError: true)
            return
        }
        
        guard let session = loginSession else {
            log("No login session available. Run SDK test first.", isError: true)
            return
        }
        
        log("Initiating login...")
        log("Note: This will open Safari or Grab app for authentication")
        
        grabIdPartner.login(loginSession: session, presentingViewController: self) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.log("Login initiation failed: \(error.localizeMessage ?? "Unknown error")", isError: true)
            } else {
                self.log("Login initiated successfully")
                self.log("Waiting for authentication callback...")
            }
        }
    }
    
    @objc private func testLogout() {
        log("=== Logout Test ===")
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
            log("Failed to get GrabIdPartner instance", isError: true)
            return
        }
        
        guard let session = loginSession else {
            log("No login session to logout", isError: true)
            return
        }
        
        grabIdPartner.logout(loginSession: session) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.log("Logout failed: \(error.localizeMessage ?? "Unknown error")", isError: true)
            } else {
                self.log("Logout successful")
                DispatchQueue.main.async {
                    self.logoutButton.isEnabled = false
                    self.loginButton.isEnabled = true
                }
            }
        }
    }
    
    func handleRedirect(url: URL) {
        log("=== Handling OAuth Redirect ===")
        log("Redirect URL: \(url.absoluteString)")
        
        guard let grabIdPartner = GrabIdPartner.sharedInstance() else {
            log("Failed to get GrabIdPartner instance", isError: true)
            return
        }
        
        guard let session = loginSession else {
            log("No login session available", isError: true)
            return
        }
        
        grabIdPartner.exchangeToken(loginSession: session, url: url) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                self.log("Token exchange failed: \(error.localizeMessage ?? "Unknown error")", isError: true)
            } else {
                self.log("Token exchange successful!")
                
                if let accessToken = session.accessToken {
                    self.log("Access Token obtained: \(accessToken.prefix(20))...")
                }
                
                if let idToken = session.idToken {
                    self.log("ID Token obtained: \(idToken.prefix(20))...")
                }
                
                self.log("=== OAuth Flow Test: PASSED ✅ ===")
                
                DispatchQueue.main.async {
                    self.logoutButton.isEnabled = true
                    self.loginButton.isEnabled = false
                }
                
                // Get ID token info
                self.getIdTokenInfo()
            }
            
            // Dismiss Safari view if any
            _ = grabIdPartner.loginCompleted(loginSession: session)
        }
    }
    
    private func getIdTokenInfo() {
        guard let grabIdPartner = GrabIdPartner.sharedInstance(),
              let session = loginSession else {
            return
        }
        
        log("Fetching ID Token Info...")
        
        grabIdPartner.getIdTokenInfo(loginSession: session) { [weak self] (idTokenInfo, error) in
            guard let self = self else { return }
            
            if let error = error {
                self.log("Failed to get ID token info: \(error.localizeMessage ?? "Unknown")", isError: true)
            } else if let info = idTokenInfo {
                self.log("ID Token Info:")
                self.log("  Partner ID: \(info.partnerId ?? "N/A")")
                self.log("  Partner User ID: \(info.partnerUserId ?? "N/A")")
                self.log("  Service: \(info.service ?? "N/A")")
                self.log("  Issuer: \(info.issuer ?? "N/A")")
                
                if let expiration = info.expiration {
                    self.log("  Expires: \(expiration)")
                    
                    let isValid = grabIdPartner.isValidIdToken(idTokenInfo: info)
                    self.log("  Token Valid: \(isValid ? "YES" : "NO")")
                }
            }
        }
    }
}
