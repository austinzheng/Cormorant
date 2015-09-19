//
//  strings.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/18/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given zero or more objects, return the stringified version of the object(s), concatenating as necessary.
func str_str(args: Params, _ ctx: Context) -> EvalResult {
//  let fn = ".str"
  if args.count == 0 {
    return .Success(.StringAtom(""))
  }
  var buffer : [String] = []
  for arg in args {
    let result = arg.toString(ctx)
    switch result {
    case let .Just(desc): buffer.append(desc)
    case let .Error(err): return .Failure(err)
    }
  }
  let result = buffer.joinWithSeparator("")
  return .Success(.StringAtom(result))
}

/// Given a string, a start index, and an optional end index, return a substring.
func str_subs(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".subs"
  guard args.count == 2 || args.count == 3 else {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }
  guard case let .StringAtom(theString) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
  }
  guard let start = args[1].extractInt() else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be numeric"))
  }
  // Use the UTF16 view, since that facilitates indexing into the string using integers (i.e. Clojure's behavior)
  let utf16Str = theString as NSString
  // TODO: Maybe this should really be Unicode-safe.
  if args.count == 2 {
    // Start index only
    return (start < utf16Str.length
      ? .Success(.StringAtom(utf16Str.substringFromIndex(start)))
      : .Failure(EvalError.outOfBoundsError(fn, idx: start)))
  }
  else {
    guard let end = args[2].extractInt() else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "third argument must be numeric"))
    }
    // Start and end indices
    return (start <= utf16Str.length
      ? (end <= utf16Str.length && !(end < start)
        ? .Success(.StringAtom(utf16Str.substringWithRange(NSMakeRange(start, end - start))))
        : .Failure(EvalError.outOfBoundsError(fn, idx: end)))
      : .Failure(EvalError.outOfBoundsError(fn, idx: start)))
  }
}

/// Given any type of object, return an equivalent string but with all letters in uppercase.
func str_uppercase(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".upper-case"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  return args[0].toString(ctx).then { .Success(.StringAtom($0.uppercaseString)) }
}

/// Given any type of object, return an equivalent string but with all letters in lowercase.
func str_lowercase(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".upper-case"
  guard args.count == 1 else {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  return args[0].toString(ctx).then { .Success(.StringAtom($0.lowercaseString)) }
}

/// Given a string, a match object, and a replacement object, replace all occurrences of the match in the string.
func str_replace(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".replace"
  return replace(args, ctx: ctx, fn: fn, firstOnly: false)
}

/// Given a string, a match object, and a replacement object, replace the first occurrence of the match in the string.
func str_replaceFirst(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".replace-first"
  return replace(args, ctx: ctx, fn: fn, firstOnly: true)
}


// MARK: Private helpers

private func replace(args: Params, ctx: Context, fn: String, firstOnly: Bool) -> EvalResult {
  guard args.count == 3 else {
    return .Failure(EvalError.arityError("3", actual: args.count, fn))
  }
  guard case let .StringAtom(theString) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
  }

  let match = args[1]
  let replacement = args[2]
  switch (match, replacement) {
  case let (.StringAtom(match), .StringAtom(replacement)):
    // Replace all occurrences of the match string with the replacement string
    return replaceWithString(theString, m: match, replacement: replacement, firstOnly: firstOnly, fn: fn)
  case let (.CharAtom(match), .CharAtom(replacement)):
    // Replace all occurrences of the match character with the replacement character
    return replaceWithString(theString, m: String(match), replacement: String(replacement), firstOnly: firstOnly, fn: fn)
  case let (.Auxiliary(match as RegularExpressionType), _):
    // Replace all occurrences of the match regex with either a template string or a transformer function
    switch replacement {
    case let .StringAtom(replacement):
      // The replacement argument is a template string
      let newStr = replaceWithTemplate(theString, m: match, template: replacement, firstOnly: firstOnly, fn: fn)
      return .Success(.StringAtom(newStr))
    default:
      // The replacement argument will be treated as a function that takes in match results and returns a string
      return replaceWithFunction(theString, match: match, function: replacement, firstOnly: firstOnly, fn: fn, ctx: ctx)
    }
  case (.StringAtom, _):
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "if the match is a string, the replacement must also be a string"))
  case (.CharAtom, _):
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "if the match is a character, the replacement must also be a character"))
  case (.Auxiliary, _):
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "second argument must be a string, character, or regex pattern"))
  default:
    return .Failure(EvalError.invalidArgumentError(fn,
      message: "second argument must be a string, character, or regex pattern"))
  }
}

private func replaceWithString(s: String, m: String, replacement: String, firstOnly: Bool, fn: String) -> EvalResult {
  let match = RegularExpressionType.escapedPatternForString(m)
  let template = RegularExpressionType.escapedTemplateForString(replacement)
  switch constructRegex(match) {
  case let .Just(regex):
    let stringRange = NSRange(location: 0, length: s.utf16.count)
    let searchRange = firstOnly ? regex.rangeOfFirstMatchInString(s, options: [], range: stringRange) : stringRange
    let newStr = (rangeIsValid(searchRange)
      ? regex.stringByReplacingMatchesInString(s, options: [], range: searchRange, withTemplate: template)
      : s)
    return .Success(.StringAtom(newStr))
  case let .Error(err):
    return .Failure(EvalError.readError(forFn: fn, error: err))
  }
}

private func replaceWithTemplate(s: String, m: RegularExpressionType, template: String, firstOnly: Bool, fn: String) -> String {
  let stringRange = NSRange(location: 0, length: s.utf16.count)
  let searchRange = firstOnly ? m.rangeOfFirstMatchInString(s, options: [], range: stringRange) : stringRange
  return (rangeIsValid(searchRange)
    ? m.stringByReplacingMatchesInString(s, options: [], range: searchRange, withTemplate: template)
    : s)
}

private func replaceWithFunction(s: String, match: RegularExpressionType, function: Value, firstOnly: Bool, fn: String, ctx: Context) -> EvalResult {
  // Handle the case where the match is a regex and the replacement is defined by a function
  let utf16Str = s as NSString

  var error : EvalError?
  var deltaBuffer : [(String, NSRange)] = []

  match.enumerateMatchesInString(s, options: [], range: NSRange(location: 0, length: utf16Str.length)) {
    (result: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
    guard let result = result else {
      // TODO: (az) do more here?
      return
    }
    // Create a vector of the results
    var shouldStop = firstOnly
    var buffer : [Value] = []
    for i in 0..<result.numberOfRanges {
      let thisRange = result.rangeAtIndex(i)
      if rangeIsValid(thisRange) {
        buffer.append(.StringAtom(utf16Str.substringWithRange(thisRange)))
      }
    }
    // Pass the match results to the function so that it can produce a replacement string
    // Note that if there aren't any match groups, the function gets the string; if there are match groups, the function
    //  gets a vector of strings (with the first being the match, and the rest being each matched group).
    let fnResult = apply(function, args: Params(buffer.count == 1 ? buffer[0] : .Vector(buffer)), ctx: ctx, fn: fn)
    switch fnResult {
    case let .Success(fnResult):
      switch fnResult {
      case let .StringAtom(str):
        let deltaObject : (String, NSRange) = (str, result.range)
        deltaBuffer.append(deltaObject)
      default:
        error = EvalError.invalidArgumentError(fn, message: "Result returned by replacement function must be a string")
        shouldStop = true
      }
    case .Recur:
      error = EvalError(.RecurMisuseError, fn)
      shouldStop = true
    case let .Failure(err):
      error = err
      shouldStop = true
    }
    // If we ran into an error or we only want the first result, stop
    if shouldStop {
      stop.memory = true
    }
  }

  // If we ran into an error, stop and return the error immediately
  if let error = error {
    return .Failure(error)
  }
  // Now that we have the replacements and ranges, build the new string
  if deltaBuffer.count == 0 {
    // No matches were made. Return the original string
    return .Success(.StringAtom(s))
  }
  let newStr = NSMutableString(string: s)
  for (replacement, range) in deltaBuffer.lazy.reverse() {
    // We perform replacement in reverse order so we don't need to keep track of offsets caused by replacement strings
    //  that are shorter or longer than the originals
    newStr.replaceCharactersInRange(range, withString: replacement)
  }
  let final = String(newStr)
  return .Success(.StringAtom(final))
}
