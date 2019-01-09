/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import Foundation

class AuthorizationCodeGenerator {
  static private func digest(input : NSData) -> NSData {
    let digestLength = Int(CC_SHA256_DIGEST_LENGTH)
    var hash = [UInt8](repeating: 0, count: digestLength)
    CC_SHA256(input.bytes, UInt32(input.length), &hash)
    return NSData(bytes: hash, length: digestLength)
  }
  
  static private func sanitizeBase64EncodedString(string: String) -> String {
    let stringWithoutPadding = string.trimmingCharacters(in: CharacterSet(charactersIn: "="))
    let stringWithoutMinus = stringWithoutPadding.replacingOccurrences(of: "+", with: "-")
    return stringWithoutMinus.replacingOccurrences(of: "/", with: "_")
  }
  
  static func getCodeChallenge(verifier: String) -> String? {
    if let stringData = verifier.data(using: String.Encoding.utf8) {
      let hashData = digest(input: stringData as NSData)
      return sanitizeBase64EncodedString(string: hashData.base64EncodedString(options: []))
    }
    return ""
  }
  
  static func getCodeVerifier() -> String? {
    var keyData = Data(count: 32)
    let result = keyData.withUnsafeMutableBytes {
      (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
      SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
    }
    if result == errSecSuccess {
      return sanitizeBase64EncodedString(string: keyData.base64EncodedString())
    } else {
      return nil
    }
  }
}

