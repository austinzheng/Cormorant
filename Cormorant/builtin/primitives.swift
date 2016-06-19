//
//  primitives.swift
//  Cormorant
//
//  Created by Austin Zheng on 1/13/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a symbol or string, return a corresponding symbol.
func pr_symbol(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".symbol"
  guard args.count == 1 || args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "1 or 2", actual: args.count, fn))
  }
  switch args[0] {
  case .symbol:
    guard args.count == 1 else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "if argument is symbol, can only have one argument"))
    }
    return .Success(args[0])
  case let .string(str):
    if args.count == 2 {
      // Qualified symbol
      let nsName = str
      guard !nsName.isEmpty, case let .string(name) = args[1] else {
        return .Failure(EvalError.invalidArgumentError(fn, message: "arguments must be strings"))
      }
      return .Success(name.isEmpty ? .nilValue : .symbol(InternedSymbol(name, namespace: nsName, ivs: ctx.ivs)))
    }
    else {
      // Unqualified symbol
      return .Success(str.isEmpty ? .nilValue : .symbol(InternedSymbol(str, namespace: nil, ivs: ctx.ivs)))
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol or string"))
  }
}

/// Given a symbol, string, or keyword, return a corresponding keyword; otherwise, return nil.
func pr_keyword(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".keyword"
  guard args.count == 1 || args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "1 or 2", actual: args.count, fn))
  }
  switch args[0] {
  case let .symbol(sym):
    guard args.count == 1 else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "if argument is symbol, can only have one argument"))
    }
    // The keyword is created directly from the symbol. It shares the symbol's name, and if the symbol is qualified,
    // also its namespace.
    return .Success(.keyword(InternedKeyword(symbol: sym)))
  case .keyword:
    guard args.count == 1 else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "if argument is keyword, can only have one argument"))
    }
    return .Success(args[0])
  case let .string(str):
    if args.count == 2 {
      // Qualified keyword
      let nsName = str
      guard !nsName.isEmpty, case let .string(name) = args[1] else {
        return .Failure(EvalError.invalidArgumentError(fn, message: "arguments must be strings"))
      }
      return .Success(name.isEmpty ? .nilValue : .keyword(InternedKeyword(name, namespace: nsName, ivs: ctx.ivs)))
    }
    else {
      // Unqualified keyword
      return .Success(str.isEmpty ? .nilValue : .keyword(InternedKeyword(str, namespace: nil, ivs: ctx.ivs)))
    }
  default:
    return .Success(.nilValue)
  }
}

/// Return the namespace string of a symbol or keyword, or nil if not present.
func pr_namespace(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".namespace"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  switch args[0] {
  case let .symbol(sym):
    if let ns = sym.ns {
      return .Success(.string(ns.asString(ctx.ivs)))
    }
    return .Success(.nilValue)
  case let .keyword(keyword):
    if let ns = keyword.ns {
      return .Success(.string(ns.asString(ctx.ivs)))
    }
    return .Success(.nilValue)
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol or a keyword"))
  }
}

/// Cast an argument to an integer.
func pr_int(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".int"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  switch args[0] {
  case .int:
    return .Success(args[0])
  case let .float(v):
    return .Success(.int(Int(v)))
  case let .char(v):
    // Note: this function assumes that characters being stored consist of a single Unicode code point. If the character
    //  consists of multiple code points, only the first will be cast to an integer.
    let scalars = String(v).unicodeScalars
    return .Success(.int(Int(scalars[scalars.startIndex].value)))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "argument must be a number or a character"))
  }
}

/// Cast an argument to a float.
func pr_double(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".double"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  switch args[0] {
  case let .int(v):
    return .Success(.float(Double(v)))
  case .float:
    return .Success(args[0])
  default:
    return .Failure(EvalError.nonNumericArgumentError(fn))
  }
}
