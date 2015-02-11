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

  /// Return a unique gensym.
  func produceGensym(prefix: String, suffix: String?) -> InternedSymbol

  /// Given an interned symbol, return its name.
  func nameForSymbol(symbol: InternedSymbol) -> String

  /// Given a symbol name, create and/or return an interned symbol.
  func symbolForName(name: String) -> InternedSymbol

  /// Given an interned keyword, return its name.
  func nameForKeyword(keyword: InternedKeyword) -> String

  /// Given a keyword name, create and/or return an interned keyword.
  func keywordForName(name: String) -> InternedKeyword

  /// Write a message to the interpreter logging facility.
  func log(domain: LogDomain, message: () -> String)

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

  var keywordsToIds : [String : InternedKeyword] = [:]
  var idsToKeywords : [InternedKeyword : String] = [:]

  var identifierCounter : UInt = 0
  var gensymCounter : UInt = 0

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

  func produceGensym(prefix: String, suffix: String?) -> InternedSymbol {
    let name = "\(prefix)\(gensymCounter)" + (suffix ?? "")
    gensymCounter += 1
    return internSymbol(name)
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
    let newSymbol = InternedSymbol(identifierCounter)
    identifierCounter += 1
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
    let newKeyword = InternedKeyword(identifierCounter)
    identifierCounter += 1
    keywordsToIds[name] = newKeyword
    idsToKeywords[newKeyword] = name
    return newKeyword
  }
}

/// A class representing the root context for a given interpreter instance. This context is responsible for interning
/// keywords and symbols, producing gensyms, and certain other responsibilities.
private final class RootContext : BaseContext, Context {
  unowned let interpreter : Interpreter
  let globalContext = GlobalContext.sharedInstance

  var root : Context { return self }

  init(interpreter: Interpreter) {
    self.interpreter = interpreter
    // Start ID counters after those for the base context
    super.init()
    identifierCounter = globalContext.identifierCounter + 1
    gensymCounter = globalContext.gensymCounter + 1
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

  func log(domain: LogDomain, message: () -> String) {
    interpreter.log(domain, message: message)
  }

  var readInput : InputFunction? { return interpreter.readInput }

  var writeOutput : OutputFunction? { return interpreter.writeOutput }
}

/// Singleton instance for the global context. Created on demand.
private var globalContextInstance : GlobalContext? = nil

/// A class representing the shared base context. This is a global read-only context that every interpreter uses. It
/// contains only the standard library and predefined symbols/keywords.
private final class GlobalContext : BaseContext, Context {

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

  func log(domain: LogDomain, message: () -> String) {
    // Don't do anything; global context never logs
  }

  var readInput : InputFunction? { return nil }

  var writeOutput : OutputFunction? { return nil }
}

/// A class representing a context representing any lexical scope beneath the global scope.
final class ChildContext : Context {
  private var otherBindings : [InternedSymbol : Binding]? = nil
  private let parent : Context
  let root : Context

  // A ChildContext houses up to 16 symbols locally. This allows it to avoid using the dictionary if possible.
  var b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15 : (symbol: InternedSymbol, binding: Binding)?
  private var count = 0

  func varIsValid(symbol: InternedSymbol) -> Bool {
    return root.varIsValid(symbol)
  }

  func varIsBound(symbol: InternedSymbol) -> Bool {
    return root.varIsBound(symbol)
  }

  func produceGensym(prefix: String, suffix: String?) -> InternedSymbol {
    return root.produceGensym(prefix, suffix: suffix)
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

  /// Push a binding into the context.
  func pushBinding(binding: Binding, forSymbol symbol: InternedSymbol) {
    if findBindingForSymbol(symbol) != nil {
      updateBinding(binding, forSymbol: symbol)
      return
    }
    switch count {
    case 0: b0 = (symbol, binding)
    case 1: b1 = (symbol, binding)
    case 2: b2 = (symbol, binding)
    case 3: b3 = (symbol, binding)
    case 4: b4 = (symbol, binding)
    case 5: b5 = (symbol, binding)
    case 6: b6 = (symbol, binding)
    case 7: b7 = (symbol, binding)
    case 8: b8 = (symbol, binding)
    case 9: b9 = (symbol, binding)
    case 10: b10 = (symbol, binding)
    case 11: b11 = (symbol, binding)
    case 12: b12 = (symbol, binding)
    case 13: b13 = (symbol, binding)
    case 14: b14 = (symbol, binding)
    case 15: b15 = (symbol, binding)
    default:
      if otherBindings != nil {
        self.otherBindings?[symbol] = binding
      }
      else {
        otherBindings = [symbol : binding]
      }
    }
    count += 1
  }

  /// Given a symbol, try to look up the corresponding binding.
  private func findBindingForSymbol(symbol: InternedSymbol) -> Binding? {
    if let b0 = b0 where b0.symbol == symbol {
      return b0.binding
    }
    if let b1 = b1 where b1.symbol == symbol {
      return b1.binding
    }
    if let b2 = b2 where b2.symbol == symbol {
      return b2.binding
    }
    if let b3 = b3 where b3.symbol == symbol {
      return b3.binding
    }
    if let b4 = b4 where b4.symbol == symbol {
      return b4.binding
    }
    if let b5 = b5 where b5.symbol == symbol {
      return b5.binding
    }
    if let b6 = b6 where b6.symbol == symbol {
      return b6.binding
    }
    if let b7 = b7 where b7.symbol == symbol {
      return b7.binding
    }
    if let b8 = b8 where b8.symbol == symbol {
      return b8.binding
    }
    if let b9 = b9 where b9.symbol == symbol {
      return b9.binding
    }
    if let b10 = b10 where b10.symbol == symbol {
      return b10.binding
    }
    if let b11 = b11 where b11.symbol == symbol {
      return b11.binding
    }
    if let b12 = b12 where b12.symbol == symbol {
      return b12.binding
    }
    if let b13 = b13 where b13.symbol == symbol {
      return b13.binding
    }
    if let b14 = b14 where b14.symbol == symbol {
      return b14.binding
    }
    if let b15 = b15 where b15.symbol == symbol {
      return b15.binding
    }
    return otherBindings?[symbol]
  }

  /// Given a symbol which should already exist in the context, update its value. The precondition is that the symbol
  /// already exists in the context (otherwise, the pushBinding function should be used to add it).
  private func updateBinding(binding: Binding, forSymbol symbol: InternedSymbol) {
    if let b0 = b0 where b0.symbol == symbol {
      self.b0 = (symbol, binding)
      return
    }
    if let b1 = b1 where b1.symbol == symbol {
      self.b1 = (symbol, binding)
      return
    }
    if let b2 = b2 where b2.symbol == symbol {
      self.b2 = (symbol, binding)
      return
    }
    if let b3 = b3 where b3.symbol == symbol {
      self.b3 = (symbol, binding)
      return
    }
    if let b4 = b4 where b4.symbol == symbol {
      self.b4 = (symbol, binding)
      return
    }
    if let b5 = b5 where b5.symbol == symbol {
      self.b5 = (symbol, binding)
      return
    }
    if let b6 = b6 where b6.symbol == symbol {
      self.b6 = (symbol, binding)
      return
    }
    if let b7 = b7 where b7.symbol == symbol {
      self.b7 = (symbol, binding)
      return
    }
    if let b8 = b8 where b8.symbol == symbol {
      self.b8 = (symbol, binding)
      return
    }
    if let b9 = b9 where b9.symbol == symbol {
      self.b9 = (symbol, binding)
      return
    }
    if let b10 = b10 where b10.symbol == symbol {
      self.b10 = (symbol, binding)
      return
    }
    if let b11 = b11 where b11.symbol == symbol {
      self.b11 = (symbol, binding)
      return
    }
    if let b12 = b12 where b12.symbol == symbol {
      self.b12 = (symbol, binding)
      return
    }
    if let b13 = b13 where b13.symbol == symbol {
      self.b13 = (symbol, binding)
      return
    }
    if let b14 = b14 where b14.symbol == symbol {
      self.b14 = (symbol, binding)
      return
    }
    if let b15 = b15 where b15.symbol == symbol {
      self.b15 = (symbol, binding)
      return
    }
    if let value = otherBindings?[symbol] {
      self.otherBindings?[symbol] = value
      return
    }
    internalError("Previously-existing binding was not found. This is an interpreter logic error.")
  }

  subscript(x: InternedSymbol) -> Binding {
    get { return findBindingForSymbol(x) ?? parent[x] }
    set { updateBinding(newValue, forSymbol: x) }
  }

  init(parent: Context) {
    self.parent = parent
    root = parent.root
  }

  func log(domain: LogDomain, message: () -> String) {
    root.log(domain, message: message)
  }

  var readInput : InputFunction? { return root.readInput }

  var writeOutput : OutputFunction? { return root.writeOutput }
}

/// Return a new root Context.
func buildRootContext(# interpreter: Interpreter) -> Context {
  return RootContext(interpreter: interpreter)
}
