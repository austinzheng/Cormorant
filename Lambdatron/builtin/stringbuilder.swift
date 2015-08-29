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
  if args.count > 1 {
    return .Failure(EvalError.arityError("0 or 1", actual: args.count, fn))
  }
  if args.count == 0 {
    return .Success(.Auxiliary(StringBuilderType()))
  }
  let result = args[0].toString(ctx)
  switch result {
  case let .Just(desc): return .Success(.Auxiliary(StringBuilderType(desc)))
  case let .Error(err): return .Failure(err)
  }
}

/// Given a string builder and some value, append that value to the string builder's buffer.
func sb_append(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".sb-append"
  if args.count != 2 {
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
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  guard case let .Auxiliary(builder as StringBuilderType) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string builder"))
  }
  builder.reverse()
  return .Success(args[0])
}
