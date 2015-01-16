//
//  interpreter.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

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
