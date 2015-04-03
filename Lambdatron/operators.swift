//
//  operators.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

public func ==(lhs: ReaderMacro, rhs: ReaderMacro) -> Bool {
  return lhs.type == rhs.type && lhs.form == rhs.form
}

func ==(lhs: SeqType, rhs: SeqType) -> BoolOrEvalError {
  // Walk through the lists
  var leftGenerator = SeqIterator(lhs).generate()
  var rightGenerator = SeqIterator(rhs).generate()
  while true {
    let left = leftGenerator.next()
    let right = rightGenerator.next()
    if left == nil && right == nil {
      // Reached the end of both lists
      return true
    }
    if let left = left {
      switch left {
      case let .Success(left):
        if let right = right {
          switch right {
          case let .Success(right):
            if left != right {
              return false
            }
            continue
          case let .Error(err): return .Error(err)
          }
        }
      case let .Error(err): return .Error(err)
      }
    }
    // One is nil, the other isn't
    return false
  }
}

func ==(lhs: SeqType, rhs: VectorType) -> BoolOrEvalError {
  if rhs.count == 0 {
    return lhs.isEmpty
  }
  var idx = 0
  for item in SeqIterator(lhs) {
    if idx == rhs.count {
      // No more items in the array, or unequal items
      return false
    }
    switch item {
    case let .Success(item):
      if item != rhs[idx] {
        return false
      }
    case let .Error(err):
      return .Error(err)
    }
    idx += 1
  }
  // There can't be any more elements in the array
  return .Boolean(idx == (rhs.count - 1))
}

func ==(lhs: ConsValue, rhs: ConsValue) -> BoolOrEvalError {
  switch lhs {
  case let .Symbol(v1):
    switch rhs {
    case let .Symbol(v2): return .Boolean(v1 == v2)  // Can happen if comparing two quoted symbols
    default: return false
    }
  case let .Keyword(k1):
    switch rhs {
    case let .Keyword(k2): return .Boolean(k1 == k2)
    default: return false
    }
  case let .Special(s1):
    switch rhs {
    case let .Special(s2): return .Boolean(s1 == s2)
    default: return false
    }
  case let .BuiltInFunction(b1):
    switch rhs {
    case let .BuiltInFunction(b2): return .Boolean(b1 == b2)
    default: return false
    }
  case .Nil:
    switch rhs {
    case .Nil: return true
    default: return false
    }
  case let .BoolAtom(b1):
    switch rhs {
    case let .BoolAtom(b2): return .Boolean(b1 == b2)
    default: return false
    }
  case let .IntAtom(i1):
    switch rhs {
    case let .IntAtom(i2): return .Boolean(i1 == i2)
    default: return false
    }
  case let .FloatAtom(n1):
    switch rhs {
    case let .FloatAtom(n2): return .Boolean(n1 == n2)
    default: return false
    }
  case let .CharAtom(c1):
    switch rhs {
    case let .CharAtom(c2): return .Boolean(c1 == c2)
    default: return false
    }
  case let .StringAtom(s1):
    switch rhs {
    case let .StringAtom(s2): return .Boolean(s1 == s2)
    default: return false
    }
  case let .Namespace(ns1):
    switch rhs {
    case let .Namespace(ns2): return .Boolean(ns1 == ns2)
    default: return false
    }
  case let .Var(v1):
    switch rhs {
    case let .Var(v2): return .Boolean(v1 == v2)
    default: return false
    }
  case let .Auxiliary(a1):
    switch rhs {
    case let .Auxiliary(a2): return .Boolean(a1.equals(a2))
    default: return false
    }
  case let .Seq(s1):
    switch rhs {
    case let .Seq(s2): return s1 == s2
    case let .Vector(v2): return s1 == v2
    default: return false
    }
  case let .Vector(v1):
    switch rhs {
    case let .Seq(s2): return s2 == v1
    case let .Vector(v2): return .Boolean(v1 == v2)
    default: return false
    }
  case let .Map(m1):
    switch rhs {
    case let .Map(m2): return .Boolean(m1 == m2)
    default: return false
    }
  case let .MacroLiteral(m1):
    switch rhs {
    case let .MacroLiteral(m2): return .Boolean(m1 === m2)
    default: return false
    }
  case let .FunctionLiteral(f1):
    switch rhs {
    case let .FunctionLiteral(f2): return .Boolean(f1 === f2)
    default: return false
    }
  case .ReaderMacroForm: return false
  }
}

public func ==(lhs: ConsValue, rhs: ConsValue) -> Bool {
  let result : BoolOrEvalError = lhs == rhs
  switch result {
  case let .Boolean(b): return b
  case .Error: return false
  }
}
