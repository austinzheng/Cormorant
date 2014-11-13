//
//  context.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

enum Binding {
  case Invalid
  case Unbound
  case Literal(ConsValue)
//  case Macro(LambdatronMacro)
  case Function(LambdatronFunction)
}

class Context {
  // A dictionary of variable and function bindings.
  var bindings : [String : Binding] = [:]
  
  let parent : Context?
  var isTopLevel : Bool {
    return parent == nil
  }
  
  func setTopLevelBinding(name: String, value: Binding) {
    if isTopLevel {
      self[name] = value
    }
    else {
      parent?.setTopLevelBinding(name, value: value)
    }
  }
  
  func nameIsValid(name: String) -> Bool {
    let binding = self[name]
    switch binding {
    case .Invalid: return false
    default: return true
    }
  }
  
  func nameIsUnbound(name: String) -> Bool {
    let binding = self[name]
    switch binding {
    case .Unbound: return true
    default: return false
    }
  }

  subscript(x: String) -> Binding {
    get {
      if let value = bindings[x] {
        return value
      }
      else if let actualParent = parent {
        // Recursively search through the bindings hierarchy
        return actualParent[x]
      }
      return .Invalid
    }
    set {
      bindings[x] = newValue
    }
  }
  
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

  class func globalContextInstance() -> Context {
    let context = Context()
    context.setupDefaultBindings()
    return context
  }
  
  private init() {
    // Only used for creating the top-level session
    self.parent = nil
  }
  
  // Create a new session
  init(parent: Context, bindings: [String : Binding]) {
    self.parent = parent
    self.bindings = bindings
  }
}
