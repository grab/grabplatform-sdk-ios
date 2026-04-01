/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import Foundation
#if canImport(CryptoSwift)
import CryptoSwift
#endif

class AuthorizationCodeGenerator {
  
  #if canImport(CryptoSwift)
  static private func digest(input: Data) -> Data {
    let hash = input.sha256()
    return Data(hash)
  }
  #else
  static private func digest(input : NSData) -> NSData {
    let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
    var hash = [UInt8](repeating: 0, count: digestLength)
    CC_SHA256(input.bytes, UInt32(input.length), &hash)
    return NSData(bytes: hash, length: digestLength)
  }
  #endif
  
  static private func sanitizeBase64EncodedString(string: String) -> String {
    let stringWithoutPadding = string.trimmingCharacters(in: CharacterSet(charactersIn: "="))
    let stringWithoutMinus = stringWithoutPadding.replacingOccurrences(of: "+", with: "-")
    return stringWithoutMinus.replacingOccurrences(of: "/", with: "_")
  }
  
  static func getCodeChallenge(verifier: String) -> String? {
    if let stringData = verifier.data(using: String.Encoding.utf8) {
      #if canImport(CryptoSwift)
      let hashData = digest(input: stringData)
      return sanitizeBase64EncodedString(string: hashData.base64EncodedString())
      #else
      let hashData = digest(input: stringData as NSData)
      return sanitizeBase64EncodedString(string: hashData.base64EncodedString(options: []))
      #endif
    }
    return ""
  }
  
  static func getCodeVerifier() -> String? {
    var keyData = Data(count: 32)
    let result = keyData.withUnsafeMutableBytes { mutableBytes -> Int32 in
      guard let baseAddress = mutableBytes.baseAddress else {
        return errSecParam
      }
      return SecRandomCopyBytes(kSecRandomDefault, 32, baseAddress)
    }
    if result == errSecSuccess {
      return sanitizeBase64EncodedString(string: keyData.base64EncodedString())
    } else {
      return nil
    }
  }
}

