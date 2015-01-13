//
//  miscellaneous.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Evaluate the equality of one or more forms.
func pr_equals(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  return .Success(.BoolLiteral(args[0] == args[1]))
}

/// Cast an argument to an integer.
func pr_toInt(args: [ConsValue], ctx: Context) -> EvalResult {
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
    let castValue : UnicodeScalar = {
      for scalar in String(v).unicodeScalars {
        return scalar
      }
      internalError("Control flow should never reach here...")
    }()
    return .Success(.IntegerLiteral(Int(castValue.value)))
  case .None, .Symbol, .Keyword, .NilLiteral, .BoolLiteral, .StringLiteral, .ListLiteral, .VectorLiteral, .MapLiteral:
    return .Failure(.InvalidArgumentError)
  case .Special, .BuiltInFunction, .ReaderMacro, .FunctionLiteral, .RecurSentinel:
    return .Failure(.InvalidArgumentError)
  }
}

/// Cast an argument to a float.
func pr_toDouble(args: [ConsValue], ctx: Context) -> EvalResult {
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
  case .Special, .BuiltInFunction, .ReaderMacro, .FunctionLiteral, .RecurSentinel:
    return .Failure(.InvalidArgumentError)
  }
}

/// Print zero or more args to screen. Returns nil.
func pr_print(args: [ConsValue], ctx: Context) -> EvalResult {
  func toString(v: ConsValue) -> String {
    switch v {
    case let .StringLiteral(s): return s
    default: return v.describe(ctx)
    }
  }
  let descs = args.map(toString)
  let outStr = descs.count > 0 ? join(" ", descs) : ""
  print(outStr)
  return .Success(.NilLiteral)
}

/// Evaluate a given form and return the result.
func pr_eval(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  return args[0].evaluate(ctx)
}

/// Force a failure. Call with zero arguments or a string containing an error message.
func pr_fail(args: [ConsValue], ctx: Context) -> EvalResult {
  return .Failure(.RuntimeError(args.count > 0 ? args[0].asStringLiteral() : nil))
}
