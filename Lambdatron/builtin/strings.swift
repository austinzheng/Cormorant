//
//  strings.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/18/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given zero or more objects, return the stringified version of the object(s), concatenating as necessary.
func str_str(args: Params, ctx: Context) -> EvalResult {
  let fn = ".str"
  if args.count == 0 {
    return .Success(.StringAtom(""))
  }
  var buffer : [String] = []
  for arg in args {
    let result = arg.toString(ctx)
    switch result {
    case let .Desc(desc): buffer.append(desc)
    case let .Error(err): return .Failure(err)
    }
  }
  let result = join("", buffer)
  return .Success(.StringAtom(result))
}

/// Given a string, a start index, and an optional end index, return a substring.
func str_subs(args: Params, ctx: Context) -> EvalResult {
  let fn = ".subs"
  if !(args.count == 2 || args.count == 3) {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }
  if let s = args[0].asString {
    if let start = args[1].extractInt() {
      // Use the UTF16 view, since that facilitates indexing into the string using integers (i.e. Clojure's behavior)
      let utf16Str = s as NSString
      if args.count == 2 {
        // Start index only
        return (start < utf16Str.length
          ? .Success(.StringAtom(utf16Str.substringFromIndex(start)))
          : .Failure(EvalError.outOfBoundsError(fn, idx: start)))
      }
      else {
        if let end = args[2].extractInt() {
          // Start and end indices
          return (start <= utf16Str.length
            ? (end <= utf16Str.length && !(end < start)
              ? .Success(.StringAtom(utf16Str.substringWithRange(NSMakeRange(start, end - start))))
              : .Failure(EvalError.outOfBoundsError(fn, idx: end)))
            : .Failure(EvalError.outOfBoundsError(fn, idx: start)))
        }
        else {
          return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be numeric"))
        }
      }
    }
    else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be numeric"))
    }
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
}

/// Given any type of object, return an equivalent string but with all letters in uppercase.
func str_uppercase(args: Params, ctx: Context) -> EvalResult {
  let fn = ".upper-case"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let s = args[0].toString(ctx)
  switch s {
  case let .Desc(s): return .Success(.StringAtom(s.uppercaseString))
  case let .Error(err): return .Failure(err)
  }
}

/// Given any type of object, return an equivalent string but with all letters in lowercase.
func str_lowercase(args: Params, ctx: Context) -> EvalResult {
  let fn = ".upper-case"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  let s = args[0].toString(ctx)
  switch s {
  case let .Desc(s): return .Success(.StringAtom(s.lowercaseString))
  case let .Error(err): return .Failure(err)
  }
}

/// Given a string, a match object, and a replacement object, replace all occurrences of the match in the string.
func str_replace(args: Params, ctx: Context) -> EvalResult {
  let fn = ".replace"
  return replace(args, ctx, fn, false)
}

/// Given a string, a match object, and a replacement object, replace the first occurrence of the match in the string.
func str_replaceFirst(args: Params, ctx: Context) -> EvalResult {
  let fn = ".replace-first"
  return replace(args, ctx, fn, true)
}


// MARK: Private helpers

private func replace(args: Params, ctx: Context, fn: String, firstOnly: Bool) -> EvalResult {
  if args.count != 3 {
    return .Failure(EvalError.arityError("3", actual: args.count, fn))
  }
  if let s = args[0].asString {
    let match = args[1]
    let replacement = args[2]
    switch match {
    case let .StringAtom(match):
      switch replacement {
      case let .StringAtom(replacement):
        // Replace all occurrences of the match string with the replacement string
        return replaceWithString(s, match, replacement, firstOnly, fn)
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "if the match is a string, the replacement must also be a string"))
      }
    case let .Auxiliary(aux):
      if let match = aux as? NSRegularExpression {
        switch replacement {
        case let .StringAtom(replacement):
          // The replacement argument is a template string
          let newStr = replaceWithTemplate(s, match, replacement, firstOnly, fn)
          return .Success(.StringAtom(newStr))
        default:
          // The replacement argument will be treated as a function that takes in match results and returns a string
          return replaceWithFunction(s, match, replacement, firstOnly, fn, ctx)
        }
      }
      else {
        // Must be regex
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "second argument must be a string, character, or regex pattern"))
      }
    case let .CharAtom(match):
      // Replace all occurrences of the match character with the replacement character
      switch replacement {
      case let .CharAtom(replacement):
        return replaceWithString(s, String(match), String(replacement), firstOnly, fn)
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "if the match is a character, the replacement must also be a character"))
      }
    default:
      return .Failure(EvalError.invalidArgumentError(fn,
        message: "second argument must be a string, character, or regex pattern"))
    }
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a string"))
}

private func replaceWithString(s: String, m: String, replacement: String, firstOnly: Bool, fn: String) -> EvalResult {
  let match = NSRegularExpression.escapedPatternForString(m)
  let template = NSRegularExpression.escapedTemplateForString(replacement)
  switch constructRegex(match) {
  case let .Success(regex):
    let stringRange = NSRange(location: 0, length: s.utf16Count)
    let searchRange = firstOnly ? regex.rangeOfFirstMatchInString(s, options: nil, range: stringRange) : stringRange
    let newStr = (rangeIsValid(searchRange)
      ? regex.stringByReplacingMatchesInString(s, options: nil, range: searchRange, withTemplate: template)
      : s)
    return .Success(.StringAtom(newStr))
  case let .Error(err):
    return .Failure(EvalError.readError(forFn: fn, error: err))
  }
}

private func replaceWithTemplate(s: String, m: NSRegularExpression, template: String, firstOnly: Bool, fn: String) -> String {
  let stringRange = NSRange(location: 0, length: s.utf16Count)
  let searchRange = firstOnly ? m.rangeOfFirstMatchInString(s, options: nil, range: stringRange) : stringRange
  return (rangeIsValid(searchRange)
    ? m.stringByReplacingMatchesInString(s, options: nil, range: searchRange, withTemplate: template)
    : s)
}

private func replaceWithFunction(s: String, match: NSRegularExpression, function: ConsValue, firstOnly: Bool, fn: String, ctx: Context) -> EvalResult {
  // Handle the case where the match is a regex and the replacement is defined by a function
  let utf16Str = s as NSString

  var error : EvalError?
  var deltaBuffer : [(String, NSRange)] = []

  match.enumerateMatchesInString(utf16Str, options: nil, range: NSRange(location: 0, length: utf16Str.length)) {
    (result: NSTextCheckingResult!, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
    // Create a vector of the results
    var shouldStop = firstOnly
    var buffer : [ConsValue] = []
    for i in 0..<result.numberOfRanges {
      let thisRange = result.rangeAtIndex(i)
      if rangeIsValid(thisRange) {
        buffer.append(.StringAtom(utf16Str.substringWithRange(thisRange)))
      }
    }
    // Pass the match results to the function so that it can produce a replacement string
    // Note that if there aren't any match groups, the function gets the string; if there are match groups, the function
    //  gets a vector of strings (with the first being the match, and the rest being each matched group).
    let fnResult = apply(function, Params(buffer.count == 1 ? buffer[0] : .Vector(buffer)), ctx, fn)
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
  var newStr : NSMutableString = NSMutableString(string: s)
  for (replacement, range) in lazy(reverse(deltaBuffer)) {
    // We perform replacement in reverse order so we don't need to keep track of offsets caused by replacement strings
    //  that are shorter or longer than the originals
    newStr.replaceCharactersInRange(range, withString: replacement)
  }
  return .Success(.StringAtom(newStr))
}
