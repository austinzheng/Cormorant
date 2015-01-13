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
  case let .IntegerLiteral(v): return .Integer(v)
  case let .FloatLiteral(v): return .Float(v)
  default: return .Invalid
  }
}

/// Evaluate the equality of two numeric forms.
func pr_numericEquals(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let first = extractNumber(args[0])
  let second = extractNumber(args[1])
  switch first {
  case let .Integer(v1):
    switch second {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 == v2))
    case let .Float(v2): return .Success(.BoolLiteral(Double(v1) == v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch second {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 == Double(v2)))
    case let .Float(v2): return .Success(.BoolLiteral(v1 == v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case .Invalid: return .Failure(.InvalidArgumentError)
  }
}

/// Evaluate whether arguments are in monotonically decreasing order.
func pr_gt(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 > v2))
    case let .Float(v2): return .Success(.BoolLiteral(Double(v1) > v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 > Double(v2)))
    case let .Float(v2): return .Success(.BoolLiteral(v1 > v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Evaluate whether arguments are in monotonically increasing order.
func pr_lt(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 < v2))
    case let .Float(v2): return .Success(.BoolLiteral(Double(v1) < v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 < Double(v2)))
    case let .Float(v2): return .Success(.BoolLiteral(v1 < v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take two numbers and return their sum.
func pr_plus(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.IntegerLiteral(v1 + v2))
    case let .Float(v2):
      return .Success(.FloatLiteral(Double(v1) + v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatLiteral(v1 + Double(v2)))
    case let .Float(v2):
      return .Success(.FloatLiteral(v1 + v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take two numbers and return their difference.
func pr_minus(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.IntegerLiteral(v1 - v2))
    case let .Float(v2):
      return .Success(.FloatLiteral(Double(v1) - v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatLiteral(v1 - Double(v2)))
    case let .Float(v2):
      return .Success(.FloatLiteral(v1 - v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take two numbers and return their product.
func pr_multiply(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.IntegerLiteral(v1 * v2))
    case let .Float(v2):
      return .Success(.FloatLiteral(Double(v1) * v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatLiteral(v1 * Double(v2)))
    case let .Float(v2):
      return .Success(.FloatLiteral(v1 * v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take one or more numbers and return their quotient. If only one number, returns 1/arg[0].
func pr_divide(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(Double(v1) / Double(v2)))
    case let .Float(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(Double(v1) / v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(v1 / Double(v2)))
    case let .Float(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(v1 / v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take the remainder of two numbers.
func pr_rem(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.IntegerLiteral(v1 % v2))
    case let .Float(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(Double(v1) % v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(v1 % Double(v2)))
    case let .Float(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(v1 % v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}
