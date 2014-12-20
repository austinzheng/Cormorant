//
//  context.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum representing the binding state and value for a particular symbol.
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

/// A class representing the lexical context of a function, loop, or 'let'-scoped block. Contexts chain together to form
/// a 'spaghetti stack'.
class Context {
  var bindings : [String : Binding] = [:]
  
  func setTopLevelBinding(name: String, value: Binding) {
    fatalError("Subclasses must override this")
  }
  
  /// Create a new global context. This is the baseline context which execution should begin with.
  class func globalContextInstance() -> Context {
    let context = BaseContext()
    loadStdlibInto(context, stdlib_files)
    return context
  }
  
  /// Create a new instance of a context for a lexical scope.
  class func instance(# parent: Context, bindings: [String : Binding]) -> Context {
    return ChildContext(parent: parent, bindings: bindings)
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
    get { fatalError("Subclasses must override this") }
    set { bindings[x] = newValue }
  }
}

/// A class representing the 'base' context - the one in which the standard library and global symbols are loaded.
private class BaseContext : Context {
  override func setTopLevelBinding(name: String, value: Binding) {
    self[name] = value
  }
  
  override subscript(x: String) -> Binding {
    get { return bindings[x] ?? .Invalid }
    set { super[x] = newValue }
  }
}

/// A class representing a context representing any lexical scope beneath the global scope.
private class ChildContext : Context {
  let parent : Context
  
  override func setTopLevelBinding(name: String, value: Binding) {
    parent.setTopLevelBinding(name, value: value)
  }
  
  override subscript(x: String) -> Binding {
    get { return bindings[x] ?? parent[x] }
    set { super[x] = newValue }
  }
  
  // Create a new session
  init(parent: Context, bindings: [String : Binding]) {
    self.parent = parent
    super.init()
    self.bindings = bindings
  }
}
