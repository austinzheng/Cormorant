//
//  ds.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

class Cons {
  var next : Cons?
  let value : ConsValue

  init(next: Cons?, value: ConsValue) {
    self.next = next
    self.value = value
  }

  func eval() -> LiteralValue {
    // TODO
    return .NilLiteral
  }
}

/// Represents the value of an item in a single cons cell; either a variable or a literal of some sort
enum ConsValue {
  case Variable(String)
  case Literal(LiteralValue)
}

/// Represents a literal value found within a ConsValue
enum LiteralValue {
  case NilLiteral
  case BoolLiteral(Bool)
  case NumberLiteral(Double)
  case StringLiteral(String)
  case List(Cons)
  case Vector([ConsValue])

  var isFalsy : Bool {
    get {
      switch self {
      case let NilLiteral: return true
      case let BoolLiteral(x): return x == false
      case let NumberLiteral(x): return x == 0
      case let StringLiteral(x): return NSString(string: x).length == 0
      case List(_): return false
      case let Vector(items): return items.count == 0
      }
    }
  }
}
