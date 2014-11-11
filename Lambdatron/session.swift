//
//  session.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

enum Binding {
  case Invalid
  case Literal(ConsValue)
  case Macro(LambdatronMacro)
  case Function(LambdatronFunction)
}

class Session {
  // A dictionary of variable and function bindings.
  // Note: right now everything is in global scope (there isn't even dynamic scope yet)
  // The goal is eventually lexical scope, or (even better) choice between the two for demonstration's sake
  var bindings : [String : Binding] = [:]

  subscript(x: String) -> Binding {
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
      // Bind basic operations
      bindings["cons"] = .Function(cons)
      bindings["first"] = .Function(first)
      bindings["rest"] = .Function(rest)
      // Bind math operators
      bindings["+"] = .Function(plus)
      bindings["-"] = .Function(minus)
      bindings["*"] = .Function(multiply)
      bindings["/"] = .Function(divide)
    }
    setupDefaultBindings()
  }
}
