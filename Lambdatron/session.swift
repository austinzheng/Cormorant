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
      // Bind list functions
      bindings["cons"] = .Function(pr_cons)
      bindings["first"] = .Function(pr_first)
      bindings["rest"] = .Function(pr_rest)
      // Bind I/O functions
      bindings["print"] = .Function(pr_print)
      // Bind comparison functions
      bindings["="] = .Function(pr_equals)
      bindings[">"] = .Function(pr_gt)
      bindings["<"] = .Function(pr_lt)
      // Bind math functions
      bindings["+"] = .Function(pr_plus)
      bindings["-"] = .Function(pr_minus)
      bindings["*"] = .Function(pr_multiply)
      bindings["/"] = .Function(pr_divide)
    }
    setupDefaultBindings()
  }
}
