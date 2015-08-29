//
//  regex.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a string or a regular expression pattern, build and return a corresponding regular expression pattern.
func re_pattern(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-pattern"
  if args.count > 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let pattern = args[0]
  switch pattern {
  case let .StringAtom(string):
    switch constructRegex(string) {
    case let .Success(regex): return .Success(.Auxiliary(regex))
    case let .Error(err): return .Failure(EvalError.readError(forFn: fn, error: err))
    }
  case let .Auxiliary(aux) where aux is NSRegularExpression:
    return .Success(pattern)
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string or regex pattern"))
  }
}

/// Given a regex pattern and a string, return the first match and groups (if any), otherwise nil.
func re_first(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-first"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  if let pattern = args[0].asRegexPattern {
    if let str = args[1].asString {
      // Do a search
      let utf16Str = str as NSString
      let result = pattern.firstMatchInString(str, options: [], range: NSRange(location: 0, length: utf16Str.length))
      if let result = result {
        if result.numberOfRanges == 0 {
          return .Success(.Nil)
        }
        else if result.numberOfRanges == 1 {
          // First match is always the raw match (without any capture groups)
          return .Success(.StringAtom(utf16Str.substringWithRange(result.rangeAtIndex(0))))
        }
        else {
          // Multiple matches, build a vector
          var buffer : [ConsValue] = []
          for i in 0..<result.numberOfRanges {
            let thisRange = result.rangeAtIndex(i)
            if rangeIsValid(thisRange) {
              buffer.append(.StringAtom(utf16Str.substringWithRange(thisRange)))
            }
          }
          return .Success(.Vector(buffer))
        }
      }
      // No matches
      return .Success(.Nil)
    }
    else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be a string"))
    }
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a regex pattern"))
}

/// Given a regex pattern and a string, return a sequence of all matches and groups (if any), otherwise nil.
func re_seq(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-seq"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  if let pattern = args[0].asRegexPattern {
    if let str = args[1].asString {
      let utf16Str = str as NSString
      var resultBuffer : [ConsValue] = []

      pattern.enumerateMatchesInString(str, options: [], range: NSRange(location: 0, length: str.utf16.count)) {
        (result: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
        guard let result = result else {
          // TODO: (az) need to do more here?
          return
        }
        // Create a vector of the results, then pass it in
        var buffer : [ConsValue] = []
        for i in 0..<result.numberOfRanges {
          let thisRange = result.rangeAtIndex(i)
          if rangeIsValid(thisRange) {
            buffer.append(.StringAtom(utf16Str.substringWithRange(thisRange)))
          }
        }
        if buffer.count > 0 {
          resultBuffer.append(.Vector(buffer))
        }
      }
      return .Success(.Seq(sequence(resultBuffer)))
    }
    else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be a string"))
    }
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a regex pattern"))
}

/// Given a regex pattern, a string, and a function, call the function once for each match in the string.
func re_iterate(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-iterate"
  if args.count != 3 {
    return .Failure(EvalError.arityError("3", actual: args.count, fn))
  }
  if let pattern = args[0].asRegexPattern {
    if let str = args[1].asString {
      let utf16Str = str as NSString
      let function = args[2]
      var error: EvalError? = nil

      pattern.enumerateMatchesInString(str, options: [], range: NSRange(location: 0, length: str.utf16.count)) {
        (result: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
        guard let result = result else {
          // TODO: (az) more to do here?
          return
        }
        // Create a vector of the results, then pass it in
        var buffer : [ConsValue] = []
        var ranges : [ConsValue] = []
        for i in 0..<result.numberOfRanges {
          let thisRange = result.rangeAtIndex(i)
          if rangeIsValid(thisRange) {
            buffer.append(.StringAtom(utf16Str.substringWithRange(thisRange)))
            ranges.append(.Vector([.IntAtom(thisRange.location), .IntAtom(thisRange.length)]))
          }
        }
        // Call the user-defined function with two arguments: a vector of the result strings, and a vector of the
        //  corresponding ranges. However, if there are *no* match groups, the arguments are just the match string, and
        //  just the range vector.
        let nextResult = apply(function,
          args: Params(buffer.count == 1 ? buffer[0] : .Vector(buffer), ranges.count == 1 ? ranges[0] : .Vector(ranges)),
          ctx: ctx,
          fn: fn)
        // The result determines whether we continue or stop early. Either a failure or the function returning a Boolean
        //  true will stop the enumeration.
        switch nextResult {
        case let .Success(s):
          if s.asBool == true {
            stop.memory = true
          }
        case .Recur:
          error = EvalError(.RecurMisuseError, fn)
          stop.memory = true
        case let .Failure(err):
          error = err
          stop.memory = true
        }
      }
      if let error = error {
        return .Failure(error)
      }
      return .Success(.Nil)
    }
    else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be a string"))
    }
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a regex pattern"))
}

/// Given a string, return an escaped version suitable for use as a template.
func re_quoteReplacement(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-quote-replacement"
  if args.count != 1 {
    return .Failure(EvalError.arityError("3", actual: args.count, fn))
  }
  if let str = args[0].asString {
    return .Success(.StringAtom(NSRegularExpression.escapedTemplateForString(str)))
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
}
