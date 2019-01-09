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
#import "GrabIdPartnerSDK-Swift.h"
#import "TestMockHelper.h"

// Helpers to provide mock responses to run unit tests - implementation

@implementation MockLoginUIViewController
@synthesize controllerPresented;

- (void)presentViewController:(UIViewController *)viewControllerToPresent animated: (BOOL)flag completion:(void (^ __nullable)(void))completion {
  controllerPresented = viewControllerToPresent;
  if (completion != nil) {
    completion();
  }
}
@end

@implementation MockExchangeTokenResponseData
@synthesize mockResponse;

- (id)init:(NSString *)mockResponse {
  self = [super init];
  if (self) {
    self.mockResponse = mockResponse;
  }
  return self;
}

- (id)init {
  self = [super init];
  if (self) {
    self.mockResponse = @"";
  }
  return self;
}

-(void)dealloc {
  self.mockResponse = nil;
}
@end

// MockURLSessionDataTask
@implementation MockURLSessionDataTask
@synthesize mockResponse;
@synthesize mockData;
@synthesize mockError;
@synthesize completion;

-(id)init:(NSData *)data mockResponse:(NSURLResponse *)mockResponse error:(NSError *) error completion:(CompletionHandler) handler {
  self = [super init];
  if (self) {
    self.mockResponse = mockResponse;
    self.mockData = data;
    self.mockError = error;
    self.completion = handler;
  }
  return self;
}

- (void)resume {
  completion(mockData, mockResponse,mockError);
}

- (void)dealloc {
  self.mockResponse = nil;
  self.mockError = nil;
  self.mockData = nil;
}
@end

// MockURLSession
@implementation MockURLSession

typedef void(^CompletionHandler)(NSData *, NSURLResponse *, NSError *);

@synthesize mockDataTask;
@synthesize urlType;
@synthesize responseType;
@synthesize nonce;
@synthesize serviceErrorDictionary;
@synthesize mockResponse;

NSString *expectedConfigurationEndPoint = @"";

- (id)init {
  self = [super init];
  if (self) {
    expectedConfigurationEndPoint = [self readGrabIdPartnerSDKSettingFromPlist:@"ServiceDiscoveryUrl"];

    self.nonce = @"";
  }
  return self;
}

-(NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(CompletionHandler)completionHandler {
  if (request == nil) {
    return self.mockDataTask;
  };
  
  NSString *urlString = [[request URL] absoluteString];
  if (urlString.length == 0) {
    return self.mockDataTask;
  }
  
  int httpStatusCode = 400;
  
  NSData *mockData;
  NSString *mockResponseString;
  
  if ([urlString containsString:expectedConfigurationEndPoint]) {
    UrlType config = configuration;
    NSString *configKey = [self urlKeyNameInPlist:config];
    if (configKey == nil) {
      return self.mockDataTask;
    }
    

    NSDictionary<NSString *,id> *mockConfigResponses = [self readMockDataFromPlist:configKey];
    if (mockConfigResponses == nil) {
      return self.mockDataTask;
    }
    
    // check to see what http status code to return for config request, default to 200
    httpStatusCode = [self getMockHttpStatusCode:config];
    
    if (httpStatusCode == 200) {
      NSString *validResponseKey = [self mockResponseTypeString:validResponse];
      mockResponseString = (NSString *)mockConfigResponses[validResponseKey];
    } else {
      mockResponseString = (NSString *)mockConfigResponses[@""];
    }
  } else {
    NSDictionary *mockResponsesDict = [self getMockResponsesDictionary];
    if (mockResponsesDict != nil) {
      for(id key in mockResponsesDict) {
        if ([urlString containsString:key]) {
          NSDictionary *mockResponses = [mockResponsesDict objectForKey:key];
          id httpStatusForKey = serviceErrorDictionary[key];
          httpStatusCode = (httpStatusForKey == nil) ? 200 : (int)httpStatusForKey;
          if (mockResponses != nil && httpStatusCode == 200) {
            NSString *validResponseKey = [self mockResponseTypeString:validResponse];
            mockResponseString = (NSString *)mockResponses[validResponseKey];
            if (mockResponseString != nil) {
              NSData *data = [mockResponseString dataUsingEncoding:NSUTF8StringEncoding];
              NSMutableDictionary *jsonDict = [[NSJSONSerialization JSONObjectWithData:data options:0 error:nil] mutableCopy];
              if (jsonDict != nil) {
                if (jsonDict[@"nonce"] != nil) {
                  jsonDict[@"nonce"] = nonce;
                  NSError *error;
                  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                                     options:0
                                                                       error:&error];
                  
                  if (jsonData != nil) {
                    mockResponseString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                  }
                }                
              }
            }
          } else {
            NSString *errorResponseKey = [self mockResponseTypeString:errorResponse];
            mockResponseString = (NSString *)mockResponses[errorResponseKey];
          }
          break;
        }
      }
    }
  }
  
  if (mockResponseString == nil) {
    mockResponseString = @"";
  }

  mockData = [mockResponseString dataUsingEncoding:NSUTF8StringEncoding];
  mockResponse = [[NSHTTPURLResponse alloc] initWithURL:[request URL] statusCode:httpStatusCode HTTPVersion:nil headerFields:nil];
  completionHandler(mockData, mockResponse, nil);

  mockDataTask.mockResponse = mockResponse;
  mockDataTask.mockData = mockData;
  mockDataTask.mockError = nil;
  return self.mockDataTask;
}

- (void)dealloc {
  self.mockDataTask = nil;
  self.nonce = nil;
  self.serviceErrorDictionary = nil;
}

// Helper functions to get mock responses from the test bundle's info.plist
-(NSDictionary<NSString *,id> *)readMockDataFromPlist:(NSString *)key {
  NSDictionary *mockResponsesDict = [self getMockResponsesDictionary];
  if (mockResponsesDict == nil) {
    return nil;
  }
  return [mockResponsesDict objectForKey:key];
}

-(NSDictionary *)getMockResponsesDictionary {
  NSDictionary *infoDict = [[NSBundle bundleForClass:[self class]] infoDictionary];
  if (infoDict == nil) {
    return nil;
  }
  return [infoDict objectForKey: @"MockJSONResponses"];
}

-(NSString *)readGrabIdPartnerSDKSettingFromPlist:(NSString *)key {
  NSDictionary *infoDict = [[NSBundle bundleForClass:[self class]] infoDictionary];
  if (infoDict == nil) {
    return nil;
  }
  NSDictionary *configs = [infoDict objectForKey: @"GrabIdPartnerSDK"];
  return [configs objectForKey:key];
}

- (NSDictionary *)urlKeyNameInPlist
{
  return @{@(authorizationCode) : @"authorization_code",
           @(refreshToken) : @"refresh_token",
           @(tokenInfo) : @"token_info?",
           @(configuration) : @"configuration"};
}

- (NSString *)urlKeyNameInPlist:(UrlType)type
{
  return [self urlKeyNameInPlist][@(type)];
}

- (NSDictionary *)mockResponseTypeString
{
  return @{@(validResponse) : @"ValidResponse",
           @(expiredResponse) : @"ExpiredResponse",
           @(tokenInfo) : @"token_info?",
           @(configuration) : @"configuration"};
}

- (NSString *)mockResponseTypeString:(MockResponseType)type
{
  return [self mockResponseTypeString][@(type)];
}

- (int)getMockHttpStatusCode:(UrlType)type {
  NSString *urlKey = [self urlKeyNameInPlist:type];
  int statusCode = 0;
  
  if (urlKey != nil) {
    NSObject *object = serviceErrorDictionary[urlKey];

    if (object != [NSNull null]) {
      statusCode =(int)object;
    }
  }
  
  return statusCode == 0 ? 200 : statusCode;
}
@end
