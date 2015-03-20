//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/13/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a symbol or string, return a corresponding symbol.
func pr_symbol(args: Params, ctx: Context) -> EvalResult {
  let fn = ".symbol"
  if args.count != 1 {
    return .Failure(args.count == 2
      ? EvalError.runtimeError(fn, message: "namespaces are not (yet) supported")
      : EvalError.arityError("1 or 2", actual: args.count, fn))
  }
  switch args[0] {
  case .Symbol:
    return .Success(args[0])
  case let .StringAtom(s):
    return .Success(s.isEmpty ? .Nil : .Symbol(ctx.symbolForName(s)))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol or string"))
  }
}

/// Given a symbol, string, or keyword, return a corresponding keyword; otherwise, return nil.
func pr_keyword(args: Params, ctx: Context) -> EvalResult {
  let fn = ".keyword"
  if args.count != 1 {
    return .Failure(args.count == 2
      ? EvalError.runtimeError(fn, message: "namespaces are not (yet) supported")
      : EvalError.arityError("1 or 2", actual: args.count, fn))
  }
  switch args[0] {
  case let .Symbol(s):
    let name = ctx.nameForSymbol(s)
    return .Success(.Keyword(ctx.keywordForName(name)))
  case .Keyword:
    return .Success(args[0])
  case let .StringAtom(s):
    return .Success(s.isEmpty ? .Nil : .Keyword(ctx.keywordForName(s)))
  default:
    return .Success(.Nil)
  }
}

/// Cast an argument to an integer.
func pr_int(args: Params, ctx: Context) -> EvalResult {
  let fn = ".int"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .IntAtom(v):
    return .Success(args[0])
  case let .FloatAtom(v):
    return .Success(.IntAtom(Int(v)))
  case let .CharAtom(v):
    // Note: this function assumes that characters being stored consist of a single Unicode code point. If the character
    //  consists of multiple code points, only the first will be cast to an integer.
    let scalars = String(v).unicodeScalars
    return .Success(.IntAtom(Int(scalars[scalars.startIndex].value)))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a number or a character"))
  }
}

/// Cast an argument to a float.
func pr_double(args: Params, ctx: Context) -> EvalResult {
  let fn = ".double"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .IntAtom(v):
    return .Success(.FloatAtom(Double(v)))
  case let .FloatAtom(v):
    return .Success(args[0])
  default:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}
