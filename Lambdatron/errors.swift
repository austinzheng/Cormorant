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
  case RegexPattern     // A regex pattern string
  case Custom           // A secondary message or informational string not covered by any of the above cases
}

public typealias MetaDict = [MetadataKey : String]

/// An object representing an error that occurs during the lexing, parsing, or reader macro expansion stages.
public struct ReadError : Printable {
  public enum ErrorType : String {
    case InvalidStringEscapeSequenceError = "InvalidStringEscapeSequenceError"
    case InvalidCharacterError = "InvalidCharacterError"
    case InvalidUnicodeError = "InvalidUnicodeError"
    case InvalidOctalError = "InvalidOctalError"
    case SymbolParseFailureError = "SymbolParseFailureError"
    case KeywordParseFailureError = "KeywordParseFailureError"
    case InvalidNamespaceError = "InvalidNamespaceError"
    case InvalidDispatchMacroError = "InvalidDispatchMacroError"
    case NonTerminatedStringError = "NonTerminatedStringError"
    case EmptyInputError = "EmptyInputError"
    case BadStartTokenError = "BadStartTokenError"
    case MismatchedDelimiterError = "MismatchedDelimiterError"
    case MismatchedReaderMacroError = "MismatchedReaderMacroError"
    case MapKeyValueMismatchError = "MapKeyValueMismatchError"
    case InvalidRegexError = "InvalidRegexError"
    case UnimplementedFeatureError = "UnimplementedFeatureError"
    case IllegalExpansionFormError = "IllegalExpansionFormError"
    case UnquoteSpliceMisuseError = "UnquoteSpliceMisuseError"
  }
  public let error : ErrorType
  public let metadata : MetaDict

  init(_ error: ErrorType, metadata: MetaDict? = nil) {
    self.error = error; self.metadata = metadata ?? [:]
  }

  public var description : String {
    let name = error.rawValue
    switch error {
    case .InvalidStringEscapeSequenceError: return "(\(name)): invalid or unfinished string escape sequence"
    case .InvalidCharacterError: return "(\(name)): invalid or unfinished character literal"
    case .InvalidUnicodeError: return "(\(name)): invalid Unicode character literal; must be in the form \\uNNNN"
    case .InvalidOctalError: return "(\(name)): invalid octal character literal; must be in the form \\oNNN"
    case .SymbolParseFailureError: return "(\(name)): could not parse symbol"
    case .KeywordParseFailureError: return "(\(name)): could not parse keyword"
    case .InvalidNamespaceError: return "(\(name)): invalid or reserved namespace"
    case .InvalidDispatchMacroError: return "(\(name)): invalid dispatch macro"
    case .NonTerminatedStringError: return "(\(name)): strings weren't all terminated by end of input"
    case .EmptyInputError: return "(\(name)): empty input"
    case .BadStartTokenError: return "(\(name)): collection or form started with invalid delimiter"
    case .MismatchedDelimiterError: return "(\(name)): mismatched delimiter ('(', '[', '{', ')', ']', or '}')"
    case .MismatchedReaderMacroError: return "(\(name)): mismatched reader macro (', `, ~, or ~@)"
    case .MapKeyValueMismatchError: return "(\(name)): map literal must be declared with an even number of forms"
    case .InvalidRegexError: return "(\(name)): regex pattern is not valid"
    case .IllegalExpansionFormError: return "(\(name)): form of illegal type provided to reader macro"
    case .UnquoteSpliceMisuseError: return "(\(name)): ~@ used improperly (outside the context of a collection)"
    case .UnimplementedFeatureError: return "(\(name)): unimplemented feature"
    }
  }
}

/// An enum describing errors that can happen at runtime when evaluating macros, functions, or special forms.
public struct EvalError : Printable {
  public enum ErrorType : String {
    case ArityError = "ArityError"
    case InvalidArgumentError = "InvalidArgumentError"
    case OutOfBoundsError = "OutOfBoundsError"
    case NotEvalableError = "NotEvalableError"
    case DivideByZeroError = "DivideByZeroError"
    case IntegerOverflowError = "IntegerOverflowError"
    case BindingMismatchError = "BindingMismatchError"
    case InvalidSymbolError = "InvalidSymbolError"
    case QualifiedSymbolMisuseError = "QualifiedSymbolMisuseError"
    case RecurMisuseError = "RecurMisuseError"
    case EvaluatingMacroError = "EvaluatingMacroError"
    case EvaluatingSpecialFormError = "EvaluatingSpecialFormError"
    case NoFnAritiesError = "NoFnAritiesError"
    case MultipleVariadicAritiesError = "MultipleVariadicAritiesEror"
    case MultipleDefinitionsPerArityError = "MultipleDefinitionsPerArityError"
    case FixedArityExceedsVariableArityError = "FixedArityExceedsVariableArityError"
    case ReadError = "ReadError"
    case VarRebindingError = "VarRebindingError"
    case AliasRebindingError = "AliasRebindingError"
    case InvalidNamespaceError = "InvalidNamespaceError"
    case ReservedNamespaceError = "ReservedNamespaceError"
    case RuntimeError = "RuntimeError"
  }
  public let error : ErrorType
  public let metadata : MetaDict

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

  static func readError(forFn fn: String, error: ReadError) -> EvalError {
    let metadata : MetaDict = [.Message: error.description]
    return EvalError(.ReadError, fn, metadata: metadata)
  }

  public var description : String {
    let desc : String
    switch error {
    case .ArityError: desc = "wrong number of arguments to macro, function, or special form"
    case .InvalidArgumentError: desc = "invalid type or value for argument"
    case .OutOfBoundsError: desc = "index to sequence was out of bounds"
    case .NotEvalableError: desc = "item in function position is not something that can be evaluated"
    case .DivideByZeroError:  desc = "attempted to divide by zero"
    case .IntegerOverflowError: desc = "arithmetic operation resulted in overflow"
    case .BindingMismatchError: desc = "binding vector must have an even number of elements"
    case .InvalidSymbolError: desc = "could not resolve symbol"
    case .QualifiedSymbolMisuseError: desc = "can't use a qualified symbol in this way"
    case .RecurMisuseError: desc = "didn't use recur as the final form within loop or fn"
    case .EvaluatingMacroError: desc = "can't take the value of a macro or reader macro"
    case .EvaluatingSpecialFormError: desc = "can't take the value of a special form"
    case .NoFnAritiesError: desc = "function or macro must be defined with at least one arity"
    case .MultipleVariadicAritiesError: desc = "function/macro can only be defined with at most one variadic arity"
    case .MultipleDefinitionsPerArityError: desc = "only one function/macro body can be defined per arity"
    case .FixedArityExceedsVariableArityError: desc = "fixed arities cannot have more params than a variadic arity"
    case .ReadError: desc = "failed to lex, parse, or expand raw input"
    case .VarRebindingError: desc = "var already refers to another var"
    case .AliasRebindingError: desc = "alias already refers to another namespace"
    case .InvalidNamespaceError: desc = "namespace does not exist"
    case .ReservedNamespaceError: desc = "namespace is a system or reserved namespace, and cannot be used"
    case .RuntimeError: desc = "runtime error"
    }

    var str = "(\(error.rawValue)): \(desc)"

    // Add data about the function, if any
    if let fn = metadata[.Fn] {
      str += "\n * fn: \(fn)"
    }

    // Add error-specific data
    switch self.error {
    case .ArityError:
      if let expected = metadata[.ExpectedArity], let actual = metadata[.ActualArity] {
        str += "\n * arity: expected: \(expected), actual: \(actual)"
      }
    case .OutOfBoundsError:
      if let idx = metadata[.Index] {
        str += "\n * index: \(idx)"
      }
    case .InvalidSymbolError:
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
