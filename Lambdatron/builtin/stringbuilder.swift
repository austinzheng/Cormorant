//
//  stringbuilder.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Return a new string builder, initialized with the contents of the argument (if any).
func sb_sb(args: Params, ctx: Context) -> EvalResult {
  let fn = ".sb"
  if args.count > 1 {
    return .Failure(EvalError.arityError("0 or 1", actual: args.count, fn))
  }
  return .Success(.Auxiliary(args.count == 0 ? StringBuilderType() : StringBuilderType(args[0].toString(ctx))))
}

/// Given a string builder and some value, append that value to the string builder's buffer.
func sb_append(args: Params, ctx: Context) -> EvalResult {
  let fn = ".sb-append"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  if let builder = args[0].asStringBuilder {
    builder.append(args[1].toString(ctx))
    return .Success(args[0])
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string builder"))
}

/// Given a string builder, reverse the characters in the string builder in-place.
func sb_reverse(args: Params, ctx: Context) -> EvalResult {
  let fn = ".sb-reverse"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  if let builder = args[0].asStringBuilder {
    builder.reverse()
    return .Success(args[0])
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string builder"))
}
