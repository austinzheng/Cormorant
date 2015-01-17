//
//  interpreter.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

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
}

typealias LoggingFunction = (String) -> ()

/// A class representing a Lambdatron interpreter.
public class Interpreter {
  // TODO: Any way to do this without the (implicitly unwrapped) optional?
  private let baseContext : Context!

  // Logging functions
  internal var evalLogging : LoggingFunction? = nil

  public func evaluate(form: String) -> Result {
    let lexed = lex(form)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, baseContext)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.readerExpand()
        switch expanded {
        case let .Success(expanded):
          let result = evaluateForm(expanded, baseContext)
          switch result {
          case let .Success(s): return .Success(s)
          case .Recur: return .EvalFailure(.RecurMisuseError)
          case let .Failure(f): return .EvalFailure(f)
          }
        case let .Failure(f): return .ReaderFailure(f)
        }
      case let .Failure(f): return .ParseFailure(f)
      }
    case let .Failure(f): return .LexFailure(f)
    }
  }

  /// Given a domain and a message, pass the message on to the appropriate logging function (if one exists).
  internal func log(domain: LogDomain, message: String) {
    switch domain {
    case .Eval:
      evalLogging?(message)
    }
  }

  var context : Context {
    return baseContext
  }

  /// Given a domain and a function, set the function as a designated handler for logging messages in the domain.
  func setLoggingFunction(domain: LogDomain, function: LoggingFunction) {
    switch domain {
    case .Eval:
      evalLogging = function
    }
  }

  init() {
    baseContext = BaseContext(interpreter: self)
    loadStdlibInto(baseContext, stdlib_files)
  }
}
