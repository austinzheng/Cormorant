//
//  session.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

// Variables can either be literal values, or function objects (for now)
enum VariableEntity {
  case Invalid
  case Literal(LiteralValue)
  case Function(LambdatronFunction)
}

class Session {
  // A dictionary of variable and function bindings.
  // Note: right now everything is in global scope (there isn't even dynamic scope yet)
  // The goal is eventually lexical scope, or (even better) choice between the two for demonstration's sake
  var bindings : [String : VariableEntity] = [:]

  subscript(x: String) -> VariableEntity {
    get {
      if let value = bindings[x] {
        return value
      }
      return .Invalid
    }
    // TODO: set
  }

  // Create a new session
  init() {
    func setupDefaultBindings() {
      // Bind math operators
      bindings["+"] = .Function(plus)
      bindings["-"] = .Function(minus)
      bindings["*"] = .Function(multiply)
      bindings["/"] = .Function(divide)
    }
    setupDefaultBindings()
  }
}
