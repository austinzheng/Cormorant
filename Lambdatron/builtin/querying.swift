//
//  querying.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Return whether or not the argument is nil.
func pr_isNil(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .NilLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a number of some sort.
func pr_isNumber(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .IntegerLiteral, .FloatLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isInteger(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .IntegerLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isFloat(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .FloatLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a string literal.
func pr_isString(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .StringLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a symbol.
func pr_isSymbol(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .Symbol: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a user-defined function.
func pr_isFunction(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .FunctionLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is something that can be called in function position (e.g. special forms).
func pr_isEvalable(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  // User-defined functions, built-ins, and special forms are eval'able.
  // TODO: sets should also be eval'able, as they are in Clojure
  switch args[0] {
  case .Symbol, .Keyword, .FunctionLiteral, .VectorLiteral, .MapLiteral, .Special, .BuiltInFunction:
    return .Success(.BoolLiteral(true))
  default:
    return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is the boolean value 'true'.
func pr_isTrue(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is the boolean value 'false'.
func pr_isFalse(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == false))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a list.
func pr_isList(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .ListLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a vector.
func pr_isVector(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .VectorLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a map.
func pr_isMap(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .MapLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a sequence.
func pr_isSeq(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .ListLiteral, .VectorLiteral, .MapLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not a number is positive.
func pr_isPos(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolLiteral(v > 0))
  case let .Float(v):
    return .Success(.BoolLiteral(!v.isSignMinus && !v.isZero))
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Return whether or not a number is negative.
func pr_isNeg(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolLiteral(v < 0))
  case let .Float(v):
    return .Success(.BoolLiteral(v.isSignMinus && !v.isZero))
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Return whether or not a number is zero.
func pr_isZero(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolLiteral(v == 0))
  case let .Float(v):
    return .Success(.BoolLiteral(v.isZero))
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Return whether or not a number is floating-point and subnormal (indicating underflow).
func pr_isSubnormal(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolLiteral(false))
  case let .Float(v):
    return .Success(.BoolLiteral(v.isSubnormal))
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Return whether or not a number is floating-point and infinite.
func pr_isInfinite(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolLiteral(false))
  case let .Float(v):
    return .Success(.BoolLiteral(v.isInfinite))
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Return whether or not a number is floating-point and a NaN.
func pr_isNaN(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolLiteral(false))
  case let .Float(v):
    return .Success(.BoolLiteral(v.isNaN))
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}
