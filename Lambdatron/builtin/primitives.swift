//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/13/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a symbol or string, return a corresponding symbol.
func pr_symbol(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(args.count == 2 ? .RuntimeError("namespaces are not (yet) supported") : .ArityError)
  }
  switch args[0] {
  case .Symbol:
    return .Success(args[0])
  case let .StringLiteral(s):
    return .Success(s.isEmpty ? .NilLiteral : .Symbol(ctx.symbolForName(s)))
  default:
    return .Failure(.InvalidArgumentError)
  }
}

/// Given a symbol, string, or keyword, return a corresponding keyword; otherwise, return nil.
func pr_keyword(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(args.count == 2 ? .RuntimeError("namespaces are not (yet) supported") : .ArityError)
  }
  switch args[0] {
  case let .Symbol(s):
    let name = ctx.nameForSymbol(s)
    return .Success(.Keyword(ctx.keywordForName(name)))
  case .Keyword:
    return .Success(args[0])
  case let .StringLiteral(s):
    return .Success(s.isEmpty ? .NilLiteral : .Keyword(ctx.keywordForName(s)))
  default:
    return .Success(.NilLiteral)
  }
}

/// Cast an argument to an integer.
func pr_int(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .IntegerLiteral(v):
    return .Success(args[0])
  case let .FloatLiteral(v):
    return .Success(.IntegerLiteral(Int(v)))
  case let .CharacterLiteral(v):
    // Note: this function assumes that characters being stored consist of a single Unicode code point. If the character
    //  consists of multiple code points, only the first will be cast to an integer.
    var generator = String(v).unicodeScalars.generate()
    // FORCE UNWRAP: the string must always have at least one character, by definition
    let castValue = generator.next()!
    return .Success(.IntegerLiteral(Int(castValue.value)))
  case .None, .Symbol, .Keyword, .NilLiteral, .BoolLiteral, .StringLiteral, .ListLiteral, .VectorLiteral, .MapLiteral:
    return .Failure(.InvalidArgumentError)
  case .Special, .BuiltInFunction, .ReaderMacro, .FunctionLiteral:
    return .Failure(.InvalidArgumentError)
  }
}

/// Cast an argument to a float.
func pr_double(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .IntegerLiteral(v):
    return .Success(.FloatLiteral(Double(v)))
  case let .FloatLiteral(v):
    return .Success(args[0])
  case .CharacterLiteral:
    return .Failure(.InvalidArgumentError)
  case .None, .Symbol, .Keyword, .NilLiteral, .BoolLiteral, .StringLiteral, .ListLiteral, .VectorLiteral, .MapLiteral:
    return .Failure(.InvalidArgumentError)
  case .Special, .BuiltInFunction, .ReaderMacro, .FunctionLiteral:
    return .Failure(.InvalidArgumentError)
  }
}
