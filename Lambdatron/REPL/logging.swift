//
//  logging.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

enum LoggingDomain : String {
  case Eval = "eval"
}

class LoggingManager {
  private var evalLoggingEnabled = false

  class var sharedInstance : LoggingManager {
    struct StaticContainer {
      static let instance = LoggingManager()
    }
    return StaticContainer.instance
  }

  func loggingEnabledForDomain(domain: LoggingDomain) -> Bool {
    switch domain {
    case .Eval:
      return evalLoggingEnabled
    }
  }

  func setLoggingForDomain(domain: LoggingDomain, enabled: Bool) {
    switch domain {
    case .Eval:
      evalLoggingEnabled = enabled
    }
  }
  
  func setAllLogging(enabled: Bool) {
    evalLoggingEnabled = enabled
  }
}

/// Log a debug message describing list evaluation to the console
func logEval(message: @autoclosure () -> String) {
  let type = LoggingDomain.Eval.rawValue
  if LoggingManager.sharedInstance.loggingEnabledForDomain(.Eval) {
    println("LOG (\(type)): \(message())")
  }
}
