//
//  interpreter.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque struct representing a ConsValue.
public struct Form {
  internal let value : ConsValue
  internal init(_ value: ConsValue) { self.value = value }
}

/// An enum describing possible results from evaluating an input to the interpreter.
public enum Result {
  case Success(ConsValue)
  case LexFailure(LexError)
  case ParseFailure(ParseError)
  case ReaderFailure(ReaderError)
  case EvalFailure(EvalError)
}

/// An enum describing logging domains that can be individually enabled or disabled as necessary.
public enum LogDomain : String {
  case Eval = "eval"

  static var allDomains : [LogDomain] { return [.Eval] }
}

typealias LoggingFunction = (@autoclosure () -> String) -> ()

/// An opaque type representing a function allowing the interpreter to write output.
public typealias OutputFunction = (String) -> ()

/// An opaque type representing a function allowing the intepreter to read input.
public typealias InputFunction = () -> String

/// A class representing a Lambdatron interpreter.
public class Interpreter {
  // TODO: Any way to do this without the (implicitly unwrapped) optional?
  var context : Context!

  // Logging functions
  var evalLogging : LoggingFunction? = nil

  // IO functions

  /// A function that the interpreter calls in order to write out data. Defaults to 'print'.
  public var writeOutput : OutputFunction? = print

  /// A function that the interpreter calls in order to read in data.
  public var readInput : InputFunction? = nil

  /// Given a string, evaluate it as Lambdatron code and return a successful result or error.
  public func evaluate(form: String) -> Result {
    let lexed = lex(form)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.readerExpand()
        switch expanded {
        case let .Success(expanded):
          let result = evaluateForm(expanded, context)
          switch result {
          case let .Success(s): return .Success(s)
          case .Recur:
            return .EvalFailure(EvalError(.RecurMisuseError, message: "recur object was returned to the top level"))
          case let .Failure(f): return .EvalFailure(f)
          }
        case let .Failure(f): return .ReaderFailure(f)
        }
      case let .Failure(f): return .ParseFailure(f)
      }
    case let .Failure(f): return .LexFailure(f)
    }
  }

  /// Given a form, evaluate it and return a successful result or error.
  public func evaluate(form: Form) -> Result {
    let result = evaluateForm(form.value, context)
    switch result {
    case let .Success(s): return .Success(s)
    case .Recur:
      return .EvalFailure(EvalError(.RecurMisuseError, message: "recur object was returned to the top level"))
    case let .Failure(f): return .EvalFailure(f)
    }
  }

  /// Given a string, return a form that can be directly evaluated later or repeatedly.
  public func readIntoForm(form: String) -> Form? {
    let lexed = lex(form)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.readerExpand()
        switch expanded {
        case let .Success(expanded):
          return Form(expanded)
        case .Failure: return nil
        }
      case .Failure: return nil
      }
    case .Failure: return nil
    }
  }

  /// Given a Lambdatron form, return a prettified description.
  public func describe(form: ConsValue) -> String {
    return form.describe(context)
  }

  /// Reset the interpreter, removing any Vars or other state. This does not affect the logging, input, or output
  /// functions.
  public func reset() {
    context = buildRootContext(interpreter: self)
  }

  /// Given a domain and a message, pass the message on to the appropriate logging function (if one exists).
  func log(domain: LogDomain, message: @autoclosure () -> String) {
    switch domain {
    case .Eval:
      evalLogging?(message)
    }
  }

  /// Given a domain and a function, set the function as a designated handler for logging messages in the domain.
  func setLoggingFunction(domain: LogDomain, function: LoggingFunction) {
    switch domain {
    case .Eval:
      evalLogging = function
    }
  }

  init() {
    context = buildRootContext(interpreter: self)
  }
}
