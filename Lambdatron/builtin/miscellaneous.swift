//
//  miscellaneous.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/15/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// Evaluate the equality of one or more forms.
func pr_equals(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".="
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  return args[0].equals(args[1]).then { .Success(.bool($0)) }
}

/// Given a Var (and in the future, an Atom), return the value actually stored inside.
func pr_deref(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".deref"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  switch args[0] {
  case let .`var`(aVar):
    return .Success(aVar.value(usingContext: ctx))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a Var"))
  }
}

/// Read in a string from the host interpreter's readInput function, and then expand it into a Lambdatron form.
func pr_read(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".read"
  guard args.isEmpty else {
    return .Failure(EvalError.runtimeError(fn, message: "Custom readers are not supported"))
  }
  let readFn = ctx.interpreter.readInput
  if let readFn = readFn {
    let str = readFn()
    return read(string: str, ctx, fn)
  }
  // If no reader is defined, just return nil
  return .Success(.nilValue)
}

/// Given a string as an argument, read and expand it into a Lambdatron form.
func pr_readString(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".read-string"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  guard case let .string(string) = args[0] else {
    // Must pass in a string
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
  }
  return read(string: string, ctx, fn)
}

/// Print zero or more args to screen. Returns nil.
func pr_print(args: Params, _ ctx: Context) -> EvalResult {
  return printOrPrintln(args, ctx: ctx, isPrintln: false)
}

/// Print zero or more args to screen, followed by a trailing newline. Returns nil.
func pr_println(args: Params, _ ctx: Context) -> EvalResult {
  return printOrPrintln(args, ctx: ctx, isPrintln: true)
}

/// Generate a unique symbol, intern it, and return it.
func pr_gensym(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".gensym"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  // Note that calling this function with keywords can generate symbols that look exactly like keywords (prefixed by
  //  ":").
  return args[0].toString(ctx).then { .Success(.symbol(ctx.ivs.produceGensym(prefix: $0, suffix: nil))) }
}

/// Return a random number between 0 (inclusive) and 1 (exclusive).
func pr_rand(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".rand"
  guard args.isEmpty else {
    return .Failure(EvalError.arityError(expected: "0", actual: args.count, fn))
  }
  let randomNumber = Double(arc4random_uniform(UInt32.max - 1))
  return .Success(.float(randomNumber / Double(UInt32.max)))
}

/// Evaluate a given form and return the result.
func pr_eval(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".eval"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  return ctx.evaluate(value: args[0])
}

/// Force a failure. Call with zero arguments or a string containing an error message.
func pr_fail(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".fail"
  let message : String
  if case let .string(m)? = args.first {
    message = m
  } else {
    message = "(fail was called)"
  }
  return .Failure(EvalError.runtimeError(fn, message: message))
}


// MARK: Private helpers

/// Given a string and a context, lex, parse, and reader-expand the string into a Lambdatron data structure.
private func read(string: String, _ ctx: Context, _ fn: String) -> EvalResult {
  // Lex and parse the string
  let lexed = lex(string)
  switch lexed {
  case let .Just(lexed):
    let parsed = parse(tokens: lexed, ctx)
    switch parsed {
    case let .Just(parsed):
      let expanded = ctx.expand(parsed)
      switch expanded {
      case let .Success(expanded):
        return .Success(expanded)
      case let .Failure(err): return .Failure(EvalError.readError(forFn: fn, error: err))
      }
    case let .Error(err): return .Failure(EvalError.readError(forFn: fn, error: err))
    }
  case let .Error(err): return .Failure(EvalError.readError(forFn: fn, error: err))
  }
}

/// Print zero or more args to screen, either with or without a trailing newline.
private func printOrPrintln(_ args: Params, ctx: Context, isPrintln: Bool) -> EvalResult {
  var descs : [String] = []
  for arg in args {
    if case let .string(str) = arg {
      // Strings are used as-is
      descs.append(str)
    }
    else {
      // Everything else is described. If a lazy-seq is involved, we need to guard agains failure.
      switch arg.describe(ctx) {
      case let .Just(desc): descs.append(desc)
      case let .Error(err): return .Failure(err)
      }
    }
  }
  let outStr = descs.count > 0 ? descs.joined(separator: " ") : ""
  ctx.interpreter.writeOutput?(isPrintln ? outStr + "\n" : outStr)
  return .Success(.nilValue)
}
