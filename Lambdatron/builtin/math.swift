//
//  math.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum wrapping one of several numerical types, or an invalid value sigil.
internal enum NumericalType {
  case Integer(Int)
  case Float(Double)
  case Invalid
}

/// Convert a given ConsValue argument into the equivalent NumericalType token.
internal func extractNumber(n: ConsValue) -> NumericalType {
  switch n {
  case let .IntAtom(v): return .Integer(v)
  case let .FloatAtom(v): return .Float(v)
  default: return .Invalid
  }
}

/// Evaluate the equality of two numeric forms.
func pr_numericEquals(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".=="
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let first = extractNumber(args[0])
  let second = extractNumber(args[1])
  switch first {
  case let .Integer(v1):
    switch second {
    case let .Integer(v2): return .Success(.BoolAtom(v1 == v2))
    case let .Float(v2): return .Success(.BoolAtom(Double(v1) == v2))
    case .Invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch second {
    case let .Integer(v2): return .Success(.BoolAtom(v1 == Double(v2)))
    case let .Float(v2): return .Success(.BoolAtom(v1 == v2))
    case .Invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Evaluate whether arguments are in monotonically decreasing order.
func pr_gt(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".>"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolAtom(v1 > v2))
    case let .Float(v2): return .Success(.BoolAtom(Double(v1) > v2))
    case .Invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolAtom(v1 > Double(v2)))
    case let .Float(v2): return .Success(.BoolAtom(v1 > v2))
    case .Invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Evaluate whether arguments are in monotonically increasing order.
func pr_lt(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".<"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolAtom(v1 < v2))
    case let .Float(v2): return .Success(.BoolAtom(Double(v1) < v2))
    case .Invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolAtom(v1 < Double(v2)))
    case let .Float(v2): return .Success(.BoolAtom(v1 < v2))
    case .Invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return their sum.
func pr_plus(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".+"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      let (sum, overflow) = Int.addWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.IntAtom(sum))
    case let .Float(v2):
      return .Success(.FloatAtom(Double(v1) + v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatAtom(v1 + Double(v2)))
    case let .Float(v2):
      return .Success(.FloatAtom(v1 + v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return their difference.
func pr_minus(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".-"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      let (difference, overflow) = Int.subtractWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.IntAtom(difference))
    case let .Float(v2):
      return .Success(.FloatAtom(Double(v1) - v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatAtom(v1 - Double(v2)))
    case let .Float(v2):
      return .Success(.FloatAtom(v1 - v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return their product.
func pr_multiply(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".*"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      let (product, overflow) = Int.multiplyWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.IntAtom(product))
    case let .Float(v2):
      return .Success(.FloatAtom(Double(v1) * v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatAtom(v1 * Double(v2)))
    case let .Float(v2):
      return .Success(.FloatAtom(v1 * v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return the result of dividing the first by the second.
func pr_divide(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = "./"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      // In lieu of support for rationals (at this time), we return an Int if the two numbers are evenly divisible, a
      //  Double otherwise.
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      let (remainder, overflow) = Int.remainderWithOverflow(v1, v2)
      if overflow {
        return .Failure(EvalError(.IntegerOverflowError, fn))
      }
      else if remainder == 0 {
        let (quotient, overflow) = Int.divideWithOverflow(v1, v2)
        return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.IntAtom(quotient))
      }
      else {
        return .Success(.FloatAtom(Double(v1) / Double(v2)))
      }
    case let .Float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(Double(v1) / v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(v1 / Double(v2)))
    case let .Float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(v1 / v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take the remainder of two numbers.
func pr_rem(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".rem"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      let (remainder, overflow) = Int.remainderWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.IntAtom(remainder))
    case let .Float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(Double(v1) % v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(v1 % Double(v2)))
    case let .Float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(v1 % v2))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return their quotient.
func pr_quot(args: [ConsValue], ctx: Context) -> EvalResult {
  let fn = ".quot"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])

  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      let (quotient, overflow) = Int.divideWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.IntAtom(quotient))
    case let .Float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(floor(Double(v1) / v2)))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(floor(v1 / Double(v2))))
    case let .Float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.FloatAtom(floor(v1 / v2)))
    case .Invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}
