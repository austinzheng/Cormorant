//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

private func areEqual(_ this: SeqType, _ that: SeqType) -> EvalOptional<Bool> {
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

private func areEqual(_ this: SeqType, _ that: VectorType) -> EvalOptional<Bool> {
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
  func equals(_ that: Value) -> EvalOptional<Bool> {
    switch self {
    case let .symbol(left):
      if case let .symbol(right) = that {
        return .Just(left == right)
      }
    case let .keyword(left):
      if case let .keyword(right) = that {
        return .Just(left == right)
      }
    case let .special(left):
      if case let .special(right) = that {
        return .Just(left == right)
      }
    case let .builtInFunction(left):
      if case let .builtInFunction(right) = that {
        return .Just(left == right)
      }
    case .nilValue:
      if case .nilValue = that {
        return .Just(true)
      }
    case let .bool(left):
      if case let .bool(right) = that {
        return .Just(left == right)
      }
    case let .int(left):
      if case let .int(right) = that {
        return .Just(left == right)
      }
    case let .float(left):
      if case let .float(right) = that {
        return .Just(left == right)
      }
    case let .char(left):
      if case let .char(right) = that {
        return .Just(left == right)
      }
    case let .string(left):
      if case let .string(right) = that {
        return .Just(left == right)
      }
    case let .namespace(left):
      if case let .namespace(right) = that {
        return .Just(left == right)
      }
    case let .`var`(left):
      if case let .`var`(right) = that {
        return .Just(left == right)
      }
    case let .auxiliary(left):
      if case let .auxiliary(right) = that {
        return .Just(left.equals(right))
      }
    case let .seq(left):
      switch that {
      case let .seq(right): return areEqual(left, right)
      case let .vector(right): return areEqual(left, right)
      default: return .Just(false)
      }
    case let .vector(left):
      switch that {
      case let .seq(right): return areEqual(right, left)
      case let .vector(right): return .Just(left == right)
      default: return .Just(false)
      }
    case let .map(left):
      if case let .map(right) = that {
        return .Just(left == right)
      }
    case let .macroLiteral(left):
      if case let .macroLiteral(right) = that {
        return .Just(left === right)
      }
    case let .functionLiteral(left):
      if case let .functionLiteral(right) = that {
        return .Just(left === right)
      }
    case .readerMacroForm:
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
