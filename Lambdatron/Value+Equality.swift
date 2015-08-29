//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

private func areEqual(this: SeqType, _ that: SeqType) -> EvalOptional<Bool> {
  // Walk through the lists
  var leftGenerator = SeqIterator(this).generate()
  var rightGenerator = SeqIterator(that).generate()
  while true {
    let left = leftGenerator.next()
    let right = rightGenerator.next()
    if left == nil && right == nil {
      // Reached the end of both lists
      return .Just(true)
    }
    if let left = left {
      switch left {
      case let .Just(left):
        if let right = right {
          switch right {
          case let .Just(right):
            if left != right {
              return .Just(false)
            }
            continue
          case let .Error(err): return .Error(err)
          }
        }
      case let .Error(err): return .Error(err)
      }
    }
    // One is nil, the other isn't
    return .Just(false)
  }
}

private func areEqual(this: SeqType, _ that: VectorType) -> EvalOptional<Bool> {
  if that.count == 0 {
    return this.isEmpty
  }
  var idx = 0
  for item in SeqIterator(this) {
    if idx == that.count {
      // No more items in the array, or unequal items
      return .Just(false)
    }
    switch item {
    case let .Just(item):
      if item != that[idx] {
        return .Just(false)
      }
    case let .Error(err):
      return .Error(err)
    }
    idx += 1
  }
  // There can't be any more elements in the array
  return .Just(idx == (that.count - 1))
}

extension Value {
  func equals(that: Value) -> EvalOptional<Bool> {
    switch self {
    case let .Symbol(left):
      if case let .Symbol(right) = that {
        return .Just(left == right)
      }
    case let .Keyword(left):
      if case let .Keyword(right) = that {
        return .Just(left == right)
      }
    case let .Special(left):
      if case let .Special(right) = that {
        return .Just(left == right)
      }
    case let .BuiltInFunction(left):
      if case let .BuiltInFunction(right) = that {
        return .Just(left == right)
      }
    case .Nil:
      if case .Nil = that {
        return .Just(true)
      }
    case let .BoolAtom(left):
      if case let .BoolAtom(right) = that {
        return .Just(left == right)
      }
    case let .IntAtom(left):
      if case let .IntAtom(right) = that {
        return .Just(left == right)
      }
    case let .FloatAtom(left):
      if case let .FloatAtom(right) = that {
        return .Just(left == right)
      }
    case let .CharAtom(left):
      if case let .CharAtom(right) = that {
        return .Just(left == right)
      }
    case let .StringAtom(left):
      if case let .StringAtom(right) = that {
        return .Just(left == right)
      }
    case let .Namespace(left):
      if case let .Namespace(right) = that {
        return .Just(left == right)
      }
    case let .Var(left):
      if case let .Var(right) = that {
        return .Just(left == right)
      }
    case let .Auxiliary(left):
      if case let .Auxiliary(right) = that {
        return .Just(left.equals(right))
      }
    case let .Seq(left):
      switch that {
      case let .Seq(right): return areEqual(left, right)
      case let .Vector(right): return areEqual(left, right)
      default: return .Just(false)
      }
    case let .Vector(left):
      switch that {
      case let .Seq(right): return areEqual(right, left)
      case let .Vector(right): return .Just(left == right)
      default: return .Just(false)
      }
    case let .Map(left):
      if case let .Map(right) = that {
        return .Just(left == right)
      }
    case let .MacroLiteral(left):
      if case let .MacroLiteral(right) = that {
        return .Just(left === right)
      }
    case let .FunctionLiteral(left):
      if case let .FunctionLiteral(right) = that {
        return .Just(left === right)
      }
    case .ReaderMacroForm:
      return .Just(false)
    }
    return .Just(false)
  }
}

public func ==(lhs: Value, rhs: Value) -> Bool {
  switch lhs.equals(rhs) {
  case let .Just(b): return b
  case .Error: return false
  }
}
