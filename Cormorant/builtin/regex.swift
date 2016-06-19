//
//  regex.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/14/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a string or a regular expression pattern, build and return a corresponding regular expression pattern.
func re_pattern(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-pattern"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  let pattern = args[0]
  switch pattern {
  case let .string(string):
    return constructRegex(string).then(fn) { .Success(.auxiliary($0)) }
  case .auxiliary(_ as RegularExpressionType):
    return .Success(pattern)
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string or regex pattern"))
  }
}

/// Given a regex pattern and a string, return the first match and groups (if any), otherwise nil.
func re_first(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-first"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  guard case let .auxiliary(pattern as RegularExpressionType) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a regex pattern"))
  }
  guard case let .string(str) = args[1] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be a string"))
  }
  // Do a search
  let utf16Str = str as NSString
  let result = pattern.firstMatch(in: str, options: [], range: NSRange(location: 0, length: utf16Str.length))
  if let result = result {
    if result.numberOfRanges == 0 {
      return .Success(.nilValue)
    }
    else if result.numberOfRanges == 1 {
      // First match is always the raw match (without any capture groups)
      return .Success(.string(utf16Str.substring(with: result.range(at: 0))))
    }
    else {
      // Multiple matches, build a vector
      var buffer : [Value] = []
      for i in 0..<result.numberOfRanges {
        let thisRange = result.range(at: i)
        if rangeIsValid(thisRange) {
          buffer.append(.string(utf16Str.substring(with: thisRange)))
        }
      }
      return .Success(.vector(buffer))
    }
  }
  // No matches
  return .Success(.nilValue)
}

/// Given a regex pattern and a string, return a sequence of all matches and groups (if any), otherwise nil.
func re_seq(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-seq"
  guard args.count == 2 else {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  guard case let .auxiliary(pattern as RegularExpressionType) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a regex pattern"))
  }
  guard case let .string(str) = args[1] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be a string"))
  }
  let utf16Str = str as NSString
  var resultBuffer : [Value] = []

  pattern.enumerateMatches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count)) {
    (result: TextCheckingResult?, flags: RegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
    guard let result = result else {
      // TODO: (az) need to do more here?
      return
    }
    // Create a vector of the results, then pass it in
    var buffer : [Value] = []
    for i in 0..<result.numberOfRanges {
      let thisRange = result.range(at: i)
      if rangeIsValid(thisRange) {
        buffer.append(.string(utf16Str.substring(with: thisRange)))
      }
    }
    if buffer.count > 0 {
      resultBuffer.append(.vector(buffer))
    }
  }
  return .Success(.seq(sequence(fromItems: resultBuffer)))
}

/// Given a regex pattern, a string, and a function, call the function once for each match in the string.
func re_iterate(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-iterate"
  guard args.count == 3 else {
    return .Failure(EvalError.arityError(expected: "3", actual: args.count, fn))
  }
  guard case let .auxiliary(pattern as RegularExpressionType) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a regex pattern"))
  }
  guard case let .string(str) = args[1] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be a string"))
  }
  let utf16Str = str as NSString
  let function = args[2]
  var error: EvalError? = nil

  pattern.enumerateMatches(in: str, options: [], range: NSRange(location: 0, length: str.utf16.count)) {
    (result: TextCheckingResult?, flags: RegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
    guard let result = result else {
      // TODO: (az) more to do here?
      return
    }
    // Create a vector of the results, then pass it in
    var buffer : [Value] = []
    var ranges : [Value] = []
    for i in 0..<result.numberOfRanges {
      let thisRange = result.range(at: i)
      if rangeIsValid(thisRange) {
        buffer.append(.string(utf16Str.substring(with: thisRange)))
        ranges.append(.vector([.int(thisRange.location), .int(thisRange.length)]))
      }
    }
    // Call the user-defined function with two arguments: a vector of the result strings, and a vector of the
    //  corresponding ranges. However, if there are *no* match groups, the arguments are just the match string, and
    //  just the range vector.
    let args = Params(buffer.count == 1 ? buffer[0] : .vector(buffer), ranges.count == 1 ? ranges[0] : .vector(ranges))
    let nextResult = ctx.apply(arguments: args, toFunction: function, fn)
    // The result determines whether we continue or stop early. Either a failure or the function returning a Boolean
    //  true will stop the enumeration.
    switch nextResult {
    case let .Success(s):
      if case let .bool(s) = s where s {
        stop.pointee = true
      }
    case .Recur:
      error = EvalError(.RecurMisuseError, fn)
      stop.pointee = true
    case let .Failure(err):
      error = err
      stop.pointee = true
    }
  }
  if let error = error {
    return .Failure(error)
  }
  return .Success(.nilValue)
}

/// Given a string, return an escaped version suitable for use as a template.
func re_quoteReplacement(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".re-quote-replacement"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  if case let .string(str) = args[0] {
    return .Success(.string(RegularExpressionType.escapedTemplate(for: str)))
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
}
