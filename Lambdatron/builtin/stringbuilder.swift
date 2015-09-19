//
//  stringbuilder.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Return a new string builder, initialized with the contents of the argument (if any).
func sb_sb(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".sb"
  guard args.isEmpty || args.count == 1 else {
    return .Failure(EvalError.arityError("0 or 1", actual: args.count, fn))
  }
  return args.isEmpty
    ? .Success(.Auxiliary(StringBuilderType()))
    : args[0].toString(ctx).then { .Success(.Auxiliary(StringBuilderType($0))) }
}

/// Given a string builder and some value, append that value to the string builder's buffer.
func sb_append(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".sb-append"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  guard case let .Auxiliary(builder as StringBuilderType) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string builder"))
  }
  return args[1].toString(ctx).then { desc in
    builder.append(desc)
    return .Success(args[0])
  }
}

/// Given a string builder, reverse the characters in the string builder in-place.
func sb_reverse(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".sb-reverse"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  guard case let .Auxiliary(builder as StringBuilderType) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string builder"))
  }
  builder.reverse()
  return .Success(args[0])
}
