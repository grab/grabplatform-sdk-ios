/**
 * Copyright (c) Grab Taxi Holdings PTE LTD (GRAB)
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 */

import Foundation

struct KeychainTokenItem {
  
  enum KeychainError: Error {
    case noToken
    case unexpectedTokenData
    case unexpectedItemData
    case unhandledError(status: OSStatus)
  }
  
  let service: String
  
  let accessGroup: String?
  
  let key: String?
  
  init(service: String, key: String? = nil, accessGroup: String? = nil) {
    self.service = service
    self.accessGroup = accessGroup
    self.key = key
  }
  
  func readToken(id: String, scope: String) -> String? {
    let scopeArray = scope.lowercased().components(separatedBy: " ")
    let sortedScope = scopeArray.joined(separator: " ")
    return try? read(key: "\(id).\(sortedScope)")
  }
  
  func saveToken(id: String, scope: String, token: String) throws {
    let scopeArray = scope.lowercased().components(separatedBy: " ")
    let sortedScope = scopeArray.joined(separator: " ")
    try writeToken(keyPrefix: "\(id)", scope: sortedScope, token: token)
  }
  
  func removeToken(id: String, scope: String) throws {
    let scopeArray = scope.lowercased().components(separatedBy: " ")
    let sortedScope = scopeArray.joined(separator: " ")
    try deleteItem(key: "\(id).\(sortedScope)")
  }

  mutating func renameKey(existingKey: String, newKey: String) throws {
    // Try to update an existing item with the new key name.
    var attributesToUpdate = [String : AnyObject]()
    attributesToUpdate[kSecAttrAccount as String] = newKey as AnyObject?
    
    let query = KeychainTokenItem.keychainQuery(withService: service, key: existingKey, accessGroup: accessGroup)
    let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
    
    // Throw an error if an unexpected status was returned.
    guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
  }
  
  func deleteItem(key: String) throws {
    // Delete the existing item from the keychain.
    let query = KeychainTokenItem.keychainQuery(withService: service, key: key, accessGroup: accessGroup)
    let status = SecItemDelete(query as CFDictionary)
    
    // Throw an error if an unexpected status was returned.
    guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
  }
  
  static func tokenItems(forService service: String, accessGroup: String? = nil) throws -> [KeychainTokenItem] {
    // Build a query for all items that match the service and access group.
    var query = KeychainTokenItem.keychainQuery(withService: service, accessGroup: accessGroup)
    query[kSecMatchLimit as String] = kSecMatchLimitAll
    query[kSecReturnAttributes as String] = kCFBooleanTrue
    query[kSecReturnData as String] = kCFBooleanFalse
    
    // Fetch matching items from the keychain.
    var queryResult: AnyObject?
    let status = withUnsafeMutablePointer(to: &queryResult) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }
    
    // If no items were found, return an empty array.
    guard status != errSecItemNotFound else { return [] }
    
    // Throw an error if an unexpected status was returned.
    guard status == noErr else { throw KeychainError.unhandledError(status: status) }
    
    // Cast the query result to an array of dictionaries.
    guard let resultData = queryResult as? [[String : AnyObject]] else { throw KeychainError.unexpectedItemData }
    
    // Create a `KeychainPasswordItem` for each dictionary in the query result.
    var passwordItems = [KeychainTokenItem]()
    for result in resultData {
      guard let key = result[kSecAttrAccount as String] as? String else { throw KeychainError.unexpectedItemData }
      
      let passwordItem = KeychainTokenItem(service: service, key: key, accessGroup: accessGroup)
      passwordItems.append(passwordItem)
    }
    
    return passwordItems
  }
  
  // MARK: helpers
  
  private func read(key: String) throws -> String  {
     // Build a query to find the item that matches the service, account and
     // access group.
    var query = KeychainTokenItem.keychainQuery(withService: service, key: key, accessGroup: accessGroup)
    query[kSecMatchLimit as String] = kSecMatchLimitOne
    query[kSecReturnAttributes as String] = kCFBooleanTrue
    query[kSecReturnData as String] = kCFBooleanTrue
    
    // Try to fetch the existing keychain item that matches the query.
    var queryResult: AnyObject?
    let status = withUnsafeMutablePointer(to: &queryResult) {
      SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
    }
    
    // Check the return status and throw an error if appropriate.
    guard status != errSecItemNotFound else { throw KeychainError.noToken }
    guard status == noErr else { throw KeychainError.unhandledError(status: status) }
    
    // Parse the token string from the query result.
    guard let existingItem = queryResult as? [String : AnyObject],
      let passwordData = existingItem[kSecValueData as String] as? Data,
      let password = String(data: passwordData, encoding: String.Encoding.utf8)
      else {
        throw KeychainError.unexpectedTokenData
    }
    
    return password
  }
  
  private func writeToken(keyPrefix: String, scope: String, token: String) throws {
    // Encode the password into an Data object.
    let encodedToken = token.data(using: String.Encoding.utf8)!
    let key = "\(keyPrefix).\(scope)"
    
    do {
      // Check for an existing item in the keychain.
      try _ = read(key: key)
      
      // Update the existing item with the new password.
      var attributesToUpdate = [String : AnyObject]()
      attributesToUpdate[kSecValueData as String] = encodedToken as AnyObject?
      
      let query = KeychainTokenItem.keychainQuery(withService: service, key: key, accessGroup: accessGroup)
      let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
      
      // Throw an error if an unexpected status was returned.
      guard status == noErr else { throw KeychainError.unhandledError(status: status) }
    }
    catch KeychainError.noToken {
      // No password was found in the keychain. Create a dictionary to save
      // as a new keychain item.
      var newItem = KeychainTokenItem.keychainQuery(withService: service, key: key, accessGroup: accessGroup)
      newItem[kSecValueData as String] = encodedToken as AnyObject?
      
      // Add a the new item to the keychain.
      let status = SecItemAdd(newItem as CFDictionary, nil)
      
      // Throw an error if an unexpected status was returned.
      guard status == noErr else { throw KeychainError.unhandledError(status: status) }
    }
  }
  

  private static func keychainQuery(withService service: String, key: String? = nil, accessGroup: String? = nil) -> [String : AnyObject] {
    var query = [String : AnyObject]()
    query[kSecClass as String] = kSecClassGenericPassword
    query[kSecAttrService as String] = service as AnyObject?
    
    if let key = key {
      query[kSecAttrAccount as String] = key as AnyObject?
    }
    
    if let accessGroup = accessGroup {
      query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
    }
    
    return query
  }
}
