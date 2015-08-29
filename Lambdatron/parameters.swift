//
//  parameters.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/9/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// A struct holding an arbitrary number of parameters without using refcounted storage if there are eight or fewer
/// params.
struct Params : CustomStringConvertible, CollectionType {
  private var a0, a1, a2, a3, a4, a5, a6, a7 : Value?

  /// An array containing all parameters from 8 and onwards.
  private var others : [Value]?

  /// How many parameters are stored within the struct.
  private(set) var count = 0

  var description : String { return describe(nil).asString }

  var startIndex : Int { return 0 }
  var endIndex : Int { return count }

  init() { }

  init(_ a0: Value) {
    self.a0 = a0
    count = 1
  }

  init(_ a0: Value, _ a1: Value) {
    self.a0 = a0; self.a1 = a1
    count = 2
  }

  init(_ a0: Value, _ a1: Value, _ a2: Value) {
    self.a0 = a0; self.a1 = a1; self.a2 = a2
    count = 3
  }

  /// Return a Params consisting of all arguments in the current Params except for the first.
  func rest() -> Params {
    if self.count == 0 {
      return self
    }
    var newParams = Params()
    for (idx, item) in enumerate() {
      if idx > 0 {
        newParams.append(item)
      }
    }
    return newParams
  }

  /// Return a Params consisting of a prefix argument followed by all arguments in the current Params.
  func prefixedBy(prefix: Value) -> Params {
    var newParams = Params(prefix)
    for item in self {
      newParams.append(item)
    }
    return newParams
  }

  /// Return the first item in the Params, or nil if none exists.
  var first : Value? {
    return a0
  }

  /// Return the last item in the Params. Precondition: the Params is not empty.
  var last : Value? {
    return count == 0 ? nil : self[count - 1]
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
  mutating func append(newValue: Value) {
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
    count++
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

  func generate() -> ParamsGenerator {
    return ParamsGenerator(self)
  }
}

struct ParamsGenerator : GeneratorType {
  private let params : Params
  private var index = 0

  mutating func next() -> Value? {
    if index < params.count {
      let value = params[index]
      index += 1
      return value
    }
    return nil
  }

  init(_ params: Params) {
    self.params = params
  }
}
