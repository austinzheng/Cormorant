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

/// Read in a string from the host interpreter's readInput function, and then expand it into a Lambdatron form.
func pr_read(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 0 {
    return .Failure(.RuntimeError("Custom readers are not supported."))
  }
  let readFn = ctx.readInput
  if let readFn = readFn {
    let str = readFn()
    return readString(str, ctx)
  }
  // If no reader is defined, just return nil
  return .Success(.NilLiteral)
}

/// Given a string as an argument, read and expand it into a Lambdatron form.
func pr_readString(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let string = args[0]
  if let string = string.asStringLiteral() {
    return readString(string, ctx)
  }
  // Must pass in a string
  return .Failure(.InvalidArgumentError)
}

/// Print zero or more args to screen. Returns nil.
func pr_print(args: [ConsValue], ctx: Context) -> EvalResult {
  return printOrPrintln(args, ctx, false)
}

/// Print zero or more args to screen, followed by a trailing newline. Returns nil.
func pr_println(args: [ConsValue], ctx: Context) -> EvalResult {
  return printOrPrintln(args, ctx, true)
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

/// Given a string and a context, lex, parse, and reader-expand the string into a Lambdatron data structure.
private func readString(string: String, ctx: Context) -> EvalResult {
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
      case .Failure: return .Failure(.ReadError)
      }
    case .Failure: return .Failure(.ReadError)
    }
  case .Failure: return .Failure(.ReadError)
  }
}

/// Print zero or more args to screen, either with or without a trailing newline.
private func printOrPrintln(args: [ConsValue], ctx: Context, isPrintln: Bool) -> EvalResult {
  func toString(v: ConsValue) -> String {
    switch v {
    case let .StringLiteral(s): return s
    default: return v.describe(ctx)
    }
  }
  let descs = args.map(toString)
  let outStr = descs.count > 0 ? join(" ", descs) : ""
  ctx.writeOutput?(isPrintln ? outStr + "\n" : outStr)
  return .Success(.NilLiteral)
}
