//
//  operators.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

func ==(lhs: Cons, rhs: Cons) -> Bool {
  var this = lhs
  var that = rhs
  // We have to walk through the lists
  while true {
    if this.value != that.value {
      // Different values
      return false
    }
    if this.next != nil && that.next == nil || this.next == nil && that.next != nil {
      // Different lengths
      return false
    }
    if this.next == nil && that.next == nil {
      // Same length, end of both lists
      return true
    }
    this = this.next!
    that = that.next!
  }
}

func ==(lhs: Cons, rhs: Vector) -> Bool {
  if rhs.count == 0 {
    return lhs.isEmpty
  }

  var that : Cons = lhs
  // Walk through the list
  for var i=0; i<rhs.count; i++ {
    if that.value != rhs[i] {
      // Different values
      return false
    }
    if let next = lhs.next {
      that = next
    }
    else {
      if i < rhs.count - 1 {
        // List is shorter than vector
        return false
      }
    }
  }
  if that.next != nil {
    // List is longer than vector
    return false
  }
  return true
}

func ==(lhs: ConsValue, rhs: ConsValue) -> Bool {
  switch lhs {
  case .None:
    switch rhs {
    case .None: return true
    default: return false
    }
  case let .Symbol(v1):
    switch rhs {
    case let .Symbol(v2): return v1 == v2  // Can happen if comparing two quoted symbols
    default: return false
    }
  case let .Special(s1):
    switch rhs {
    case let .Special(s2): return s1 == s2
    default: return false
    }
  case let .BuiltInFunction(b1):
    switch rhs {
    case let .BuiltInFunction(b2): return b1 == b2
    default: return false
    }
  case .NilLiteral:
    switch rhs {
    case .NilLiteral: return true
    default: return false
    }
  case let .BoolLiteral(b1):
    switch rhs {
    case let .BoolLiteral(b2): return b1 == b2
    default: return false
    }
  case let .IntegerLiteral(i1):
    switch rhs {
    case let .IntegerLiteral(i2): return i1 == i2
    default: return false
    }
  case let .FloatLiteral(n1):
    switch rhs {
    case let .FloatLiteral(n2): return n1 == n2
    default: return false
    }
  case let .StringLiteral(s1):
    switch rhs {
    case let .StringLiteral(s2): return s1 == s2
    default: return false
    }
  case let .ListLiteral(l1):
    switch rhs {
    case let .ListLiteral(l2): return l1 == l2
    case let .VectorLiteral(v2): return l1 == v2
    default: return false
    }
  case let .VectorLiteral(v1):
    switch rhs {
    case let .ListLiteral(l2): return l2 == v1
    case let .VectorLiteral(v2): return v1 == v2
    default: return false
    }
  case let .MapLiteral(m1):
    switch rhs {
    case let .MapLiteral(m2): return m1 == m2
    default: return false
    }
  case let .FunctionLiteral(f1):
    switch rhs {
    case let .FunctionLiteral(f2): return f1 === f2
    default: return false
    }
  case .RecurSentinel: return false
  case let .MacroArgument(ma1):
    switch rhs {
    case let .MacroArgument(ma2): return ma1.value == ma2.value
    default: return ma1.value == rhs
    }
  case .ReaderMacro: return false
  }
}
