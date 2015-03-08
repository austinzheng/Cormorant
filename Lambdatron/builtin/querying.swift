//
//  querying.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Return whether or not the argument is nil.
func pr_isNil(args: Params, ctx: Context) -> EvalResult {
  let fn = ".nil?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Nil: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a number of some sort.
func pr_isNumber(args: Params, ctx: Context) -> EvalResult {
  let fn = ".number?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .IntAtom, .FloatAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isInteger(args: Params, ctx: Context) -> EvalResult {
  let fn = ".int?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .IntAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isFloat(args: Params, ctx: Context) -> EvalResult {
  let fn = ".float?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .FloatAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a string.
func pr_isString(args: Params, ctx: Context) -> EvalResult {
  let fn = ".string?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .StringAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a character.
func pr_isChar(args: Params, ctx: Context) -> EvalResult {
  let fn = ".char?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .CharAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a symbol.
func pr_isSymbol(args: Params, ctx: Context) -> EvalResult {
  let fn = ".symbol?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Symbol: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a keyword.
func pr_isKeyword(args: Params, ctx: Context) -> EvalResult {
  let fn = ".keyword?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Keyword: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a user-defined or built-in function.
func pr_isFunction(args: Params, ctx: Context) -> EvalResult {
  let fn = ".fn?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .FunctionLiteral, .BuiltInFunction: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is something that can be called in function position (e.g. special forms).
func pr_isEvalable(args: Params, ctx: Context) -> EvalResult {
  let fn = ".eval?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  // User-defined functions, built-ins, and special forms are eval'able.
  // TODO: sets should also be eval'able, as they are in Clojure
  switch args[0] {
  case .Symbol, .Keyword, .FunctionLiteral, .Vector, .Map, .Special, .BuiltInFunction:
    return .Success(true)
  default:
    return .Success(false)
  }
}

/// Return whether or not the argument is the boolean value 'true'.
func pr_isTrue(args: Params, ctx: Context) -> EvalResult {
  let fn = ".true?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .BoolAtom(b): return .Success(.BoolAtom(b == true))
  default: return .Success(false)
  }
}

/// Return whether or not the argument is the boolean value 'false'.
func pr_isFalse(args: Params, ctx: Context) -> EvalResult {
  let fn = ".false?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .BoolAtom(b): return .Success(.BoolAtom(b == false))
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a list.
func pr_isList(args: Params, ctx: Context) -> EvalResult {
  let fn = ".list?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .List: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a vector.
func pr_isVector(args: Params, ctx: Context) -> EvalResult {
  let fn = ".vector?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Vector: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a map.
func pr_isMap(args: Params, ctx: Context) -> EvalResult {
  let fn = ".map?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Map: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a sequence.
func pr_isSeq(args: Params, ctx: Context) -> EvalResult {
  let fn = ".seq?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .List, .Vector, .Map: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not a number is positive.
func pr_isPos(args: Params, ctx: Context) -> EvalResult {
  let fn = ".pos?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolAtom(v > 0))
  case let .Float(v):
    return .Success(.BoolAtom(!v.isSignMinus && !v.isNaN && !v.isZero))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Return whether or not a number is negative.
func pr_isNeg(args: Params, ctx: Context) -> EvalResult {
  let fn = ".neg?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolAtom(v < 0))
  case let .Float(v):
    return .Success(.BoolAtom(v.isSignMinus && !v.isNaN && !v.isZero))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Return whether or not a number is zero.
func pr_isZero(args: Params, ctx: Context) -> EvalResult {
  let fn = ".zero?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(.BoolAtom(v == 0))
  case let .Float(v):
    return .Success(.BoolAtom(v.isZero))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Return whether or not a number is floating-point and subnormal (indicating underflow).
func pr_isSubnormal(args: Params, ctx: Context) -> EvalResult {
  let fn = ".subnormal?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(false)
  case let .Float(v):
    return .Success(.BoolAtom(v.isSubnormal))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Return whether or not a number is floating-point and infinite.
func pr_isInfinite(args: Params, ctx: Context) -> EvalResult {
  let fn = ".infinite?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(false)
  case let .Float(v):
    return .Success(.BoolAtom(v.isInfinite))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Return whether or not a number is floating-point and a NaN.
func pr_isNaN(args: Params, ctx: Context) -> EvalResult {
  let fn = ".nan?"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = extractNumber(args[0])
  switch num {
  case let .Integer(v):
    return .Success(false)
  case let .Float(v):
    return .Success(.BoolAtom(v.isNaN))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}
