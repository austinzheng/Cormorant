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
    case let BoundMacro(m): return "macro:'\(m.name)'"
    }
  }
}

/// A class representing the lexical context of a function, loop, or 'let'-scoped block. Contexts chain together to form
/// a 'spaghetti stack'.
class Context {
  var bindings : [InternedSymbol : Binding] = [:]
  
  func setTopLevelBinding(name: InternedSymbol, value: Binding) {
    fatalError("Subclasses must override this")
  }
  
  func nameForSymbol(symbol: InternedSymbol) -> String {
    fatalError("Subclasses must override this")
  }
  
  func symbolForName(name: String) -> InternedSymbol {
    fatalError("Subclasses must override this")
  }
  
  private func retrieveBaseParent() -> BaseContext {
    fatalError("Subclasses must override this")
  }
  
  /// Create a new global context. This is the baseline context which execution should begin with.
  class func globalContextInstance() -> Context {
    let context = BaseContext()
    loadStdlibInto(context, stdlib_files)
    return context
  }
  
  /// Create a new instance of a context for a lexical scope.
  class func instance(# parent: Context, bindings: [InternedSymbol : Binding]) -> Context {
    return ChildContext(parent: parent, bindings: bindings)
  }
  
  func symbolIsValid(symbol: InternedSymbol) -> Bool {
    let binding = self[symbol]
    switch binding {
    case .Invalid: return false
    default: return true
    }
  }
  
  func symbolIsBound(symbol: InternedSymbol) -> Bool {
    let binding = self[symbol]
    switch binding {
    case .Unbound: return true
    default: return false
    }
  }
  
  subscript(x: InternedSymbol) -> Binding {
    get { fatalError("Subclasses must override this") }
    set { bindings[x] = newValue }
  }
}

/// A class representing the 'base' context - the one in which the standard library and global symbols are loaded.
private class BaseContext : Context {
  // The base context is responsible for maintaining the table that maps symbol names (e.g. "foo") to their interned
  //  identifiers, as well as building new gensyms.
  
  var namesToIds : [String : InternedSymbol] = [:]
  var idsToNames : [InternedSymbol : String] = [:]
  var idCounter = 0
  
  override func nameForSymbol(symbol: InternedSymbol) -> String {
    if let name = idsToNames[symbol] {
      return name
    }
    // If there is no name for an interned symbol, something is seriously wrong.
    fatal("Previously interned symbol doesn't have a name")
  }
  
  override func symbolForName(name: String) -> InternedSymbol {
    if let symbol = namesToIds[name] {
      return symbol
    }
    else {
      // We need to intern a new symbol
      let newSymbol = InternedSymbol(idCounter)
      idCounter++
      namesToIds[name] = newSymbol
      idsToNames[newSymbol] = name
      return newSymbol
    }
  }
  
  private override func retrieveBaseParent() -> BaseContext {
    return self
  }
  
  override func setTopLevelBinding(name: InternedSymbol, value: Binding) {
    self[name] = value
  }
  
  override subscript(x: InternedSymbol) -> Binding {
    get { return bindings[x] ?? .Invalid }
    set { super[x] = newValue }
  }
}

/// A class representing a context representing any lexical scope beneath the global scope.
private class ChildContext : Context {
  let parent : Context
  private let baseParent : BaseContext
  
  override func nameForSymbol(symbol: InternedSymbol) -> String {
    return baseParent.nameForSymbol(symbol)
  }
  
  override func symbolForName(name: String) -> InternedSymbol {
    return baseParent.symbolForName(name)
  }
  
  override func setTopLevelBinding(name: InternedSymbol, value: Binding) {
    parent.setTopLevelBinding(name, value: value)
  }
  
  private override func retrieveBaseParent() -> BaseContext {
    return baseParent
  }
  
  override subscript(x: InternedSymbol) -> Binding {
    get { return bindings[x] ?? parent[x] }
    set { super[x] = newValue }
  }
  
  // Create a new session
  init(parent: Context, bindings: [InternedSymbol : Binding]) {
    self.parent = parent
    baseParent = parent.retrieveBaseParent()
    super.init()
    self.bindings = bindings
  }
}
