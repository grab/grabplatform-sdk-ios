/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import XCTest
import GrabIdPartnerSDK
import SafariServices

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
    
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
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
      XCTAssert(loginSession.acrValues?.count ?? 0 == 2)
      XCTAssertTrue(loginSession.acrValues?["acrKey1"] == "acrValue1")
      XCTAssertTrue(loginSession.acrValues?["acrKey2"] == "acrValue2")
      XCTAssertTrue(loginSession.request == "test request")
      XCTAssertTrue(loginSession.hint == "test hint")

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

  func testCreateLoginSession() {
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    
    var (loginSession, error) = grabIdPartner.createLoginSession(clientId: "", redirectUrl: "testRedirectUrl", scope: "testScope", serviceDiscoveryUrl: "testDiscoveryUrl")
    XCTAssertNil(loginSession)
    XCTAssertEqual(error?.code, GrabIdPartnerErrorCode.invalidClientId)

    (loginSession, error) = grabIdPartner.createLoginSession(clientId: nil, redirectUrl: "", scope: "testScope", serviceDiscoveryUrl: "testDiscoveryUrl")
    XCTAssertNil(loginSession)
    XCTAssertEqual(error?.code, GrabIdPartnerErrorCode.invalidClientId)

    (loginSession, error) = grabIdPartner.createLoginSession(clientId: "testClientId", redirectUrl: "", scope: "testScope", serviceDiscoveryUrl: "testDiscoveryUrl")
    XCTAssertNil(loginSession)
    XCTAssertEqual(error?.code, GrabIdPartnerErrorCode.invalidRedirectUrl)

    (loginSession, error) = grabIdPartner.createLoginSession(clientId: "testClientId", redirectUrl: nil, scope: "testScope", serviceDiscoveryUrl: "testDiscoveryUrl")
    XCTAssertNil(loginSession)
    XCTAssertEqual(error?.code, GrabIdPartnerErrorCode.invalidRedirectUrl)

    (loginSession, error) = grabIdPartner.createLoginSession(clientId: "testClientId", redirectUrl: "testRedirectUrl", scope: "", serviceDiscoveryUrl: "testDiscoveryUrl")
    XCTAssertNil(loginSession)
    XCTAssertEqual(error?.code, GrabIdPartnerErrorCode.invalidScope)
    
    (loginSession, error) = grabIdPartner.createLoginSession(clientId: "testClientId", redirectUrl: "testRedirectUrl", scope: nil, serviceDiscoveryUrl: "testDiscoveryUrl")
    XCTAssertNil(loginSession)
    XCTAssertEqual(error?.code, GrabIdPartnerErrorCode.invalidScope)
  }
  
  func testLogin() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }

    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3",
                                    serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery",
                                    hint: "test hint", idTokenHint: "test idtokenhint", prompt: "test prompt")

    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.acrValues == nil)
    XCTAssert(loginSession.request == nil)
    XCTAssert(loginSession.hint == "test hint")
    XCTAssert(loginSession.idTokenHint == "test idtokenhint")
    XCTAssert(loginSession.prompt == "test prompt")

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
  
  func testChangingLoginSession() {
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }

    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3",
                                    serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery",
                                    hint: "test hint", idTokenHint: "test idtokenhint", prompt: "test prompt")

    loginSession.request = "testRequest"
    XCTAssertEqual(loginSession.request, "testRequest")
    loginSession.redirectUrl = testUrl
    XCTAssertEqual(loginSession.redirectUrl.absoluteString, "grabtest://testopen")
    loginSession.scope = "testScope"
    XCTAssertEqual(loginSession.scope, "testScope")
    loginSession.hint = "testHint"
    XCTAssertEqual(loginSession.hint, "testHint")
    loginSession.idTokenHint = "testIdTokenHint"
    XCTAssertEqual(loginSession.idTokenHint, "testIdTokenHint")
    loginSession.prompt = "testPrompt"
    XCTAssertEqual(loginSession.prompt, "testPrompt")
  }
  
  func testLoginAndLogout() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.acrValues == nil)
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
  
  func testLoginAndLogoutWithAppLink() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    mockUrlSession.testWithAppLink = true
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.acrValues == nil)
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
          XCTAssertNotNil(error)
          XCTAssertEqual(error?.code ?? GrabIdPartnerErrorCode.authorizationFailed, GrabIdPartnerErrorCode.failedTolaunchAppStoreLink)
          expectation.fulfill()
        }
      }
    }
    waitForExpectations(timeout: 1, handler: nil)
  }

  func testExchangeToken() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")

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

  func testExchangeTokenWithInvalidState() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
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
  
  func testExchangeTokenWithoutState() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
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
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
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
        
        mockUrlSession.mockResponseType = MockResponseType.expiredResponse
        
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
  
  func testLoginServiceError() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
    // result
    XCTAssert(loginSession.clientId == "TestClientId")
    XCTAssert(loginSession.redirectUrl.absoluteString == "grabtest://testopen")
    XCTAssert(loginSession.scope == "test_scope1 test_scope2 test_scope3")
    XCTAssert(loginSession.acrValues == nil)
    XCTAssert(loginSession.request == nil)
    
    // given
    
    let presentingController = MockLoginUIViewController()
    let expectation = self.expectation(description: "testLogin")
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
    // set service error
    mockUrlSession.serviceErrorDictionary[UrlSubstring.configuration.rawValue] = 400

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
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    
    // set service error
    mockUrlSession.serviceErrorDictionary[UrlSubstring.authorizationCode.rawValue] = 400

    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
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
  
  func testLoginWithValidAccessToken() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery", hint: "testHint")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        XCTAssertFalse(mockUrlSession.refreshTokenServiceCalled)

        
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
          XCTAssert(loginSession.hint == "testHint")
          XCTAssert(loginSession.accessTokenExpiresAt ?? Date() >= Date())
          
          // verify token is valid
          let isValid = grabIdPartner.isValidAccessToken(loginSession: loginSession)
          XCTAssertTrue(isValid)

          mockUrlSession.exchangeTokenServiceCalled = false
          mockUrlSession.refreshTokenServiceCalled = false

          presentingController.controllerPresented = nil
          
          // when: login after getting the access token and refresh token
          grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
            
            // then
            // verify in-app web authorization not shown and access token is refreshed
            XCTAssertNil(presentingController.controllerPresented)
            
            XCTAssertFalse(mockUrlSession.exchangeTokenServiceCalled)
            XCTAssert(loginSession.accessToken == "testAccessToken")
            XCTAssert(loginSession.refreshToken == "testRefreshToken")
            XCTAssert(loginSession.tokenType == "TestTokenType")
            XCTAssert(loginSession.hint == "testHint")
            XCTAssert(loginSession.accessTokenExpiresAt ?? Date() >= Date())
            
            // Now verify when app restart with new loginSession, calling login API with accessToken nil will use
            // cache access token
            let newLoginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery", hint: "testHint")
            grabIdPartner.login(loginSession: newLoginSession, presentingViewController:presentingController) { (error) in
              
              // then
              // verify in-app web authorization not shown and access token is refreshed
              XCTAssertNil(presentingController.controllerPresented)
              
              XCTAssertFalse(mockUrlSession.exchangeTokenServiceCalled)
              XCTAssert(newLoginSession.accessToken == "testAccessToken")
              XCTAssert(newLoginSession.refreshToken == "testRefreshToken")
              XCTAssert(newLoginSession.tokenType == "TestTokenType")
              XCTAssert(newLoginSession.accessTokenExpiresAt ?? Date() >= Date())
              expectation.fulfill()
            }
          }
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 1, handler: nil)
  }

  func testLoginWithExpiredAccessToken() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery", hint: "testHint")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        XCTAssertFalse(mockUrlSession.refreshTokenServiceCalled)
        
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        mockUrlSession.mockResponseType = MockResponseType.expiredResponse

        // when
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          // verified the access token has expired
          let isValid = grabIdPartner.isValidAccessToken(loginSession: loginSession)
          XCTAssertFalse(isValid)

          mockUrlSession.exchangeTokenServiceCalled = false
          mockUrlSession.refreshTokenServiceCalled = false
          
          presentingController.controllerPresented = nil
          
          // when: login after getting the access token and refresh token and refresh token failed
          mockUrlSession.serviceErrorDictionary[UrlSubstring.refreshToken.rawValue] = 400

          grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in

            // then
            // verify refresh token is called and in-app web authorization is shown
            XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")

            expectation.fulfill()
          }
        }
      }
    }
    
    // wait
    waitForExpectations(timeout: 90, handler: nil)
  }
  
  func testTokenInfoServiceError() {
    // given
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    
    // set service error
    mockUrlSession.serviceErrorDictionary[UrlSubstring.tokenInfo.rawValue] = 400

    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
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
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
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
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
    
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        mockUrlSession.nonce = loginSession.nonce ?? ""
        
        guard let redirectUrl = URL(string:"grabtest://testopen?code=12345&state=\(loginSession.state ?? "")") else {
          XCTAssert(false, "invalid redirect url")
          return
        }
        
        grabIdPartner.exchangeToken(loginSession: loginSession, url: redirectUrl) { error in
          
          XCTAssertNil(error)

          grabIdPartner.getIdTokenInfo(loginSession: loginSession) { (tokenInfo, error) in
            // result
            XCTAssert(tokenInfo?.service == "PASSENGER")
            XCTAssert(tokenInfo?.audience == "350c848f-2580-45ba-8879-69d51d54f2d3")
            XCTAssert(tokenInfo?.issuer == "https://testissuer.grab.com")
            XCTAssert(tokenInfo?.tokenId == "TESTRYWZTsd1IYY66g")
            XCTAssert(tokenInfo?.partnerId == "a4ec3215-d34b-457b-aa8e-46577358643c")
            XCTAssert(tokenInfo?.partnerUserId == "41c0893d-245e-438b-b971-625badbe7dc4")
            
            grabIdPartner.getIdTokenInfo(loginSession: loginSession) { (tokenInfo, error) in
              XCTAssertNil(error)
              // result
              XCTAssert(tokenInfo?.service == "PASSENGER")
              XCTAssert(tokenInfo?.audience == "350c848f-2580-45ba-8879-69d51d54f2d3")
              XCTAssert(tokenInfo?.issuer == "https://testissuer.grab.com")
              XCTAssert(tokenInfo?.tokenId == "TESTRYWZTsd1IYY66g")
              XCTAssert(tokenInfo?.partnerId == "a4ec3215-d34b-457b-aa8e-46577358643c")
              XCTAssert(tokenInfo?.partnerUserId == "41c0893d-245e-438b-b971-625badbe7dc4")

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
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
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
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)

    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }

    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")

    let presentingController = MockLoginUIViewController()

    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        mockUrlSession.nonce = loginSession.nonce ?? ""
        
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
    waitForExpectations(timeout: 90, handler: nil)
  }
  
  func testLogout() {
    // given - 0581ada9-cdbb-4f16-9d43-ad50debdbc6a
    let mockUrlSession = MockURLSession(data:nil, response:nil, error:nil)
    
    let grabIdPartner = GrabIdPartner(urlSession: mockUrlSession, bundle: Bundle(for: GrabIdPartnerSDKTests.self))
    let url = URL(string: "grabtest://testopen")
    let expectation = self.expectation(description: "testExchangeToken")
    guard let testUrl = url else {
      XCTAssert(false, "invalid url")
      return
    }
    
    let loginSession = LoginSession(clientId: "TestClientId", redirectUrl: testUrl, scope: "test_scope1 test_scope2 test_scope3", serviceDiscoveryUrl: "http://testdiscoveryendpoint.com/testservicediscovery")
    
    let presentingController = MockLoginUIViewController()
    
    // clean up any previous login session
    grabIdPartner.logout(loginSession: loginSession) { _ in
      
      grabIdPartner.login(loginSession: loginSession, presentingViewController:presentingController) { (error) in
        XCTAssertNil(error)
        XCTAssertNotNil(presentingController.controllerPresented as? SFSafariViewController, "expected SFSafariViewController")
        
        mockUrlSession.nonce = loginSession.nonce ?? ""
        
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
    waitForExpectations(timeout: 1, handler: nil)
  }
  
  func testPartnerSDKErrorDomains() {
    GrabIdPartnerErrorDomain.allCases.forEach { domain in
      let error = GrabIdPartnerError(code: GrabIdPartnerErrorCode.invalidUrl , domain: domain)
      XCTAssertEqual(error.domain, domain)
    }
  }

  func testPartnerSDKErrorCodes() {
    GrabIdPartnerErrorCode.allCases.forEach { code in
      let error = GrabIdPartnerError(code: code, domain: GrabIdPartnerErrorDomain.authorization)
      XCTAssertEqual(error.code, code)
    }
  }

  func testPartnerSDKLocalizationErrors() {
    GrabIdPartnerLocalization.allCases.forEach { localizationError in
      let error = GrabIdPartnerError(code: GrabIdPartnerErrorCode.authorizationFailed,
                                     localizeMessage: localizationError.rawValue, domain: GrabIdPartnerErrorDomain.authorization)
      XCTAssertEqual(error.localizeMessage, localizationError.rawValue)
    }
  }

  func testPartnerSDKInitLocalizationErrors() {
    GrabIdPartnerLocalization.allCases.forEach { localizationError in
      let locError = GrabIdPartnerLocalization(rawValue: localizationError.rawValue)
      let error = GrabIdPartnerError(code: GrabIdPartnerErrorCode.authorizationFailed,
                                     localizeMessage: locError?.rawValue ?? "", domain: GrabIdPartnerErrorDomain.authorization)
      XCTAssertEqual(error.localizeMessage, locError?.rawValue)
    }

    let unknownError = GrabIdPartnerLocalization(rawValue: "test unknown error")
    let error = GrabIdPartnerError(code: GrabIdPartnerErrorCode.authorizationFailed,
                                   localizeMessage: unknownError?.rawValue ?? "", domain: GrabIdPartnerErrorDomain.authorization)
    XCTAssertEqual(error.localizeMessage, unknownError?.rawValue)
  }
}
