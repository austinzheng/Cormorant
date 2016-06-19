//
//  Params.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/9/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// A struct holding an arbitrary number of parameters without using refcounted storage if there are eight or fewer
/// params.
struct Params : RandomAccessCollection {

  // TODO: this shouldn't be necessary, but Swift 3 has issues with inferring the type otherwise...
  typealias Indices = DefaultRandomAccessIndices<Params>

  private var a0, a1, a2, a3, a4, a5, a6, a7 : Value?

  /// An array containing all parameters from 8 and onwards.
  private var others : [Value]?

  /// How many parameters are actually stored within the struct.
  private var effectiveCount = 0

  var startIndex : Int { return 0 }
  var endIndex : Int { return effectiveCount }

  func index(after i: Int) -> Int {
    precondition(i < endIndex)
    return i + 1
  }

  func index(before i: Int) -> Int {
    precondition(i > startIndex)
    return i - 1
  }

  init() { }

  init(_ a0: Value) {
    self.a0 = a0
    effectiveCount = 1
  }

  init(_ a0: Value, _ a1: Value) {
    self.a0 = a0; self.a1 = a1
    effectiveCount = 2
  }

  init(_ a0: Value, _ a1: Value, _ a2: Value) {
    self.a0 = a0; self.a1 = a1; self.a2 = a2
    effectiveCount = 3
  }

  /// Return a Params consisting of all arguments in the current Params except for the first.
  func rest() -> Params {
    if self.count == 0 {
      return self
    }
    var newParams = Params()
    for (idx, item) in enumerated() {
      if idx > 0 {
        newParams.append(item)
      }
    }
    return newParams
  }

  /// Return a Params consisting of a prefix argument followed by all arguments in the current Params.
  func prefixed(by prefix: Value) -> Params {
    var newParams = Params(prefix)
    for item in self {
      newParams.append(item)
    }
    return newParams
  }

  /// An array containing all values within the Params. Note that this should be used sparingly, since it is relatively
  /// expensive (requiring the creation of a mutable array).
  var asArray : [Value] {
    var buffer : [Value] = []
    for item in self {
      buffer.append(item)
    }
    return buffer
  }

  /// Push another value onto the Params struct. This is ONLY meant for the use case where the Params struct is
  /// initially being populated.
  mutating func append(_ newValue: Value) {
    switch count {
    case 0: a0 = newValue
    case 1: a1 = newValue
    case 2: a2 = newValue
    case 3: a3 = newValue
    case 4: a4 = newValue
    case 5: a5 = newValue
    case 6: a6 = newValue
    case 7: a7 = newValue
    default:
      others?.append(newValue)
      if others == nil {
        others = [newValue]
      }
    }
    effectiveCount += 1
  }

  subscript(idx: Int) -> Value {
    switch idx {
    case 0: return a0!
    case 1: return a1!
    case 2: return a2!
    case 3: return a3!
    case 4: return a4!
    case 5: return a5!
    case 6: return a6!
    case 7: return a7!
    default: return others![idx - 8]
    }
  }
}
