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
  let compareResult : BoolOrEvalError = args[0] == args[1]
  switch compareResult {
  case let .Boolean(b): return .Success(.BoolAtom(b))
  case let .Error(err): return .Failure(err)
  }
}

/// Given a Var (and in the future, an Atom), return the value actually stored inside.
func pr_deref(args: Params, ctx: Context) -> EvalResult {
  let fn = ".deref"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch args[0] {
  case let .Var(aVar):
    return .Success(aVar.value(usingContext: ctx))
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a Var"))
  }
}

/// Read in a string from the host interpreter's readInput function, and then expand it into a Lambdatron form.
func pr_read(args: Params, ctx: Context) -> EvalResult {
  let fn = ".read"
  if args.count != 0 {
    return .Failure(EvalError.runtimeError(fn, message: "Custom readers are not supported"))
  }
  let readFn = ctx.interpreter.readInput
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
  if let string = string.asString {
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

/// Generate a unique symbol, intern it, and return it.
func pr_gensym(args: Params, ctx: Context) -> EvalResult {
  let fn = ".gensym"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  // Note that calling this function with keywords can generate symbols that look exactly like keywords (prefixed by
  //  ":").
  let prefix = args[0].toString(ctx)
  switch prefix {
  case let .Desc(prefix):
    let gensym = ctx.ivs.produceGensym(prefix, suffix: nil)
    return .Success(.Symbol(gensym))
  case let .Error(err):
    return .Failure(err)
  }
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
  let message = args.first?.asString ?? "(fail was called)"
  return .Failure(EvalError.runtimeError(fn, message: message))
}


// MARK: Private helpers

/// Given a string and a context, lex, parse, and reader-expand the string into a Lambdatron data structure.
private func readString(string: String, ctx: Context, fn: String) -> EvalResult {
  // Lex and parse the string
  let lexed = lex(string)
  switch lexed {
  case let .Success(lexed):
    let parsed = parse(lexed, ctx)
    switch parsed {
    case let .Success(parsed):
      let expanded = parsed.expand(ctx)
      switch expanded {
      case let .Success(expanded):
        return .Success(expanded)
      case let .Failure(err): return .Failure(EvalError.readError(forFn: fn, error: err))
      }
    case let .Failure(err): return .Failure(EvalError.readError(forFn: fn, error: err))
    }
  case let .Failure(err): return .Failure(EvalError.readError(forFn: fn, error: err))
  }
}

/// Print zero or more args to screen, either with or without a trailing newline.
private func printOrPrintln(args: Params, ctx: Context, isPrintln: Bool) -> EvalResult {
  var descs : [String] = []
  for arg in args {
    if let str = arg.asString {
      // Strings are used as-is
      descs.append(str)
    }
    else {
      // Everything else is described. If a lazy-seq is involved, we need to guard agains failure.
      switch arg.describe(ctx) {
      case let .Desc(desc): descs.append(desc)
      case let .Error(err): return .Failure(err)
      }
    }
  }
  let outStr = descs.count > 0 ? join(" ", descs) : ""
  ctx.interpreter.writeOutput?(isPrintln ? outStr + "\n" : outStr)
  return .Success(.Nil)
}
