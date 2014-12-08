//
//  context.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

enum Binding : Printable {
  case Invalid
  case Unbound
  case Literal(ConsValue)
  case FunctionParam(ConsValue)
  case MacroParam(ConsValue)
  case BoundMacro(Macro)
  
  var description : String {
    switch self {
    case Invalid: return "invalid"
    case Unbound: return "unbound"
    case let Literal(l): return "literal: \(l.description)"
    case let FunctionParam(fp): return "function parameter: \(fp.description)"
    case let MacroParam(mp): return "macro parameter: \(mp.description)"
    case let BoundMacro(m): return "macro: '\(m.name)'"
    }
  }
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
  
  class func globalContextInstance() -> Context {
    let context = Context()
    loadStdlibInto(context, stdlib_files)
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
