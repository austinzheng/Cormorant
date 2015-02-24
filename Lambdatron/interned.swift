//
//  interned.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An value representing an interned symbol. This is a lightweight fixed-size struct. There is a one-to-one mapping
/// between every symbol name used in the program (no matter the context) and a distinct InternedSymbol value.
public struct InternedSymbol : Hashable {
  let identifier: UInt
  // TODO: namespaces support would go here
  
  init(_ identifier: UInt) {
    self.identifier = identifier
  }
  
  public var hashValue : Int {
    return identifier.hashValue
  }
}

public func ==(lhs: InternedSymbol, rhs: InternedSymbol) -> Bool {
  return lhs.identifier == rhs.identifier
}

/// A value representing an interned keyword.
public struct InternedKeyword : Hashable {
  let identifier: UInt
  
  init(_ identifier: UInt) {
    self.identifier = identifier
  }
  
  public var hashValue : Int {
    return identifier.hashValue
  }
}

public func ==(lhs: InternedKeyword, rhs: InternedKeyword) -> Bool {
  return lhs.identifier == rhs.identifier
}
