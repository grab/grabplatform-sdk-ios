/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import Foundation
@objc public enum GrabIdPartnerErrorDomain: Int {
  case serviceDiscovery
  case loadConfiguration
  case authorization
  case exchangeToken
  case getIdTokenInfo
  case logout
  case protectedResource
}

@objc public enum GrabIdPartnerErrorCode : Int {
  case grabIdServiceFailed
  case discoveryServiceFailed
  case idTokenInfoServiceFailed
  case exchangeTokenServiceFailed
  case authorizationInitializationFailure
  case securityValidationFailed
  case logoutFailed
  case invalidIdToken                 // The id token is invalid.
  case invalidNonce
  case invalidConfiguration           // Missing GrabIdPartnerSDK in plist/manifest
  case somethingWentWrong             // This error is unexpected or cannot be exposed.
  case network                        // There is an issue with network connectivity.
  case invalidClientId                // Invalid client id
  case invalidScope                   // Invalid scope
  case invalidRedirectUrl             // Invalid redirect url
  case invalidAuthorizationCode       // Invalid authorization code
  case invalidUrl                     // The authorize end point is invalid
  case invalidPartnerId               // Partner id is not set in AndroidManifest.
  case unAuthorized                   // Partner application is unauthorized.
  case authorizationFailed            // Authorization failed
  case serviceUnavailable             // The service was not available.
  case serviceError                   // The GrabId service is returning an error.
  case invalidAccessToken             // The access token is invalid.
  case invalidResponse                // Unexpected response from GrabId service
  case invalidServiceDiscoveryUrl     // Invalid service discovery url
  
  case partnerAppError = 10000               // app defined errors are 10000 and above
  // more to come ...
}

@objc open class GrabIdPartnerError : NSObject {
  @objc public let domain: GrabIdPartnerErrorDomain
  @objc public let code : GrabIdPartnerErrorCode
  @objc public let localizeMessage : String?
  @objc public let serviceError : Error?            // network or service error
  
  @objc public init(code: GrabIdPartnerErrorCode, localizeMessage: String? = nil, domain: GrabIdPartnerErrorDomain, serviceError: Error? = nil) {
    self.code = code
    self.localizeMessage = localizeMessage
    self.serviceError = serviceError
    self.domain = domain
    
    super.init()
  }
}

@objc public enum GrabIdPartnerLocalization: Int, RawRepresentable {
  case invalidUrl
  case securityValidationFailed
  case authorizationInitializationFailure
  case invalidResponse
  case logoutFailed
  case invalidIdToken
  case invalidNonce
  case invalidConfiguration
  case somethingWentWrong
  case invalidClientId
  case invalidScope
  case invalidRedirectUrl
  case serviceError
    
  public typealias RawValue = String
    
  public var rawValue: RawValue {
    switch self {
      case .invalidUrl: return Localization.invalidUrl
      case .securityValidationFailed: return Localization.securityValidationFailed
      case .somethingWentWrong:  return Localization.somethingWentWrong
      case .invalidResponse:  return Localization.invalidResponse
      case .authorizationInitializationFailure: return Localization.authorizationInitializationFailure
      case .invalidIdToken: return Localization.invalidIdToken
      case .invalidNonce: return Localization.invalidNonce
      case .logoutFailed: return Localization.logoutFailed
      case .invalidClientId: return Localization.invalidClientId
      case .invalidScope: return Localization.invalidScope
      case .invalidRedirectUrl: return Localization.invalidRedirectUrl
      case .invalidConfiguration: return Localization.invalidConfiguration
      case .serviceError: return Localization.serviceError
    }
  }
    
  public init?(rawValue: RawValue) {
    switch rawValue {
      case Localization.invalidUrl: self = .invalidUrl
      case Localization.somethingWentWrong: self = .somethingWentWrong
      case Localization.securityValidationFailed: self = .securityValidationFailed
      case Localization.invalidResponse: self = .invalidResponse
      case Localization.authorizationInitializationFailure: self = .authorizationInitializationFailure
      case Localization.logoutFailed: self = .logoutFailed
      case Localization.invalidIdToken: self = .invalidIdToken
      case Localization.invalidNonce: self = .invalidNonce
      case Localization.invalidClientId: self = .invalidClientId
      case Localization.invalidScope: self = .invalidScope
      case Localization.invalidRedirectUrl: self = .invalidRedirectUrl
      case Localization.invalidConfiguration: self = .invalidConfiguration
      case Localization.serviceError: self = .serviceError
      
      default: self = .somethingWentWrong
    }
  }
  
  private struct Localization {
    static let invalidUrl = "Invalid Url."
    static let securityValidationFailed = "Security validation failed."
    static let invalidResponse = "Invalid response from GrabId Partner service."
    static let authorizationInitializationFailure = "Authorization initialization failed."
    static let logoutFailed = "Logout failed."
    static let somethingWentWrong = "Unknown."
    static let invalidIdToken = "Invalid idToken."
    static let invalidNonce = "Invalid Nonce."
    static let invalidConfiguration = "Configuration error."
    static let invalidClientId = "Invalid client id."
    static let invalidScope = "Invalid scope."
    static let invalidRedirectUrl = "Invalid redirect url."
    static let serviceError = "GrabId service error."
  }
}
