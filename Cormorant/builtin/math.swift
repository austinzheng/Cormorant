//
//  math.swift
//  Cormorant
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Evaluate the equality of two numeric forms.
func pr_numericEquals(args: Params, _ ctx: Context) -> EvalResult {
  return test(args, ==, ==, ".==")
}

/// Evaluate whether arguments are in strictly decreasing order.
func pr_gt(args: Params, _ ctx: Context) -> EvalResult {
  return test(args, >, >, ".>")
}

/// Evaluate whether arguments are in monotonically decreasing order.
func pr_gteq(args: Params, _ ctx: Context) -> EvalResult {
  return test(args, >=, >=, ".>=")
}

/// Evaluate whether arguments are in strictly increasing order.
func pr_lt(args: Params, _ ctx: Context) -> EvalResult {
  return test(args, <, <, ".<")
}

/// Evaluate whether arguments are in monotonically increasing order.
func pr_lteq(args: Params, _ ctx: Context) -> EvalResult {
  return test(args, <=, <=, ".<=")
}

/// Take two numbers and return their sum.
func pr_plus(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".+"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let num0 = args[0].extractNumber()
  let num1 = args[1].extractNumber()
  
  switch num0 {
  case let .integer(v1):
    switch num1 {
    case let .integer(v2):
      let (sum, overflow) = Int.addWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.int(sum))
    case let .float(v2):
      return .Success(.float(Double(v1) + v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .float(v1):
    switch num1 {
    case let .integer(v2):
      return .Success(.float(v1 + Double(v2)))
    case let .float(v2):
      return .Success(.float(v1 + v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return their difference.
func pr_minus(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".-"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let num0 = args[0].extractNumber()
  let num1 = args[1].extractNumber()
  
  switch num0 {
  case let .integer(v1):
    switch num1 {
    case let .integer(v2):
      let (difference, overflow) = Int.subtractWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.int(difference))
    case let .float(v2):
      return .Success(.float(Double(v1) - v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .float(v1):
    switch num1 {
    case let .integer(v2):
      return .Success(.float(v1 - Double(v2)))
    case let .float(v2):
      return .Success(.float(v1 - v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return their product.
func pr_multiply(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".*"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let num0 = args[0].extractNumber()
  let num1 = args[1].extractNumber()
  
  switch num0 {
  case let .integer(v1):
    switch num1 {
    case let .integer(v2):
      let (product, overflow) = Int.multiplyWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.int(product))
    case let .float(v2):
      return .Success(.float(Double(v1) * v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .float(v1):
    switch num1 {
    case let .integer(v2):
      return .Success(.float(v1 * Double(v2)))
    case let .float(v2):
      return .Success(.float(v1 * v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return the result of dividing the first by the second.
func pr_divide(args: Params, _ ctx: Context) -> EvalResult {
  let fn = "./"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let num0 = args[0].extractNumber()
  let num1 = args[1].extractNumber()
  
  switch num0 {
  case let .integer(v1):
    switch num1 {
    case let .integer(v2):
      // In lieu of support for rationals (at this time), we return an Int if the two numbers are evenly divisible, a
      //  Double otherwise.
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      let (remainder, overflow) = Int.remainderWithOverflow(v1, v2)
      if overflow {
        return .Failure(EvalError(.IntegerOverflowError, fn))
      }
      else if remainder == 0 {
        let (quotient, overflow) = Int.divideWithOverflow(v1, v2)
        return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.int(quotient))
      }
      else {
        return .Success(.float(Double(v1) / Double(v2)))
      }
    case let .float(v2):
      return .Success(.float(Double(v1) / v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .float(v1):
    switch num1 {
    case let .integer(v2):
      return .Success(.float(v1 / Double(v2)))
    case let .float(v2):
      return .Success(.float(v1 / v2))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take the remainder of two numbers.
func pr_rem(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".rem"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let num0 = args[0].extractNumber()
  let num1 = args[1].extractNumber()
  
  switch num0 {
  case let .integer(v1):
    switch num1 {
    case let .integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      let (remainder, overflow) = Int.remainderWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.int(remainder))
    case let .float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.float(Double(v1).truncatingRemainder(dividingBy: v2)))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .float(v1):
    switch num1 {
    case let .integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.float(v1.truncatingRemainder(dividingBy: Double(v2))))
    case let .float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.float(v1.truncatingRemainder(dividingBy: v2)))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Take two numbers and return their quotient.
func pr_quot(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".quot"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let num0 = args[0].extractNumber()
  let num1 = args[1].extractNumber()

  switch num0 {
  case let .integer(v1):
    switch num1 {
    case let .integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      let (quotient, overflow) = Int.divideWithOverflow(v1, v2)
      return overflow ? .Failure(EvalError(.IntegerOverflowError, fn)) : .Success(.int(quotient))
    case let .float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.float(floor(Double(v1) / v2)))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .float(v1):
    switch num1 {
    case let .integer(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.float(floor(v1 / Double(v2))))
    case let .float(v2):
      if v2 == 0 { return .Failure(EvalError(.DivideByZeroError, fn)) }
      return .Success(.float(floor(v1 / v2)))
    case .invalid:
      return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}


// MARK: Private helpers

private typealias IntTestFn = (Int, Int) -> Bool
private typealias DoubleTestFn = (Double, Double) -> Bool

private func test(_ args: Params, _ ipred: IntTestFn, _ dpred: DoubleTestFn, _ fn: String) -> EvalResult {
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  let first = args[0].extractNumber()
  let second = args[1].extractNumber()
  switch first {
  case let .integer(v1):
    switch second {
    case let .integer(v2): return .Success(.bool(ipred(v1, v2)))
    case let .float(v2): return .Success(.bool(dpred(Double(v1), v2)))
    case .invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case let .float(v1):
    switch second {
    case let .integer(v2): return .Success(.bool(dpred(v1, Double(v2))))
    case let .float(v2): return .Success(.bool(dpred(v1, v2)))
    case .invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
    }
  case .invalid: return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}
