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
  case Param(ConsValue)     // Currently treated no differently than Literal, but here for future optimization
  case BoundMacro(Macro)
  
  var description : String {
    switch self {
    case Invalid: return "invalid"
    case Unbound: return "unbound"
    case let Literal(l): return "literal: \(l.description)"
    case let Param(mp): return "function/macro parameter: \(mp.description)"
    case let BoundMacro(m): return "macro:'\(m.name)'"
    }
  }
}

/// A protocol representing the execution context of a given form. Contexts represent the lexical environment of a
/// function, loop, or let-scoped block, unifying both local bindings and Vars. They also mediate access to other
/// mutable interpreter state, such as I/O and gensym. Contexts chain together to form a 'spaghetti stack'.
protocol Context : class {

  /// Given an interned symbol representing a Var and a value, create or set the Var to the value.
  func setVar(name: InternedSymbol, value: Binding)

  /// Given an interned symbol, retrieve the topmost valid binding or Var for it.
  subscript(x: InternedSymbol) -> Binding { get set }

  /// Return whether or not a Var is valid.
  func varIsValid(symbol: InternedSymbol) -> Bool

  /// Return whether or not a Var is bound.
  func varIsBound(symbol: InternedSymbol) -> Bool

  /// Given an interned symbol, return its name.
  func nameForSymbol(symbol: InternedSymbol) -> String

  /// Given a symbol name, create and/or return an interned symbol.
  func symbolForName(name: String) -> InternedSymbol

  /// Given an interned keyword, return its name.
  func nameForKeyword(keyword: InternedKeyword) -> String

  /// Given a keyword name, create and/or return an interned keyword.
  func keywordForName(name: String) -> InternedKeyword

  /// Write a message to the interpreter logging facility.
  func log(domain: LogDomain, message: @autoclosure () -> String)

  /// Get a reference to the interpreter's input function, if any.
  var readInput : InputFunction? { get }

  /// Get a reference to the interpreter's output function, if any.
  var writeOutput : OutputFunction? { get }

  /// Get a reference to the interpreter's root context.
  var root : Context { get }
}

/// An abstract class representing a base context - either the RootContext for an interpreter, or the GlobalContext used
/// by all interpreter instances.
private class BaseContext {
  var bindings : [InternedSymbol : Binding] = [:]

  var namesToIds : [String : InternedSymbol] = [:]
  var idsToNames : [InternedSymbol : String] = [:]
  var symbolIdCounter = 0

  var keywordsToIds : [String : InternedKeyword] = [:]
  var idsToKeywords : [InternedKeyword : String] = [:]
  var keywordIdCounter = 0

  func varIsValid(symbol: InternedSymbol) -> Bool {
    let binding = bindings[symbol] ?? .Invalid
    switch binding {
    case .Invalid: return false
    default: return true
    }
  }

  func varIsBound(symbol: InternedSymbol) -> Bool {
    let binding = bindings[symbol] ?? .Invalid
    switch binding {
    case .Unbound: return true
    default: return false
    }
  }

  /// Given a symbol, return the name for the symbol (if one exists).
  func existingNameForSymbol(symbol: InternedSymbol) -> String? {
    return idsToNames[symbol]
  }

  /// Given a symbol name, return the interned symbol object (if one exists).
  func existingSymbolForName(name: String) -> InternedSymbol? {
    return namesToIds[name]
  }

  /// Create a new interned symbol for the given symbol name.
  func internSymbol(name: String) -> InternedSymbol {
    // Precondition: name is not currently used by any symbol.
    let newSymbol = InternedSymbol(symbolIdCounter)
    symbolIdCounter++
    namesToIds[name] = newSymbol
    idsToNames[newSymbol] = name
    return newSymbol
  }

  /// Given a keyword, return the name for the keyword (if one exists).
  func existingNameForKeyword(keyword: InternedKeyword) -> String? {
    return idsToKeywords[keyword]
  }

  /// Given a keyword name, return the interned keyword object (if one exists).
  func existingKeywordForName(name: String) -> InternedKeyword? {
    return keywordsToIds[name]
  }

  /// Create a new interned keyword for the given keyword name.
  func internKeyword(name: String) -> InternedKeyword {
    // Precondition: name is not currently used by any keyword.
    let newKeyword = InternedKeyword(keywordIdCounter)
    keywordIdCounter++
    keywordsToIds[name] = newKeyword
    idsToKeywords[newKeyword] = name
    return newKeyword
  }
}

/// A class representing the root context for a given interpreter instance. This context is responsible for interning
/// keywords and symbols, producing gensyms, and certain other responsibilities.
private class RootContext : BaseContext, Context {
  unowned let interpreter : Interpreter
  let globalContext = GlobalContext.sharedInstance

  var root : Context { return self }

  init(interpreter: Interpreter) {
    self.interpreter = interpreter
    // Start ID counters after those for the base context
    super.init()
    self.symbolIdCounter = globalContext.symbolIdCounter + 1
    self.keywordIdCounter = globalContext.keywordIdCounter + 1
  }

  override func varIsValid(symbol: InternedSymbol) -> Bool {
    return super.varIsValid(symbol) || globalContext.varIsValid(symbol)
  }

  override func varIsBound(symbol: InternedSymbol) -> Bool {
    return super.varIsBound(symbol) || globalContext.varIsBound(symbol)
  }

  func nameForSymbol(symbol: InternedSymbol) -> String {
    if let name = existingNameForSymbol(symbol) {
      return name
    }
    else if let name = globalContext.existingNameForSymbol(symbol) {
      return name
    }
    // If there is no name for an interned symbol, something is seriously wrong.
    internalError("Previously interned symbol doesn't have a name")
  }

  func symbolForName(name: String) -> InternedSymbol {
    // The symbol comes from either the root context, the global context, or by interning a new symbol.
    return existingSymbolForName(name) ?? (globalContext.existingSymbolForName(name) ?? internSymbol(name))
  }

  func nameForKeyword(keyword: InternedKeyword) -> String {
    if let name = idsToKeywords[keyword] {
      return name
    }
    internalError("Previously interned keyword doesn't have a name")
  }

  func keywordForName(name: String) -> InternedKeyword {
    // The keyword comes from either the root context, the global context, or by interning a new keyword.
    return existingKeywordForName(name) ?? (globalContext.existingKeywordForName(name) ?? internKeyword(name))
  }

  private func retrieveBaseParent() -> BaseContext {
    return self
  }

  func setVar(name: InternedSymbol, value: Binding) {
    self[name] = value
  }

  subscript(x: InternedSymbol) -> Binding {
    get { return bindings[x] ?? (globalContext[x] ?? .Invalid) }
    set { bindings[x] = newValue }
  }

  func log(domain: LogDomain, message: @autoclosure () -> String) {
    interpreter.log(domain, message: message)
  }

  var readInput : InputFunction? { return interpreter.readInput }

  var writeOutput : OutputFunction? { return interpreter.writeOutput }
}

/// Singleton instance for the global context. Created on demand.
private var globalContextInstance : GlobalContext? = nil

/// A class representing the shared base context. This is a global read-only context that every interpreter uses. It
/// contains only the standard library and predefined symbols/keywords.
final private class GlobalContext : BaseContext, Context {

  var root : Context { return self }

  /// Return the singleton instance of the global context.
  class var sharedInstance : GlobalContext {
    if let globalContext = globalContextInstance {
      return globalContext
    }
    // No interpreters have been previously initialized, so create a global context instance.
    let gcInstance = GlobalContext()
    globalContextInstance = gcInstance
    return gcInstance
  }

  override init() {
    super.init()
    // Load standard library into the context
    loadStdlibInto(self, stdlib_files)
  }

  func nameForSymbol(symbol: InternedSymbol) -> String {
    if let name = existingNameForSymbol(symbol) {
      return name
    }
    // If there is no name for an interned symbol, something is seriously wrong.
    internalError("Previously interned symbol doesn't have a name")
  }

  func symbolForName(name: String) -> InternedSymbol {
    return existingSymbolForName(name) ?? internSymbol(name)
  }

  func nameForKeyword(keyword: InternedKeyword) -> String {
    if let name = existingNameForKeyword(keyword) {
      return name
    }
    internalError("Previously interned keyword doesn't have a name")
  }

  func keywordForName(name: String) -> InternedKeyword {
    return existingKeywordForName(name) ?? internKeyword(name)
  }

  func setVar(name: InternedSymbol, value: Binding) {
    self[name] = value
  }

  subscript(x: InternedSymbol) -> Binding {
    get { return bindings[x] ?? .Invalid }
    set { bindings[x] = newValue }
  }

  func log(domain: LogDomain, message: @autoclosure () -> String) {
    // Don't do anything; global context never logs
  }

  var readInput : InputFunction? { return nil }

  var writeOutput : OutputFunction? { return nil }
}

/// A class representing a context representing any lexical scope beneath the global scope.
private class ChildContext : Context {
  var bindings : [InternedSymbol : Binding] = [:]
  let parent : Context
  let root : Context

  func varIsValid(symbol: InternedSymbol) -> Bool {
    return root.varIsValid(symbol)
  }

  func varIsBound(symbol: InternedSymbol) -> Bool {
    return root.varIsBound(symbol)
  }

  func nameForSymbol(symbol: InternedSymbol) -> String {
    return root.nameForSymbol(symbol)
  }

  func symbolForName(name: String) -> InternedSymbol {
    return root.symbolForName(name)
  }

  func nameForKeyword(keyword: InternedKeyword) -> String {
    return root.nameForKeyword(keyword)
  }

  func keywordForName(name: String) -> InternedKeyword {
    return root.keywordForName(name)
  }

  func setVar(name: InternedSymbol, value: Binding) {
    root.setVar(name, value: value)
  }

  subscript(x: InternedSymbol) -> Binding {
    get { return bindings[x] ?? parent[x] }
    set { bindings[x] = newValue }
  }

  init(parent: Context, bindings: [InternedSymbol : Binding]) {
    self.parent = parent
    root = parent.root
    self.bindings = bindings
  }

  func log(domain: LogDomain, message: @autoclosure () -> String) {
    root.log(domain, message: message)
  }

  var readInput : InputFunction? { return root.readInput }

  var writeOutput : OutputFunction? { return root.writeOutput }
}

/// Return a new root Context.
func buildRootContext(# interpreter: Interpreter) -> Context {
  return RootContext(interpreter: interpreter)
}

/// Given a context and additional bindings, return a new child Context.
func buildContext(# parent: Context, # bindings: [InternedSymbol : Binding]) -> Context {
  return ChildContext(parent: parent, bindings: bindings)
}
