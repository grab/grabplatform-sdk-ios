/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

#import <XCTest/XCTest.h>
@import SafariServices;
@import GrabIdPartnerSDK;
@import Pods_GrabIdPartnerSDK_Tests;
#import <GrabIdPartnerSDK/GrabIdPartnerSDK-Swift.h>
#import "TestMockHelper.h"

// Tests to show how to call the GrabId Partner SDK with Objective-C. There are unit tests to cover the SDK APIs. The purpose of
// the tests here is just to validate Objective-C calling Swift Grab Partner Id SDK API.

@interface GrabIdPartnerSDK_Objc_Tests : XCTestCase

-(void) testLoadLoginSession;

@end

@implementation GrabIdPartnerSDK_Objc_Tests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

-(void) testGrabIdPartnerSharedInstance
{
  id<GrabIdPartnerProtocol> grabIdPartner = [GrabIdPartner sharedInstance];
  XCTAssertNotNil(grabIdPartner);
}

-(void) testLoadLoginSession
{
  NSBundle *bundle = [NSBundle bundleForClass:[GrabIdPartnerSDK_Objc_Tests class]];
 // MockURLSession *urlSession = [[MockURLSession alloc] init];
  
  id<GrabIdPartnerProtocol> grabIdPartner = [[GrabIdPartner alloc] initWithBundle:bundle];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testLoadLoginSession"];

  [grabIdPartner loadLoginSessionWithCompletion: ^(LoginSession * _Nullable loginSession, GrabIdPartnerError * _Nullable error) {
    if (loginSession == nil) {
      // failed to load session
    }
    
    if (error != nil) {
      // failed with error
      NSLog(@"loadLoginSession failed with error code %ld, message %@", (long)error.code, error.localizeMessage);
    }

    XCTAssertTrue([loginSession.clientId isEqualToString: @"TestClientId"]);
    XCTAssertTrue([loginSession.redirectUrl.absoluteString isEqualToString:@"grabtest://testopen"]);
    XCTAssertTrue([loginSession.scope isEqualToString:@"test_scope1 test_scope2 test_scope3"]);
    XCTAssertTrue([loginSession.redirectUrl.absoluteString isEqualToString:@"grabtest://testopen"]);
    XCTAssertNotNil(loginSession.acrValues);
    XCTAssertTrue([loginSession.acrValues[@"acrKey1"] isEqualToString:@"acrValue1"]);
    XCTAssertTrue([loginSession.acrValues[@"acrKey2"] isEqualToString:@"acrValue2"]);
    XCTAssertNotNil(loginSession.request);
    XCTAssertTrue([loginSession.request isEqualToString:@"test request"]);
    XCTAssertTrue([loginSession.request isEqualToString:@"test request"]);
    [expectation fulfill];
  }];
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

-(void) testCreateLoginSessionStaging
{
  LoginSession *loginSession = [[LoginSession alloc] initWithClientId:@"TestClientId"
                                                          redirectUrl:[[NSURL alloc] initWithString:@"grabtest://testopen"]
                                                         scope:@"test_scope1 test_scope2 test_scope3"
                                                      request:@"test request" acrValues: @{ @"acrKey1": @"acrValue1",
                                                                                            @"acrKey2": @"acrValue2" }
                                                  serviceDiscoveryUrl:@"http://testdiscoveryendpoint.com/testservicediscovery"
                                                         hint: @""];
  XCTAssertTrue([loginSession.clientId isEqualToString: @"TestClientId"]);
  XCTAssertTrue([loginSession.redirectUrl.absoluteString isEqualToString:@"grabtest://testopen"]);
  XCTAssertTrue([loginSession.scope isEqualToString:@"test_scope1 test_scope2 test_scope3"]);
  XCTAssertTrue([loginSession.redirectUrl.absoluteString isEqualToString:@"grabtest://testopen"]);
  XCTAssertNotNil(loginSession.acrValues);
  XCTAssertTrue([loginSession.acrValues[@"acrKey1"] isEqualToString:@"acrValue1"]);
  XCTAssertTrue([loginSession.acrValues[@"acrKey2"] isEqualToString:@"acrValue2"]);
  XCTAssertTrue([loginSession.serviceDiscoveryUrl isEqualToString:@"http://testdiscoveryendpoint.com/testservicediscovery"]);
  XCTAssertNotNil(loginSession.request);
  XCTAssertTrue([loginSession.request isEqualToString:@"test request"]);
}

-(void) testLogin
{
  NSBundle *bundle = [NSBundle bundleForClass:[GrabIdPartnerSDK_Objc_Tests class]];

  LoginSession *loginSession = [[LoginSession alloc] initWithClientId:@"TestClientId"
                                                           redirectUrl:[[NSURL alloc] initWithString:@"grabtest://testopen"]
                                                                 scope:@"test_scope1 test_scope2 test_scope3"
                                                               request:@"test request" acrValues: @{ @"acrKey1": @"acrValue1",
                                                                                                     @"acrKey2": @"acrValue2" }
                                                   serviceDiscoveryUrl:@"http://testdiscoveryendpoint.com/testservicediscovery"
                                                          hint: @""];

  MockURLSession *urlSession = [[MockURLSession alloc] init];
  
  id<GrabIdPartnerProtocol> grabIdPartner = [[GrabIdPartner alloc] initWithUrlSession:urlSession bundle:bundle];
  XCTAssertNotNil(grabIdPartner);
  
  MockLoginUIViewController *presentingController = [[MockLoginUIViewController alloc] init];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testLoadLoginSession"];

  [grabIdPartner logoutWithLoginSession:loginSession completion:^(GrabIdPartnerError * _Nullable error) {

    [grabIdPartner loginWithLoginSession:loginSession presentingViewController:presentingController completion:^(GrabIdPartnerError * _Nullable error) {
      XCTAssertNil(error);
      NSString *className = NSStringFromClass([presentingController.controllerPresented class]);
      XCTAssertTrue([className isEqualToString: @"SFSafariViewController"]);
      [expectation fulfill];
    }];
  }];
  
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

-(void) testExchangeToken
{
  NSBundle *bundle = [NSBundle bundleForClass:[GrabIdPartnerSDK_Objc_Tests class]];
  
  LoginSession *loginSession = [[LoginSession alloc] initWithClientId:@"TestClientId"
                                                          redirectUrl:[[NSURL alloc] initWithString:@"grabtest://testopen"]
                                                                scope:@"test_scope1 test_scope2 test_scope3"
                                                              request:@"test request" acrValues: @{ @"acrKey1": @"acrValue1",
                                                                                                    @"acrKey2": @"acrValue2" }
                                                  serviceDiscoveryUrl:@"http://testdiscoveryendpoint.com/testservicediscovery"
                                                         hint: @""];


  MockURLSession *urlSession = [[MockURLSession alloc] init];
  
  id<GrabIdPartnerProtocol> grabIdPartner = [[GrabIdPartner alloc] initWithUrlSession:urlSession bundle:bundle];
  XCTAssertNotNil(grabIdPartner);
  
  MockLoginUIViewController *presentingController = [[MockLoginUIViewController alloc] init];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testLoadLoginSession"];
  
  [grabIdPartner logoutWithLoginSession:loginSession completion:^(GrabIdPartnerError * _Nullable error) {
    
    [grabIdPartner loginWithLoginSession:loginSession presentingViewController:presentingController completion:^(GrabIdPartnerError * _Nullable error) {
      XCTAssertNil(error);
      NSString *className = NSStringFromClass([presentingController.controllerPresented class]);
      XCTAssertTrue([className isEqualToString: @"SFSafariViewController"]);
      
      NSString *urlString = [NSString stringWithFormat:@"grabtest://testopen?code=12345&state=%@", loginSession.state == nil ? @"" : loginSession.state];
      NSURL *redirectUrl = [[NSURL alloc] initWithString:urlString];
      
      [grabIdPartner exchangeTokenWithLoginSession:loginSession url:redirectUrl completion:^(GrabIdPartnerError * _Nullable error) {
        XCTAssertTrue([loginSession.idToken isEqualToString:@"testIdToken"]);
        XCTAssertTrue([loginSession.accessToken isEqualToString:@"testAccessToken"]);
        XCTAssertTrue([loginSession.refreshToken isEqualToString:@"testRefreshToken"]);
        XCTAssertTrue([loginSession.tokenType isEqualToString:@"TestTokenType"]);
        XCTAssertTrue([loginSession.serviceDiscoveryUrl containsString:@"http://testdiscoveryendpoint.com/testservicediscovery"]);
        BOOL isValidAccessToken = [grabIdPartner isValidAccessTokenWithLoginSession:loginSession];
        XCTAssertTrue(isValidAccessToken);
        NSDate * now = [NSDate date];
        NSComparisonResult result = [now compare:loginSession.accessTokenExpiresAt];
        XCTAssertTrue(result == NSOrderedAscending);
        [expectation fulfill];
      }];
    }];
  }];
  
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

-(void) testTokenInfo
{
  NSBundle *bundle = [NSBundle bundleForClass:[GrabIdPartnerSDK_Objc_Tests class]];
  
  LoginSession *loginSession = [[LoginSession alloc] initWithClientId:@"TestClientId"
                                                          redirectUrl:[[NSURL alloc] initWithString:@"grabtest://testopen"]
                                                                scope:@"test_scope1 test_scope2 test_scope3"
                                                              request:@"test request" acrValues: @{ @"acrKey1": @"acrValue1",
                                                                                                    @"acrKey2": @"acrValue2" }
                                                  serviceDiscoveryUrl:@"http://testdiscoveryendpoint.com/testservicediscovery"
                                                         hint:@""];

  
  MockURLSession *urlSession = [[MockURLSession alloc] init];
  
  id<GrabIdPartnerProtocol> grabIdPartner = [[GrabIdPartner alloc] initWithUrlSession:urlSession bundle:bundle];
  XCTAssertNotNil(grabIdPartner);
  
  MockLoginUIViewController *presentingController = [[MockLoginUIViewController alloc] init];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testLoadLoginSession"];
  
  [grabIdPartner logoutWithLoginSession:loginSession completion:^(GrabIdPartnerError * _Nullable error) {
    
    [grabIdPartner loginWithLoginSession:loginSession presentingViewController:presentingController completion:^(GrabIdPartnerError * _Nullable error) {
      XCTAssertNil(error);
      NSString *className = NSStringFromClass([presentingController.controllerPresented class]);
      XCTAssertTrue([className isEqualToString: @"SFSafariViewController"]);
      
      NSString *urlString = [NSString stringWithFormat:@"grabtest://testopen?code=12345&state=%@", loginSession.state == nil ? @"" : loginSession.state];
      NSURL *redirectUrl = [[NSURL alloc] initWithString:urlString];
      
      // set up the nonce in the mock response to match the loginSession nonce. otherwise it will failed with invalidnonce
      urlSession.nonce = loginSession.nonce;
      
      [grabIdPartner exchangeTokenWithLoginSession:loginSession url:redirectUrl completion:^(GrabIdPartnerError * _Nullable error) {
        // verified the login completed successfully and web browser is closed after login
        // completed
        BOOL loginCompletedSuccess = [grabIdPartner loginCompletedWithLoginSession:loginSession];
        XCTAssertTrue(loginCompletedSuccess);
        
        [grabIdPartner getIdTokenInfoWithLoginSession:loginSession completion:^(IdTokenInfo * _Nullable tokenInfo, GrabIdPartnerError * _Nullable error) {
          XCTAssertNil(error);
          XCTAssertNotNil(tokenInfo);
          
          if (tokenInfo != nil) {
            BOOL isValid = [grabIdPartner isValidIdTokenWithIdTokenInfo:tokenInfo];
            XCTAssertTrue(isValid);
          }

          XCTAssertTrue([tokenInfo.audience isEqualToString:@"350c848f-2580-45ba-8879-69d51d54f2d3"]);
          XCTAssertTrue([tokenInfo.service isEqualToString:@"PASSENGER"]);
          XCTAssertTrue([tokenInfo.nonce isEqualToString:loginSession.nonce]);
          XCTAssertTrue([tokenInfo.partnerUserId isEqualToString:@"41c0893d-245e-438b-b971-625badbe7dc4"]);
          XCTAssertTrue([tokenInfo.partnerId isEqualToString:@"a4ec3215-d34b-457b-aa8e-46577358643c"]);
          XCTAssertTrue([tokenInfo.tokenId isEqualToString:@"TESTRYWZTsd1IYY66g"]);
          XCTAssertTrue([tokenInfo.issuer isEqualToString:@"https://testissuer.grab.com"]);
          
          NSString *epoachTime = @"1541112042";
          NSTimeInterval seconds = [epoachTime doubleValue];
          NSDate *issueDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
          XCTAssertTrue([tokenInfo.issueDate isEqualToDate:issueDate]);
          
          epoachTime = @"1541112042";
          seconds = [epoachTime doubleValue];
          NSDate *notValidBeforeDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
          XCTAssertTrue([tokenInfo.notValidBefore isEqualToDate:notValidBeforeDate]);

          epoachTime = @"2541371242";
          seconds = [epoachTime doubleValue];
          NSDate *expirationDate = [[NSDate alloc] initWithTimeIntervalSince1970:seconds];
          XCTAssertTrue([tokenInfo.expiration isEqualToDate:expirationDate]);

          [grabIdPartner logoutWithLoginSession:loginSession completion:^(GrabIdPartnerError * _Nullable error) {
            [expectation fulfill];
          }];
        }];
      }];
    }];
  }];
  
  [self waitForExpectationsWithTimeout:1.0 handler:nil];
}

-(void) testGetTokenInfoWithInvalidNonce
{
  NSBundle *bundle = [NSBundle bundleForClass:[GrabIdPartnerSDK_Objc_Tests class]];
  
  LoginSession *loginSession = [[LoginSession alloc] initWithClientId:@"TestClientId"
                                                          redirectUrl:[[NSURL alloc] initWithString:@"grabtest://testopen"]
                                                                scope:@"test_scope1 test_scope2 test_scope3"
                                                              request:@"test request" acrValues: @{ @"acrKey1": @"acrValue1",
                                                                                                    @"acrKey2": @"acrValue2" }
                                                  serviceDiscoveryUrl:@"http://testdiscoveryendpoint.com/testservicediscovery"
                                                         hint:@""];
  
  MockURLSession *urlSession = [[MockURLSession alloc] init];
  
  id<GrabIdPartnerProtocol> grabIdPartner = [[GrabIdPartner alloc] initWithUrlSession:urlSession bundle:bundle];
  XCTAssertNotNil(grabIdPartner);
  
  MockLoginUIViewController *presentingController = [[MockLoginUIViewController alloc] init];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"testLoadLoginSession"];

  [grabIdPartner logoutWithLoginSession:loginSession completion:^(GrabIdPartnerError * _Nullable error) {

    [grabIdPartner loginWithLoginSession:loginSession presentingViewController:presentingController completion:^(GrabIdPartnerError * _Nullable error) {
      XCTAssertNil(error);
      NSString *className = NSStringFromClass([presentingController.controllerPresented class]);
      NSLog(@"%@", className);
      XCTAssertTrue([className isEqualToString: @"SFSafariViewController"]);


      NSString *urlString = [NSString stringWithFormat:@"grabtest://testopen?code=12345&state=%@", loginSession.state == nil ? @"" : loginSession.state];
      NSURL *redirectUrl = [[NSURL alloc] initWithString:urlString];
      
      [grabIdPartner exchangeTokenWithLoginSession:loginSession url:redirectUrl completion:^(GrabIdPartnerError * _Nullable error) {
        [grabIdPartner getIdTokenInfoWithLoginSession:loginSession completion:^(IdTokenInfo * _Nullable tokenInfo, GrabIdPartnerError * _Nullable error) {
          XCTAssertNotNil(error);
          
          // access error code and domain from "GrabIdPartnerSDK-Swift.h"
          XCTAssertTrue(error.code == GrabIdPartnerErrorCodeInvalidNonce);
          XCTAssertTrue(error.domain == GrabIdPartnerErrorDomainGetIdTokenInfo);
          // verified the login completed successfully and web browser is closed after login
          // completed
          BOOL loginCompletedSuccess = [grabIdPartner loginCompletedWithLoginSession:loginSession];
          XCTAssertTrue(loginCompletedSuccess);
          
          [grabIdPartner logoutWithLoginSession:loginSession completion:^(GrabIdPartnerError * _Nullable error) {
            [expectation fulfill];
          }];
        }];
      }];
    }];
  }];
  
  [self waitForExpectationsWithTimeout:90.0 handler:nil];
}
@end
