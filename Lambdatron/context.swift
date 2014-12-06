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
  case BuiltIn(LambdatronBuiltIn)
  
  var description : String {
    switch self {
    case .Invalid: return "invalid"
    case .Unbound: return "unbound"
    case let .Literal(l): return "literal: \(l.description)"
    case let .FunctionParam(fp): return "function parameter: \(fp.description)"
    case let .MacroParam(mp): return "macro parameter: \(mp.description)"
    case let .BoundMacro(m): return "macro: '\(m.name)'"
    case let .BuiltIn(b): return "builtin: \(b)"
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
  
  func setupDefaultBindings() {
    // Bind collection functions
    bindings["list"] = .BuiltIn(pr_list)
    bindings["vector"] = .BuiltIn(pr_vector)
    bindings["hash-map"] = .BuiltIn(pr_hashmap)
    bindings["concat"] = .BuiltIn(pr_concat)
    bindings["seq"] = .BuiltIn(pr_seq)
    bindings["get"] = .BuiltIn(pr_get)
    bindings["assoc"] = .BuiltIn(pr_assoc)
    bindings["dissoc"] = .BuiltIn(pr_dissoc)
    // Bind type test functions
    bindings["number?"] = .BuiltIn(pr_isNumber)
    bindings["string?"] = .BuiltIn(pr_isString)
    bindings["symbol?"] = .BuiltIn(pr_isSymbol)
    bindings["fn?"] = .BuiltIn(pr_isFunction)
    bindings["eval?"] = .BuiltIn(pr_isEvalable)
    bindings["true?"] = .BuiltIn(pr_isTrue)
    bindings["false?"] = .BuiltIn(pr_isFalse)
    bindings["list?"] = .BuiltIn(pr_isList)
    bindings["vector?"] = .BuiltIn(pr_isVector)
    bindings["map?"] = .BuiltIn(pr_isMap)
    // Bind I/O functions
    bindings["print"] = .BuiltIn(pr_print)
    // Bind comparison functions
    bindings["="] = .BuiltIn(pr_equals)
    bindings[">"] = .BuiltIn(pr_gt)
    bindings["<"] = .BuiltIn(pr_lt)
    // Bind math functions
    bindings["+"] = .BuiltIn(pr_plus)
    bindings["-"] = .BuiltIn(pr_minus)
    bindings["*"] = .BuiltIn(pr_multiply)
    bindings["/"] = .BuiltIn(pr_divide)
    // Bind other functions
    bindings["apply"] = .BuiltIn(pr_apply)
  }

  class func globalContextInstance() -> Context {
    let context = Context()
    context.setupDefaultBindings()
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
