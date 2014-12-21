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
struct InternedSymbol : Hashable {
  let identifier: Int
  // TODO: namespaces support would go here
  
  init(_ identifier: Int) {
    self.identifier = identifier
  }
  
  var hashValue : Int {
    return identifier.hashValue
  }
}

func ==(lhs: InternedSymbol, rhs: InternedSymbol) -> Bool {
  return lhs.identifier == rhs.identifier
}

/// A value representing an interned keyword.
struct InternedKeyword : Hashable {
  let identifier: Int
  
  init(_ identifier: Int) {
    self.identifier = identifier
  }
  
  var hashValue : Int {
    return identifier.hashValue
  }
}

func ==(lhs: InternedKeyword, rhs: InternedKeyword) -> Bool {
  return lhs.identifier == rhs.identifier
}
