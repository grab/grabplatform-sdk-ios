/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import Foundation

@objc open class IdTokenInfo : NSObject, NSCoding {
  init(audience: String?,
       service: String?,
       notValidBefore: Date?,
       expiration: Date?,
       issueDate: Date?,
       issuer: String?,
       tokenId: String?,
       partnerId: String?,
       partnerUserid: String?,
       nonce: String?
    ) {
    self.audience = audience
    self.service = service
    self.notValidBefore = notValidBefore
    self.expiration = expiration
    self.issuer = issuer
    self.issueDate = issueDate
    self.partnerId = partnerId
    self.partnerUserId = partnerUserid
    self.tokenId = tokenId
    self.nonce = nonce
  }
  
  public func encode(with aCoder: NSCoder) {
    aCoder.encode(audience,forKey: "audience")
    aCoder.encode(service,forKey: "service")
    aCoder.encode(expiration, forKey: "expiration")
    aCoder.encode(notValidBefore,forKey: "notValidBefore")
    aCoder.encode(issueDate,forKey: "issueDate")
    aCoder.encode(issuer,forKey: "issuer")
    aCoder.encode(partnerId,forKey: "partnerId")
    aCoder.encode(nonce,forKey: "nonce")
  }
  
  public required init?(coder aDecoder: NSCoder) {
    self.audience = aDecoder.decodeObject(forKey:"audience") as? String
    self.service = aDecoder.decodeObject(forKey:"service") as? String
    self.notValidBefore =  aDecoder.decodeObject(forKey:"notValidBefore") as? Date
    self.expiration = aDecoder.decodeObject(forKey:"expiration") as? Date
    self.issuer = aDecoder.decodeObject(forKey:"issuer") as? String
    self.issueDate = aDecoder.decodeObject(forKey:"issueDate") as? Date
    self.partnerId = aDecoder.decodeObject(forKey:"partnerId") as? String
    self.nonce = aDecoder.decodeObject(forKey:"nonce") as? String
  }
  
  @objc public fileprivate(set) var audience: String? = nil       // audience
  @objc public fileprivate(set) var service: String? = nil        // service
  @objc public fileprivate(set) var notValidBefore: Date? = nil   // token valid start date
  @objc public fileprivate(set) var expiration: Date? = nil       // expiration
  @objc public fileprivate(set) var issueDate: Date? = nil        // issue date
  @objc public fileprivate(set) var issuer: String? = nil         // issuer
  @objc public fileprivate(set) var tokenId: String? = nil        // idToken
  @objc public fileprivate(set) var partnerId: String? = nil      // partner Id
  @objc public fileprivate(set) var partnerUserId: String? = nil  // partner user Id
  @objc public fileprivate(set) var nonce: String? = nil          // nonce
  
  internal func saveIdTokenInfo(loginSession: LoginSession) {
    if let nonce = nonce {
      let encodedData = NSKeyedArchiver.archivedData(withRootObject: self)
      if saveTokenInfoToKeyChain(loginSession: loginSession) {
        UserDefaults.standard.set(encodedData, forKey: nonce)
      }
    }
  }
  
  static internal func restoreIdToken(loginSession: LoginSession) -> IdTokenInfo? {
    guard let key = loginSession.nonce else {
      return nil
    }
    
    if let data = UserDefaults.standard.data(forKey: key),
      let idTokenInfo = NSKeyedUnarchiver.unarchiveObject(with: data) as? IdTokenInfo {
      if idTokenInfo.getTokenInfoFromKeyChain(loginSession:loginSession, idTokenInfo: idTokenInfo) {
        return idTokenInfo
      }
    }
    
    return nil
  }
  
  private func getTokenInfoFromKeyChain(loginSession: LoginSession, idTokenInfo: IdTokenInfo) -> Bool {
    let keyChain = KeychainTokenItem(service: loginSession.clientId)

    // read token from keychain
    let tokenId = keyChain.readToken(id: Constants.keyChainKeys.tokenId, scope: loginSession.scope)
    let partnerUserId = keyChain.readToken(id: Constants.keyChainKeys.partnerUserId, scope: loginSession.scope)

    if !(tokenId?.isEmpty ?? true),
      !(partnerUserId?.isEmpty ?? true) {
      idTokenInfo.tokenId = tokenId
      idTokenInfo.partnerUserId = partnerUserId
      return true
    } else {
      _ = GrabIdPartner.removeLoginSession(loginSession: loginSession)
      return false
    }
  }
  
  private func saveTokenInfoToKeyChain(loginSession: LoginSession) -> Bool {
    let keyChain = KeychainTokenItem(service: loginSession.clientId)
    do {
      try keyChain.saveToken(id: Constants.keyChainKeys.tokenId, scope: loginSession.scope, token: tokenId ?? "")
      try keyChain.saveToken(id: Constants.keyChainKeys.partnerUserId, scope: loginSession.scope, token: partnerUserId ?? "")
      return true
    } catch {
      // delete the tokens from keychain == no caching
      _ = GrabIdPartner.removeLoginSession(loginSession: loginSession)
    }

    return false
  }
  
  private struct Constants {
    struct keyChainKeys {
      static let tokenId = "tokenId" // unsigned idToken
      static let partnerUserId = "partnerUserId"
    }
  }
}

