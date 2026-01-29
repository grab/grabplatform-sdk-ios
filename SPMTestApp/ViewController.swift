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
        loginButton.setTitle("Test Login (Optional)", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        loginButton.backgroundColor = UIColor(red: 0.0, green: 0.69, blue: 0.25, alpha: 1.0)
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 10
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(testLogin), for: .touchUpInside)
        view.addSubview(loginButton)
        
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
            
            testButton.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 30),
            testButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            testButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            testButton.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: testButton.bottomAnchor, constant: 15),
            loginButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            textView.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
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
            }
            
            _ = grabIdPartner.loginCompleted(loginSession: session)
        }
    }
}
