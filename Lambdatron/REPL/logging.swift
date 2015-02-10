//
//  logging.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

class LoggingManager {
  private var evalLoggingEnabled = false

  func loggingEnabledForDomain(domain: LogDomain) -> Bool {
    switch domain {
    case .Eval:
      return evalLoggingEnabled
    }
  }

  func setLoggingForDomain(domain: LogDomain, enabled: Bool) {
    switch domain {
    case .Eval:
      evalLoggingEnabled = enabled
    }
  }
  
  func setAllLogging(enabled: Bool) {
    evalLoggingEnabled = enabled
  }

  func logEval(message: @autoclosure () -> String) {
    let type = LogDomain.Eval.rawValue
    if loggingEnabledForDomain(.Eval) {
      println("LOG (\(type)): \(message())")
    }
  }
}
