//
//  querying.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Return whether or not the argument is nil.
func pr_isNil(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".nil?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Nil: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a number of some sort.
func pr_isNumber(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".number?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .IntAtom, .FloatAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isInteger(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".int?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .IntAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isFloat(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".float?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .FloatAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a string.
func pr_isString(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".string?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .StringAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a character.
func pr_isChar(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".char?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .CharAtom: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a symbol.
func pr_isSymbol(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".symbol?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Symbol: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a keyword.
func pr_isKeyword(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".keyword?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Keyword: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a user-defined or built-in function.
func pr_isFunction(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".fn?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .FunctionLiteral, .BuiltInFunction: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is something that can be called in function position (e.g. special forms).
func pr_isEvalable(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".eval?"
  guard args.count == 1 else {
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
func pr_isTrue(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".true?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .BoolAtom(b): return .Success(.BoolAtom(b == true))
  default: return .Success(false)
  }
}

/// Return whether or not the argument is the boolean value 'false'.
func pr_isFalse(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".false?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .BoolAtom(b): return .Success(.BoolAtom(b == false))
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a Var.
func pr_isVar(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".var?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Var: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a sequence.
func pr_isSeq(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".seq?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Seq: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a vector.
func pr_isVector(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".vector?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Vector: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not the argument is a map.
func pr_isMap(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".map?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .Map: return .Success(true)
  default: return .Success(false)
  }
}

/// Return whether or not a number is positive.
func pr_isPos(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".pos?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = args[0].extractNumber()
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
func pr_isNeg(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".neg?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = args[0].extractNumber()
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
func pr_isZero(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".zero?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = args[0].extractNumber()
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
func pr_isSubnormal(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".subnormal?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = args[0].extractNumber()
  switch num {
  case .Integer:
    return .Success(false)
  case let .Float(v):
    return .Success(.BoolAtom(v.isSubnormal))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Return whether or not a number is floating-point and infinite.
func pr_isInfinite(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".infinite?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = args[0].extractNumber()
  switch num {
  case .Integer:
    return .Success(false)
  case let .Float(v):
    return .Success(.BoolAtom(v.isInfinite))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}

/// Return whether or not a number is floating-point and a NaN.
func pr_isNaN(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".nan?"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let num = args[0].extractNumber()
  switch num {
  case .Integer:
    return .Success(false)
  case let .Float(v):
    return .Success(.BoolAtom(v.isNaN))
  case .Invalid:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}
