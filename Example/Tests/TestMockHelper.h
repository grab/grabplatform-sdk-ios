/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

// Helpers to provide mock responses to run unit tests.

@interface MockLoginUIViewController : UIViewController

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion ;
@property(nonatomic,retain) UIViewController *controllerPresented;
@end

@protocol MockResponseDataProtocol
@property(nonatomic,retain) NSString *mockResponse;
- init:(NSString *) mockResponse;
@end

@interface MockExchangeTokenResponseData : NSObject<MockResponseDataProtocol>
@property(nonatomic,retain) NSString *mockResponse;
- init:(NSString *) mockResponse;
@end

@interface MockConfigurationResponseData : NSObject<MockResponseDataProtocol>
@property(nonatomic,retain) NSString *mockResponse;
- init:(NSString *) mockResponse;
@end

@interface MockTokenInfoResponseData : NSObject<MockResponseDataProtocol>
@property(nonatomic,retain) NSString *mockResponse;
@property(nonatomic,retain) NSString *nonce;

- init:(NSString *) mockResponse;
@end

// MockURLSessionDataTask
@interface MockURLSessionDataTask : NSURLSessionDataTask

typedef void(^CompletionHandler)(NSData *, NSURLResponse *, NSError *);

@property (nonatomic, copy) CompletionHandler completion;
@property(nonatomic,retain) NSURLResponse *mockResponse;
@property(nonatomic,retain) NSError *mockError;
@property(nonatomic,retain) NSData *mockData;

- (void)resume;
@end

// MockURLSession
@interface MockURLSession : NSURLSession
typedef NS_ENUM(NSUInteger, UrlType) {
  authorizationCode = 0,
  refreshToken = 1,
  tokenInfo = 2,
  configuration = NSUIntegerMax
};

typedef NS_ENUM(NSUInteger, MockResponseType) {
  validResponse = 0,
  expiredResponse = 1,
  errorResponse = 2
};

@property(nonatomic,retain) NSURLResponse *mockResponse;
@property(nonatomic,retain) MockURLSessionDataTask *mockDataTask;
@property (nonatomic, retain) NSMutableDictionary *serviceErrorDictionary;

@property(nonatomic,assign) NSString *nonce;

@property (nonatomic, assign) UrlType urlType;
@property (nonatomic, assign) MockResponseType responseType;
@end


