import XCTest
import GrabIdPartnerSDK
import SafariServices

public final class MockLoginUIViewController: UIViewController {
  public var controllerPresented : UIViewController? = nil
  
  override public func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
    controllerPresented = viewControllerToPresent
  }
}

protocol MockResponseDataProtocol {
  var mockResponse : String { get set }
  init(mockResponse: String)
}

public final class MockExchangeTokenResponseData : MockResponseDataProtocol {
  // Exchange token mock data
  public static let mockValidResponse = "{\"access_token\":\"testAccessToken\",\"token_type\":\"TestTokenType\",\"expires_in\":10,\"id_token\":\"testIdToken\",\"refresh_token\":\"testRefreshToken\"}"
  public static let mockExpiredTokenResponse = "{\"access_token\":\"testAccessToken\",\"token_type\":\"TestTokenType\",\"expires_in\":0,\"id_token\":\"testIdToken\",\"refresh_token\":\"testRefreshToken\"}"
  
  public var mockResponse : String
  
  init(mockResponse: String = MockExchangeTokenResponseData.mockValidResponse) {
    self.mockResponse = mockResponse
  }
}

public final class MockConfigurationResponseData : MockResponseDataProtocol {
  // Exchange token mock data
  public static let mockValidResponse = "{\"issuer\":\"https://idp.grab.com\",\"authorization_endpoint\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/authorize\",\"token_endpoint\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/token\",\"userinfo_endpoint\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/userinfo\",\"revocation_endpoint\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/revoke\",\"jwks_uri\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/public_keys\",\"response_types_supported\":[\"code\",\"token\"],\"code_challenge_methods_supported\":[\"S256\"],\"claims_supported\":[\"aud\",\"sub\",\"exp\",\"iat\",\"iss\",\"nbf\",\"name\",\"email\"],\"scopes_supported\":[\"openid\",\"profile.read\"],\"id_token_signing_alg_values_supported\":[\"RS256\"],\"userinfo_signing_alg_values_supported\":[\"none\"],\"request_object_signing_alg_values_supported\":[\"none\"],\"token_endpoint_auth_methods_supported\":[\"client_secret_post\"],\"registration_endpoint\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/authorize\",\"grant_types_supported\":[\"authorization_code\",\"implicit\"],\"acr_values_supported\":[\"service\",\"consent_ctx\"],\"request_parameter_supported\":true,\"id_token_verification_endpoint\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/id_tokens/token_info\",\"impl_pattern_endpoint\":\"https://api.stg-myteksi.com/grabid/v1/oauth2/scope_defs/name/impl_pattern\"}"
  
  public var mockResponse : String
  
  init(mockResponse: String = MockConfigurationResponseData.mockValidResponse) {
    self.mockResponse = mockResponse
  }
}

public final class MockTokenInfoResponseData : MockResponseDataProtocol {
  // Exchange token mock data
  public static var nonce : String = "0581ada9-cdbb-4f16-9d43-ad50debdbc6a" // extract from the valid response above, nonce has to match for getIdTokenInfo

  public static var mockValidResponse : String {
    get {
     return "{\"acr\":\"[\\\"service:PASSENGER\\\"]\",\"aud\":\"f795769ebe7446f38dede8fd36ee32fd\",\"exp\":2541371242,\"iat\":1541112042,\"iss\":\"https://idp.grab.com\",\"jti\":\"WiP03b0DRYWZTsd1IYY66g\",\"nbf\":1541112042,\"pid\":\"59da6712-d131-4a2f-8e23-1a775fb4f5b7\",\"sub\":\"8206f105-a224-41ba-a514-92ef6b39ff31\",\"svc\":\"PASSENGER\"  ,\"nonce\":\"\(nonce)\"}"
    }
  }
  
  public var mockResponse : String
  
  init(mockResponse: String = MockTokenInfoResponseData.mockValidResponse) {
    self.mockResponse = mockResponse
  }
}

public final class URLSessionMockSuccess : URLSession {
  
  public var mockTokenInfoResponseData = MockTokenInfoResponseData()
  public var mockConfigurationResponseData = MockConfigurationResponseData()
  public var mockExchangeTokenResponseData = MockExchangeTokenResponseData()

  public var mockTokenInfoServiceError = 200
  public var mockConfigurationServiceError = 200
  public var mockExchangeTokenServiceError = 200

  private let expectedConfigurationEndPoint = "/grabid/v1/oauth2/.well-known/openid-configuration"

  var url: NSURL?
  var request: NSURLRequest?
  
  var resultConfigurationEndPoint : String? = nil
  var resultExchangeTokenUrl : String? = nil
  var resultTokenInfoUrl : String? = nil

  private let dataTaskMock: URLSessionDataTaskMock
  
  public init(data: NSData?, response: URLResponse?, error: NSError?) {
    dataTaskMock = URLSessionDataTaskMock()
    dataTaskMock.taskResponse = (data, response, error)
  }
  
  override public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    guard let url = request.url else {
      XCTAssert(false, "invalid url")
      return self.dataTaskMock
    }
    
    if mockTokenInfoServiceError != 200 {
      mockTokenInfoResponseData.mockResponse = ""
    }

    if mockConfigurationServiceError != 200 {
      mockTokenInfoResponseData.mockResponse = ""
    }
    
    if mockExchangeTokenServiceError != 200 {
      mockTokenInfoResponseData.mockResponse = ""
    }
    
    if url.absoluteString.contains(expectedConfigurationEndPoint) {
      resultConfigurationEndPoint = url.absoluteString
      completionHandler(mockConfigurationResponseData.mockResponse.data(using: .utf8), HTTPURLResponse(url: url, statusCode: mockConfigurationServiceError, httpVersion: nil, headerFields: nil), nil)
    } else if url.absoluteString.contains("/token?") {
      resultExchangeTokenUrl = url.absoluteString
      completionHandler(mockExchangeTokenResponseData.mockResponse.data(using: .utf8), HTTPURLResponse(url: url, statusCode: mockExchangeTokenServiceError, httpVersion: nil, headerFields: nil), nil)
    } else if url.absoluteString.contains("/token_info?") {
      resultTokenInfoUrl = url.absoluteString
      completionHandler(mockTokenInfoResponseData.mockResponse.data(using: .utf8), HTTPURLResponse(url: url, statusCode: mockTokenInfoServiceError, httpVersion: nil, headerFields: nil), nil)
    }
    
    return self.dataTaskMock
  }

  final private class URLSessionDataTaskMock : URLSessionDataTask {
    
    typealias CompletionHandler = (NSData?, URLResponse?, NSError?) -> Void
    var completionHandler: CompletionHandler?
    var taskResponse: (NSData?, URLResponse?, NSError?)?
    
    override func resume() {
      completionHandler?(taskResponse?.0, taskResponse?.1, taskResponse?.2)
    }
  }
}

class GrabIdPartnerSDKTests: XCTestCase {
  override func setUp() {
    super.setUp()
    // do setup
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testLoginWithConfig() {
    // given
    
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    
    let expectation = self.expectation(description: "testLoginWithConfig")
    
    grabIdPartner.loadLoginSession() { (loginSession, error) in
      guard let loginSession = loginSession else {
        XCTAssert(false, "Invalid loginSession")
        return
      }
      
      XCTAssert(loginSession.clientId == "TestClientId")
      XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
      XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
      XCTAssert(loginSession.arcValues?.count ?? 0 == 2)
      XCTAssertTrue(loginSession.arcValues?["arcKey1"] == "arcValue1")
      XCTAssertTrue(loginSession.arcValues?["arcKey2"] == "arcValue2")
      XCTAssertTrue(loginSession.request == "test request")

      let presentingController = MockLoginUIViewController()

      // delete session data first
      grabIdPartner.logout(loginSession: loginSession) { _ in
      
        // then
        
        grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
          
          XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
          XCTAssertNil(error)
          
          expectation.fulfill()
        }
      }
    }
    waitForExpectations(timeout: 2, handler: nil)
  }

  func testLogin() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }

    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")

    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.arcValues == nil)
    XCTAssert(loginSession.request == nil)

    // given
    
    let presentingController = MockLoginUIViewController()
    let expectation = self.expectation(description: "testLogin")

    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      // when
      
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        expectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testLoginAndLogout() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.arcValues == nil)
    XCTAssert(loginSession.request == nil)
    
    // given
    
    var presentingController = MockLoginUIViewController()
    let expectation = self.expectation(description: "testLoginWithCaching")

    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
    
        grabIdPartner.logout(loginSession: loginSession)
        presentingController = MockLoginUIViewController()
        
        // when: subsequence login will use cache and won't trigger web login flow
        grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
          
          // then: loaded from cache
          XCTAssertNil(error)
          XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
          expectation.fulfill()
        }
      }
    }
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testLoginWithoutLogout() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.arcValues == nil)
    XCTAssert(loginSession.request == nil)
    
    // given
    
    var presentingController = MockLoginUIViewController()
    let expectation = self.expectation(description: "testLoginWithCaching")
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        
        presentingController = MockLoginUIViewController()
        
        // when: subsequence login will use cache and won't trigger web login flow
        grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
          
          // then: loaded from cache
          XCTAssertNotNil(error)
          XCTAssertNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
          expectation.fulfill()
        }
      }
    }
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testExhangeToken() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")

    let presentingController = MockLoginUIViewController()
  
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in

      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")

        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        // when
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          XCTAssert(loginSession.idToken == "testIdToken")
          XCTAssert(loginSession.accessToken == "testAccessToken")
          XCTAssert(loginSession.refreshToken == "testRefreshToken")
          XCTAssert(loginSession.tokenType == "TestTokenType")
          XCTAssert(loginSession.accessTokenExpiresAt ?? Date() >= Date())

          // verify token is valid
          let isValid = grabIdPartner.isValidAccessToken(loginSession: loginSession)
          XCTAssertTrue(isValid)

          expectation.fulfill()
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }

  func testExhangeTokenWithInvalidState() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=invalidState") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        // when
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          
          // then
          XCTAssertNotNil(error)
          XCTAssert(error?.code == .securityValidationFailed)
          
          // verify token is valid
          let isValid = grabIdPartner.isValidAccessToken(loginSession: loginSession)
          XCTAssertFalse(isValid)
          
          expectation.fulfill()
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testExhangeTokenWithoutState() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        // when
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          
          // then
          XCTAssertNotNil(error)
          XCTAssert(error?.code == .securityValidationFailed)
   
          // verify token is valid
          let isValid = grabIdPartner.isValidAccessToken(loginSession: loginSession)
          XCTAssertFalse(isValid)

          expectation.fulfill()
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testExpiredExhangeToken() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    mockUrlSession.mockExchangeTokenResponseData.mockResponse = MockExchangeTokenResponseData.mockExpiredTokenResponse
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")

        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        // when
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          XCTAssert(loginSession.idToken == "testIdToken")
          XCTAssert(loginSession.accessToken == "testAccessToken")
          XCTAssert(loginSession.refreshToken == "testRefreshToken")
          XCTAssert(loginSession.tokenType == "TestTokenType")
          XCTAssert(loginSession.accessTokenExpiresAt ?? Date() <= Date())
          
          let isValid = grabIdPartner.isValidAccessToken(loginSession: loginSession)
          XCTAssertFalse(isValid)

          expectation.fulfill()
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testAccessTokenCache() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")

        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        // when
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          XCTAssert(loginSession.idToken == "testIdToken")
          XCTAssert(loginSession.accessToken == "testAccessToken")
          XCTAssert(loginSession.refreshToken == "testRefreshToken")
          XCTAssert(loginSession.tokenType == "TestTokenType")
          XCTAssert(loginSession.accessTokenExpiresAt ?? Date() >= Date())
          
          let presentingController = MockLoginUIViewController()

          // then: after token exchange, we will use the cache token
          grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
            XCTAssertNil(error)
            XCTAssertNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
            XCTAssert(loginSession.accessToken == "testAccessToken")
            expectation.fulfill()
          }
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testLoginServiceError() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    
    // set service error
    mockUrlSession.mockConfigurationServiceError = 400
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.arcValues == nil)
    XCTAssert(loginSession.request == nil)
    
    // given
    
    let presentingController = MockLoginUIViewController()
    let expectation = self.expectation(description: "testLogin")
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      // when
      
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNotNil(error)
        XCTAssertTrue(error?.code == .discoveryServiceFailed)
        expectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testExhangeTokenServiceError() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    
    // set service error
    mockUrlSession.mockExchangeTokenServiceError = 400
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        // when
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          XCTAssertNotNil(error)
          XCTAssertTrue(error?.code == .exchangeTokenServiceFailed)
          expectation.fulfill()
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testTokenInfoServiceError() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    
    // set service error
    mockUrlSession.mockTokenInfoServiceError = 400
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
   
          XCTAssertNil(error)
          
          grabIdPartner.getIdTokenInfo(loginSession: loginSession) { (tokenInfo, error) in
            XCTAssertNotNil(error)
            XCTAssertTrue(error?.code == .idTokenInfoServiceFailed)
            // verify id token is invalid
            if let tokenInfo = tokenInfo {
              let isValid = grabIdPartner.isValidIdToken(idTokenInfo: tokenInfo)
              XCTAssertFalse(isValid)
            }
            expectation.fulfill()
          }
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testTokenInfoMismatchNonce() {
    // given - 0581ada9-cdbb-4f16-9d43-ad50debdbc6a
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          
          XCTAssertNil(error)
          
          grabIdPartner.getIdTokenInfo(loginSession: loginSession) { (tokenInfo, error) in
            XCTAssertNotNil(error)
            XCTAssertTrue(error?.code == .invalidNonce)

            expectation.fulfill()
          }
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testTokenInfoCache() {
    // given - 0581ada9-cdbb-4f16-9d43-ad50debdbc6a
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        MockTokenInfoResponseData.nonce = loginSession.nonce ?? ""
        
        mockUrlSession.mockTokenInfoResponseData = MockTokenInfoResponseData()
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          
          XCTAssertNil(error)

          grabIdPartner.getIdTokenInfo(loginSession: loginSession) { (tokenInfo, error) in
            // result
            XCTAssert(tokenInfo?.service == "PASSENGER")
            XCTAssert(tokenInfo?.audience == "f795769ebe7446f38dede8fd36ee32fd")
            XCTAssert(tokenInfo?.issuer == "https://idp.grab.com")
            XCTAssert(tokenInfo?.tokenId == "WiP03b0DRYWZTsd1IYY66g")
            XCTAssert(tokenInfo?.partnerId == "59da6712-d131-4a2f-8e23-1a775fb4f5b7")
            XCTAssert(tokenInfo?.partnerUserId == "8206f105-a224-41ba-a514-92ef6b39ff31")

            // clear the mock response and verified getIdTokenInfo is returning data from cache.
            mockUrlSession.mockTokenInfoResponseData.mockResponse = ""
            
            grabIdPartner.getIdTokenInfo(loginSession: loginSession) { (tokenInfo, error) in
              XCTAssertNil(error)
              // result
              XCTAssert(tokenInfo?.service == "PASSENGER")
              XCTAssert(tokenInfo?.audience == "f795769ebe7446f38dede8fd36ee32fd")
              XCTAssert(tokenInfo?.issuer == "https://idp.grab.com")
              XCTAssert(tokenInfo?.tokenId == "WiP03b0DRYWZTsd1IYY66g")
              XCTAssert(tokenInfo?.partnerId == "59da6712-d131-4a2f-8e23-1a775fb4f5b7")
              XCTAssert(tokenInfo?.partnerUserId == "8206f105-a224-41ba-a514-92ef6b39ff31")

              expectation.fulfill()
            }
          }
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testLoginCompletedWithWebViewPresented() {
    // given
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    let presentingController = MockLoginUIViewController()
    let expectation = self.expectation(description: "testLogin")
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
      
        // when loginCompleted
        let success = grabIdPartner.loginCompleted(loginSession: loginSession)
      
        // then
        XCTAssertTrue(success)
      
        expectation.fulfill()
      }
    }
    
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testTokenInfo() {
    // given - 0581ada9-cdbb-4f16-9d43-ad50debdbc6a
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)

    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }

    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")

    let presentingController = MockLoginUIViewController()

    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        MockTokenInfoResponseData.nonce = loginSession.nonce ?? ""
        
        mockUrlSession.mockTokenInfoResponseData = MockTokenInfoResponseData()
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          
          XCTAssertNil(error)
          
          grabIdPartner.getIdTokenInfo(loginSession: loginSession) { (tokenInfo, error) in
            XCTAssertNil(error)
            
            if let tokenInfo = tokenInfo {
              let isValid = grabIdPartner.isValidIdToken(idTokenInfo: tokenInfo)
              XCTAssertTrue(isValid)
            } else {
              XCTAssert(false, "invalid tokenInfo")
            }
            
            grabIdPartner.logout(loginSession: loginSession)
            
            expectation.fulfill()
          }
        }
      }
    }

    // wait
    waitForExpectations(timeout: 2, handler: nil)
  }
  
  func testLogout() {
    // given - 0581ada9-cdbb-4f16-9d43-ad50debdbc6a
    let mockUrlSession = URLSessionMockSuccess(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        MockTokenInfoResponseData.nonce = loginSession.nonce ?? ""
        
        mockUrlSession.mockTokenInfoResponseData = MockTokenInfoResponseData()
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          
          XCTAssertNil(error)
          
          // then
          let saveLoginSession = loginSession
          grabIdPartner.logout(loginSession: loginSession) { (error) in
            let success = error == nil
            XCTAssertTrue(success)
            
            grabIdPartner.logout(loginSession: saveLoginSession) { (error) in
              let success = error == nil
              XCTAssertFalse(success)
              expectation.fulfill()
            }
          }
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 2, handler: nil)
  }
}
