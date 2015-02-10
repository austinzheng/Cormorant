//
//  miscellaneous.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Evaluate the equality of one or more forms.
func pr_equals(args: Params, ctx: Context) -> EvalResult {
  let fn = ".="
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  return .Success(.BoolAtom(args[0] == args[1]))
}

/// Read in a string from the host interpreter's readInput function, and then expand it into a Lambdatron form.
func pr_read(args: Params, ctx: Context) -> EvalResult {
  let fn = ".read"
  if args.count != 0 {
    return .Failure(EvalError.runtimeError(fn, message: "Custom readers are not supported"))
  }
  let readFn = ctx.readInput
  if let readFn = readFn {
    let str = readFn()
    return readString(str, ctx, fn)
  }
  // If no reader is defined, just return nil
  return .Success(.Nil)
}

/// Given a string as an argument, read and expand it into a Lambdatron form.
func pr_readString(args: Params, ctx: Context) -> EvalResult {
  let fn = ".read-string"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let string = args[0]
  if let string = string.asString() {
    return readString(string, ctx, fn)
  }
  // Must pass in a string
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
}

/// Print zero or more args to screen. Returns nil.
func pr_print(args: Params, ctx: Context) -> EvalResult {
  return printOrPrintln(args, ctx, false)
}

/// Print zero or more args to screen, followed by a trailing newline. Returns nil.
func pr_println(args: Params, ctx: Context) -> EvalResult {
  return printOrPrintln(args, ctx, true)
}

/// Return a random number between 0 (inclusive) and 1 (exclusive).
func pr_rand(args: Params, ctx: Context) -> EvalResult {
  let fn = ".rand"
  if args.count != 0 {
    return .Failure(EvalError.arityError("> 0", actual: args.count, fn))
  }
  let randomNumber = Double(arc4random_uniform(UInt32.max - 1))
  return .Success(.FloatAtom(randomNumber / Double(UInt32.max)))
}

/// Evaluate a given form and return the result.
func pr_eval(args: Params, ctx: Context) -> EvalResult {
  let fn = ".eval"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  return args[0].evaluate(ctx)
}

/// Force a failure. Call with zero arguments or a string containing an error message.
func pr_fail(args: Params, ctx: Context) -> EvalResult {
  let fn = ".fail"
  let message = args.first?.asString() ?? "(fail was called)"
  return .Failure(EvalError.runtimeError(fn, message: message))
}

/// Given a string and a context, lex, parse, and reader-expand the string into a Lambdatron data structure.
private func readString(string: String, ctx: Context, fn: String) -> EvalResult {
  // Lex and parse the string
  let lexed = lex(string)
  switch lexed {
  case let .Success(lexed):
    let parsed = parse(lexed, ctx)
    switch parsed {
    case let .Success(parsed):
      let expanded = parsed.readerExpand()
      switch expanded {
      case let .Success(expanded):
        return .Success(expanded)
      case .Failure: return .Failure(EvalError(.ReadError, fn))
      }
    case .Failure: return .Failure(EvalError(.ReadError, fn))
    }
  case .Failure: return .Failure(EvalError(.ReadError, fn))
  }
}

/// Print zero or more args to screen, either with or without a trailing newline.
private func printOrPrintln(args: Params, ctx: Context, isPrintln: Bool) -> EvalResult {
  func toString(v: ConsValue) -> String {
    switch v {
    case let .StringAtom(s): return s
    default: return v.describe(ctx)
    }
  }
  let descs = map(args, toString)
  let outStr = descs.count > 0 ? join(" ", descs) : ""
  ctx.writeOutput?(isPrintln ? outStr + "\n" : outStr)
  return .Success(.Nil)
}
