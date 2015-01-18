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
  ctx.writeOutput?(outStr)
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
