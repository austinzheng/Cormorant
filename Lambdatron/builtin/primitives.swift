//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/13/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a symbol or string, return a corresponding symbol.
func pr_symbol(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".symbol"
  if args.count != 1 && args.count != 2 {
    return .Failure(EvalError.arityError("1 or 2", actual: args.count, fn))
  }
  switch args[0] {
  case .Symbol:
    if args.count != 1 {
      return .Failure(EvalError.invalidArgumentError(fn, message: "if argument is symbol, can only have one argument"))
    }
    return .Success(args[0])
  case let .StringAtom(str):
    if args.count == 2 {
      // Qualified symbol
      let nsName = str
      if case let .StringAtom(name) = args[1] where !nsName.isEmpty {
        if name.isEmpty {
          return .Success(.Nil)
        }
        return .Success(.Symbol(InternedSymbol(name, namespace: nsName, ivs: ctx.ivs)))
      }
      else {
        return .Failure(EvalError.invalidArgumentError(fn, message: "arguments must be strings"))
      }
    }
    else {
      // Unqualified symbol
      return .Success(str.isEmpty ? .Nil : .Symbol(InternedSymbol(str, namespace: nil, ivs: ctx.ivs)))
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol or string"))
  }
}

/// Given a symbol, string, or keyword, return a corresponding keyword; otherwise, return nil.
func pr_keyword(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".keyword"
  if args.count != 1 && args.count != 2 {
    return .Failure(EvalError.arityError("1 or 2", actual: args.count, fn))
  }
  switch args[0] {
  case let .Symbol(sym):
    if args.count != 1 {
      return .Failure(EvalError.invalidArgumentError(fn, message: "if argument is symbol, can only have one argument"))
    }
    // The keyword is created directly from the symbol. It shares the symbol's name, and if the symbol is qualified,
    // also its namespace.
    return .Success(.Keyword(InternedKeyword(symbol: sym)))
  case .Keyword:
    if args.count != 1 {
      return .Failure(EvalError.invalidArgumentError(fn, message: "if argument is keyword, can only have one argument"))
    }
    return .Success(args[0])
  case let .StringAtom(str):
    if args.count == 2 {
      // Qualified keyword
      let nsName = str
      if !nsName.isEmpty, case let .StringAtom(name) = args[1] {
        if name.isEmpty {
          return .Success(.Nil)
        }
        return .Success(.Keyword(InternedKeyword(name, namespace: nsName, ivs: ctx.ivs)))
      }
      else {
        return .Failure(EvalError.invalidArgumentError(fn, message: "arguments must be strings"))
      }
    }
    else {
      // Unqualified keyword
      return .Success(str.isEmpty ? .Nil : .Keyword(InternedKeyword(str, namespace: nil, ivs: ctx.ivs)))
    }
  default:
    return .Success(.Nil)
  }
}

/// Return the namespace string of a symbol or keyword, or nil if not present.
func pr_namespace(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".namespace"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .Symbol(sym):
    if let ns = sym.ns {
      return .Success(.StringAtom(ns.asString(ctx.ivs)))
    }
    return .Success(.Nil)
  case let .Keyword(keyword):
    if let ns = keyword.ns {
      return .Success(.StringAtom(ns.asString(ctx.ivs)))
    }
    return .Success(.Nil)
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol or a keyword"))
  }
}

/// Cast an argument to an integer.
func pr_int(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".int"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case .IntAtom:
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
func pr_double(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".double"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .IntAtom(v):
    return .Success(.FloatAtom(Double(v)))
  case .FloatAtom:
    return .Success(args[0])
  default:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}
