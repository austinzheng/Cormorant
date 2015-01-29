//
//  errors.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/22/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enumeration describing various keys which can be used to add metadata to an error.
public enum MetadataKey {
  case Message          // A message provided when the error was thrown
  case Fn               // The name of the function, macro, or special form within which the error was thrown
  case ExpectedArity    // A description of an expected arity for a function
  case ActualArity      // A description of the actual arity for a function
  case Index            // An out-of-bounds value used to index into a collection
  case Symbol           // A symbol which was invalid or unbound
  case Custom           // A secondary message or informational string not covered by any of the above cases
}

typealias MetaDict = [MetadataKey : String]

/// An error object involving the failure of the lexer to properly lex some input string.
public struct LexError : Printable {
  enum ErrorType : String {
    case InvalidEscapeSequenceError = "InvalidEscapeSequenceError"
    case InvalidCharacterError = "InvalidCharacterError"
    case NonTerminatedStringError = "NonTerminatedStringError"
  }
  let error : ErrorType
  let metadata : MetaDict

  init(_ error: ErrorType, metadata: MetaDict? = nil) {
    self.error = error; self.metadata = metadata ?? [:]
  }

  public var description : String {
    let name = self.error.rawValue
    switch self.error {
    case .InvalidEscapeSequenceError: return "(\(name)): invalid or unfinished escape sequence"
    case .InvalidCharacterError: return "(\(name)): invalid or unfinished character literal"
    case .NonTerminatedStringError: return "(\(name)): strings weren't all terminated by end of input"
    }
  }
}

/// An enum describing errors that can cause parsing to fail.
public enum ParseError : String, Printable {
  case EmptyInputError = "EmptyInputError"
  case BadStartTokenError = "BadStartTokenError"
  case MismatchedDelimiterError = "MismatchedDelimiterError"
  case MismatchedReaderMacroError = "MismatchedReaderMacroError"
  case MapKeyValueMismatchError = "MapKeyValueMismatchError"

  public var description : String {
    let name = self.rawValue
    switch self {
    case EmptyInputError:
      return "(\(name)): empty input"
    case BadStartTokenError:
      return "(\(name)): collection or form started with invalid delimiter"
    case MismatchedDelimiterError:
      return "(\(name)): mismatched delimiter ('(', '[', '{', ')', ']', or '}')"
    case MismatchedReaderMacroError:
      return "(\(name)): mismatched reader macro (', `, ~, or ~@)"
    case MapKeyValueMismatchError:
      return "(\(name)): map literal must be declared with an even number of forms"
    }
  }
}

/// An enum describing errors that can happen while expanding reader macros.
public enum ReaderError : String, Printable {
  case UnmatchedReaderMacroError = "UnmatchedReaderMacroError"
  case IllegalFormError = "IllegalFormError"
  case UnquoteSpliceMisuseError = "SyntaxQuoteMisuseError"
  
  public var description : String {
    let desc : String = {
      switch self {
      case UnmatchedReaderMacroError:
        return "reader macro token present without corresponding form"
      case IllegalFormError:
        return "form of illegal type provided to reader macro (e.g. None)"
      case UnquoteSpliceMisuseError:
        return "~@ used improperly (outside the context of a collection)"
      }
    }()
    return "(\(self.rawValue)): \(desc)"
  }
}

/// An enum describing errors that can happen at runtime when evaluating macros, functions, or special forms.
public struct EvalError : Printable {
  enum ErrorType : String {
    case ArityError = "ArityError"
    case InvalidArgumentError = "InvalidArgumentError"
    case OutOfBoundsError = "OutOfBoundsError"
    case NotEvalableError = "NotEvalableError"
    case DivideByZeroError = "DivideByZeroError"
    case IntegerOverflowError = "IntegerOverflowError"
    case BindingMismatchError = "BindingMismatchError"
    case InvalidSymbolError = "InvalidSymbolError"
    case UnboundSymbolError = "UnboundSymbolError"
    case RecurMisuseError = "RecurMisuseError"
    case EvaluatingMacroError = "EvaluatingMacroError"
    case EvaluatingSpecialFormError = "EvaluatingSpecialFormError"
    case NoFnAritiesError = "NoFnAritiesError"
    case MultipleVariadicAritiesError = "MultipleVariadicAritiesEror"
    case MultipleDefinitionsPerArityError = "MultipleDefinitionsPerArityError"
    case FixedArityExceedsVariableArityError = "FixedArityExceedsVariableArityError"
    case ReadError = "ReadError"
    case RuntimeError = "RuntimeError"
  }
  let error : ErrorType
  let metadata : MetaDict

  init(_ error: ErrorType, _ fn: String, message: String? = nil, metadata: MetaDict? = nil) {
    var meta = metadata ?? [:]
    meta[.Fn] = fn
    if let message =  message {
      meta[.Message] = message
    }
    self.error = error
    self.metadata = meta
  }

  init(_ error: ErrorType, message: String? = nil, metadata: MetaDict? = nil) {
    var meta = metadata ?? [:]
    self.error = error
    self.metadata = meta
  }

  static func outOfBoundsError(fn: String, idx: Int, metadata: MetaDict? = nil) -> EvalError {
    var meta = metadata ?? [:]
    meta[.Index] = "\(idx)"
    let error = EvalError(.OutOfBoundsError, fn, metadata: meta)
    return error
  }

  static func runtimeError(fn: String, message: String, metadata: MetaDict? = nil) -> EvalError {
    return EvalError(.RuntimeError, fn, message: message, metadata: metadata)
  }

  static func nonNumericArgumentError(fn: String, metadata: MetaDict? = nil) -> EvalError {
    return invalidArgumentError(fn, message: "argument must be numeric", metadata: metadata)
  }

  static func invalidArgumentError(fn: String, message: String, metadata: MetaDict? = nil) -> EvalError {
    return EvalError(.InvalidArgumentError, fn, message: message, metadata: metadata)
  }

  static func arityError(expected: String, actual: Int, _ fn: String, metadata: MetaDict? = nil) -> EvalError {
    var meta = metadata ?? [:]
    meta[.ExpectedArity] = expected
    meta[.ActualArity] = "\(actual)"
    let error = EvalError(.ArityError, fn, metadata: meta)
    return error
  }

  public var description : String {
    let desc : String = {
      switch self.error {
      case .ArityError: return "wrong number of arguments to macro, function, or special form"
      case .InvalidArgumentError: return "invalid type or value for argument"
      case .OutOfBoundsError: return "index to sequence was out of bounds"
      case .NotEvalableError: return "item in function position is not something that can be evaluated"
      case .DivideByZeroError:  return "attempted to divide by zero"
      case .IntegerOverflowError: return "arithmetic operation resulted in overflow"
      case .BindingMismatchError: return "binding vector must have an even number of elements"
      case .InvalidSymbolError: return "could not resolve symbol"
      case .UnboundSymbolError: return "symbol is unbound, and cannot be resolved"
      case .RecurMisuseError: return "didn't use recur as the final form within loop or fn"
      case .EvaluatingMacroError: return "can't take the value of a macro or reader macro"
      case .EvaluatingSpecialFormError: return "can't take the value of a special form"
      case .NoFnAritiesError: return "function or macro must be defined with at least one arity"
      case .MultipleVariadicAritiesError: return "function/macro can only be defined with at most one variadic arity"
      case .MultipleDefinitionsPerArityError: return "only one function/macro body can be defined per arity"
      case .FixedArityExceedsVariableArityError: return "fixed arities cannot have more params than a variadic arity"
      case .ReadError: return "failed to lex, parse, or expand raw input"
      case .RuntimeError: return "runtime error"
      }
      }()
    var str = "(\(self.error.rawValue)): \(desc)"

    // Add data about the function, if any
    if let fn = metadata[.Fn] {
      str += "\n * fn: \(fn)"
    }

    // Add error-specific data
    switch self.error {
    case .ArityError:
      if let expected = metadata[.ExpectedArity] {
        if let actual = metadata[.ActualArity] {
          str += "\n * arity: expected: \(expected), actual: \(actual)"
        }
      }
    case .OutOfBoundsError:
      if let idx = metadata[.Index] {
        str += "\n * index: \(idx)"
      }
    case .InvalidSymbolError, .UnboundSymbolError:
      if let symbol = metadata[.Symbol] {
        str += "\n * symbol: \"\(symbol)\""
      }
    default:
      break
    }

    // Add any custom message pinned to the error
    if let message = metadata[.Message] {
      str += "\n * message: \(message)"
    }

    return str
  }
}
