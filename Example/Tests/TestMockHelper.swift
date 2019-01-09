/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import Foundation
import GrabIdPartnerSDK
import SafariServices

// dictionary key in info.plist that contains the mock valid and error reponses.
internal enum UrlSubstring : String {
  case authorizationCode = "authorization_code"
  case refreshToken = "refresh_token"
  case tokenInfo = "token_info?"
  case configuration = "configuration"
}

// Mock response to use in the plist
public enum MockResponseType : String {
  case validResponse = "ValidResponse"
  case expiredResponse = "ExpiredResponse"
  case errorResponse = "ErrorResponse"
}

@objc public final class MockLoginUIViewController: UIViewController {
  @objc public var controllerPresented : UIViewController? = nil
  
  @objc override public func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
    controllerPresented = viewControllerToPresent
  }
}

@objc public final class MockURLSession : URLSession {
  var refreshTokenServiceCalled = false
  var exchangeTokenServiceCalled = false
  
  public var nonce : String = ""
  public var mockResponseType = MockResponseType.validResponse
  
  private var serviceConfigurationEndPoint : String = ""
  public var serviceErrorDictionary : [String:Int] = [:]
  
  var url: NSURL?
  var request: NSURLRequest?
  
  var resultConfigurationEndPoint : String? = nil
  var resultExchangeTokenUrl : String? = nil
  var resultTokenInfoUrl : String? = nil
  
  private let dataTaskMock: URLSessionDataTaskMock
  
  @objc public init(data: NSData?, response: URLResponse?, error: NSError?) {
    dataTaskMock = URLSessionDataTaskMock()
    dataTaskMock.taskResponse = (data, response, error)

    if let infoPlist = Bundle(for: GrabIdPartnerSDKTests.self).infoDictionary,
      let grabIdPartnerSDKConfig = infoPlist["GrabIdPartnerSDK"] as? Dictionary<String, AnyObject> {
      serviceConfigurationEndPoint = grabIdPartnerSDKConfig["ServiceDiscoveryUrl"] as? String ?? ""
    }
  }
  
  private func readMockDataFromPList(key: String) -> [String:Any]? {
    if let infoPlist = Bundle(for: GrabIdPartnerSDKTests.self).infoDictionary,
      let mockDataDict = infoPlist["MockJSONResponses"] as? Dictionary<String, AnyObject> {
      guard let mockData = mockDataDict[key] as? [String: AnyObject] else {
        return [:]
      }
      
      return mockData
    }
    return [:]
  }
  
  @objc override public func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
    guard let url = request.url else {
      return self.dataTaskMock
    }

    if let infoPlist = Bundle(for: GrabIdPartnerSDKTests.self).infoDictionary,
       let mockDataDict = infoPlist["MockJSONResponses"] as? Dictionary<String, AnyObject> {
      var mockResponse = ""
      var httpStatusCode = 400

      if url.absoluteString.contains(serviceConfigurationEndPoint) {
        if let configDict = mockDataDict[UrlSubstring.configuration.rawValue] {
          httpStatusCode = serviceErrorDictionary[UrlSubstring.configuration.rawValue] ?? 200
          if httpStatusCode == 200 {
            mockResponse = configDict[MockResponseType.validResponse.rawValue] as? String ?? ""
          } else {
            mockResponse = configDict[MockResponseType.errorResponse.rawValue] as? String ?? ""
          }
        }

        completionHandler(mockResponse.data(using: .utf8), HTTPURLResponse(url: url, statusCode: httpStatusCode, httpVersion: nil, headerFields: nil), nil)
      } else {
        for (urlSubstring, responseDict) in mockDataDict {
          if url.absoluteString.contains(urlSubstring) {
            resultConfigurationEndPoint = url.absoluteString
            
            if url.absoluteString.contains(UrlSubstring.refreshToken.rawValue) {
              refreshTokenServiceCalled = true
            }
            
            let httpStatusCode = serviceErrorDictionary[urlSubstring] ?? 200
            if httpStatusCode == 200 {
              mockResponse = responseDict[mockResponseType.rawValue] as? String ?? ""
              if let data = mockResponse.data(using: .utf8) {
                do {
                  // if the response contains nonce, we need to update it with the nonce generated
                  // during login. Otherwise, the validResponse will fail because of nonce mismatch.
                  // we can't mock nonce since nonce is generated during login for security validation.
                  if var jsonDict = try JSONSerialization.jsonObject(with: data) as? [String:Any],
                   jsonDict["nonce"] != nil {
                    jsonDict["nonce"] = nonce
                    if let responseData = try? JSONSerialization.data(withJSONObject: jsonDict, options: []) {
                      mockResponse = String(data:responseData, encoding:.utf8) ?? ""
                    }
                  }
                } catch {
                  // do nothing, unit test will eventually failed because of bad test data.
                }
              }
              completionHandler(mockResponse.data(using: .utf8), HTTPURLResponse(url: url, statusCode: httpStatusCode, httpVersion: nil, headerFields: nil), nil)
              break
            } else {
              let httpStatusCode = serviceErrorDictionary[urlSubstring] ?? 400
              let mockResponse = responseDict[MockResponseType.errorResponse.rawValue] as? String ?? ""
              completionHandler(mockResponse.data(using: .utf8), HTTPURLResponse(url: url, statusCode: httpStatusCode, httpVersion: nil, headerFields: nil), nil)
              break
            }
          }
        }
      }
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
