//
//  auxiliary.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// A protocol that types can conform to if they wish to be accessible as Lambdatron objects. All values of
/// AuxiliaryType are atoms which evaluate to themselves.
public protocol AuxiliaryType : class {
  // Unfortunately, given Swift's lack of support for introspection/reflection, the use of AuxiliaryType to add support
  //  for arbitrary Swift types to Lambdatron at runtime is mostly circumscribed. This protocol is meant for making it
  //  easier to add features to Lambdatron that require runtime support.

  /// Return whether this AuxiliaryType instance is equal in value to another AuxiliaryType instance.
  func equals(_ other: AuxiliaryType) -> Bool
  /// Return a hash value (same as with Swift's Hashable protocol)
  var hashValue : Int { get }

  /// Return a description of the instance's value that can be printed out or otherwise displayed.
  func describe() -> String
  /// Return a description of the instance's value with additional detail useful for debugging or troubleshooting.
  func debugDescribe() -> String
  /// Return a stringified version of the instance's value. This may or may not be distinct from the description.
  func toString() -> String
}


// MARK: String builder

/// An opaque class representing a string builder.
public final class StringBuilderType : AuxiliaryType {
  var buffer : [Character]
  public var hashValue : Int { return ObjectIdentifier(self).hashValue }

  public func describe() -> String { return "#<StringBuilder \(string())>" }
  public func debugDescribe() -> String { return "Object.StringBuilder(\(buffer))" }
  public func toString() -> String { return string() }

  func append(_ str: String) { buffer += Array(str.characters) }
  func reverse() { buffer = buffer.reversed() }
  func string() -> String { return String(buffer) }

  public func equals(_ other: AuxiliaryType) -> Bool {
    if let other = other as? StringBuilderType {
      return self.buffer == other.buffer
    }
    return false
  }

  init() { buffer = [] }
  init(_ str: String) { buffer = Array(str.characters) }
}


// MARK: Regex

extension RegularExpression : AuxiliaryType {
  public func describe() -> String { return "#\"\(pattern)\"" }
  public func debugDescribe() -> String { return "Object.Regex(#\"\(pattern)\")" }
  public func toString() -> String { return pattern }

  public func equals(_ other: AuxiliaryType) -> Bool {
    if let other = other as? RegularExpression {
      return isEqual(other)
    }
    return false
  }
}
