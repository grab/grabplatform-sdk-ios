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

- (void)presentViewController:(UIViewController *_Nullable)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion ;
@property(nonatomic,retain) UIViewController * _Nullable controllerPresented;
@end

@protocol MockResponseDataProtocol
@property(nonatomic,retain) NSString * _Nonnull mockResponse;
- init:(NSString *_Nullable) mockResponse;
@end

@interface MockExchangeTokenResponseData : NSObject<MockResponseDataProtocol>
@property(nonatomic,retain) NSString * _Nullable mockResponse;
- init:(NSString *_Nullable) mockResponse;
@end

@interface MockConfigurationResponseData : NSObject<MockResponseDataProtocol>
@property(nonatomic,retain) NSString * _Nullable mockResponse;
- init:(NSString *_Nullable) mockResponse;
@end

@interface MockTokenInfoResponseData : NSObject<MockResponseDataProtocol>
@property(nonatomic,retain) NSString * _Nullable mockResponse;
@property(nonatomic,retain) NSString * _Nullable nonce;

- init:(NSString *_Nullable) mockResponse;
@end

// MockURLSessionDataTask
@interface MockURLSessionDataTask : NSURLSessionDataTask

typedef void(^CompletionHandler)(NSData *_Nullable, NSURLResponse *_Nullable, NSError *_Nullable);

@property (nonatomic, copy) CompletionHandler _Nullable completion;
@property(nonatomic,retain) NSURLResponse * _Nullable mockResponse;
@property(nonatomic,retain) NSError * _Nullable mockError;
@property(nonatomic,retain) NSData * _Nullable mockData;

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

@property(nonatomic,retain) NSURLResponse * _Nullable mockResponse;
@property(nonatomic,retain) MockURLSessionDataTask * _Nullable mockDataTask;
@property (nonatomic, retain) NSMutableDictionary * _Nullable serviceErrorDictionary;

@property(nonatomic,assign) NSString * _Nullable nonce;

@property (nonatomic, assign) UrlType urlType;
@property (nonatomic, assign) MockResponseType responseType;
@end


