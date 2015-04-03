//
//  context.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// A protocol representing the execution context of a given form. Contexts represent the lexical environment of a
/// function, loop, or let-scoped block, unifying both local bindings and Vars. They also mediate access to other
/// mutable interpreter state, such as I/O and gensym. Contexts chain together to form a 'spaghetti stack'.
protocol Context : class {
  /// Get a reference to the interpreter.
  var interpreter : Interpreter { get }

  /// Get a reference to the interned value store.
  var ivs : InternedValueStore { get }

  /// Get a reference to the namespace context that serves as the root parent for this context.
  var root : NamespaceContext { get }

  /// Given the interned string describing a symbol, retrieve the topmost valid binding or Var for it.
  subscript(x: UnqualifiedSymbol) -> ConsValue? { get }

  /// Given a symbol that might be qualified, resolve the binding or Var to which the symbol refers. If the symbol is
  /// unqualified, the binding is resolved locally; in particular, refers are considered. If the symbol is qualified,
  /// the lookup happens through the interpreter.
  func resolveBindingForSymbol(symbol: InternedSymbol) -> ConsValue?
}


// MARK: Namespace context

public func ==(lhs: NamespaceContext, rhs: NamespaceContext) -> Bool {
  return lhs === rhs
}

/// A context which represents a namespace.
final public class NamespaceContext : Context, Hashable {
  unowned let interpreter : Interpreter

  /// Whether or not this namespace is deleted. Deleted namespaces cannot alias or refer other namespaces, and have
  /// other limitations on what they can do.
  private(set) var isDeleted : Bool = false

  /// Denotes whether this context represents a system namespace. System namespaces cannot be switched to or deleted.
  public let isSystemNamespace : Bool
  let internedName : NamespaceName
  public let name : String

  /// A map from symbols interned within this namespace to Vars.
  private(set) var vars : [UnqualifiedSymbol : VarType] = [:]

  /// A map from refer'ed symbols (that reside within other namespaces) to Vars.
  private(set) var refers : [UnqualifiedSymbol : VarType] = [:]

  /// Namespace aliases. Keys are alias names; values are references to the namespaces.
  private(set) var aliases : [NamespaceName : NamespaceContext] = [:]
  /// A set containing any aliases which are set to resolve to this namespace. This prevents reference cycles.
  private(set) var selfAliases = Set<NamespaceName>()

  var ivs : InternedValueStore { return interpreter.internStore }
  var root : NamespaceContext { return self }

  public var hashValue : Int { return ObjectIdentifier(self).hashValue }


  // MARK: Namespace API

  /// Clean up a namespace in preparation for its removal.
  func prepareForRemoval() {
    isDeleted = true
    // Remove all aliases to prevent retain cycles
    aliases.removeAll(keepCapacity: false)
  }

  /// Register an alias for another namespace.
  func alias(namespace: NamespaceContext, usingAlias a: NamespaceName) -> EvalError? {
    precondition(interpreter.namespaces[namespace.internedName] != nil,
      "Namespace being aliased must exist in interpreter")
    if isDeleted {
      return nil
    }
    // Note that 'a' can only exist in one of aliases or selfAliases
    if let existingNamespace = aliases[a] where !(namespace === existingNamespace) {
      // Redefining an alias that currently points to a non-self namespace to point to another namespace (not allowed)
      return EvalError(.AliasRebindingError)
    }
    else if selfAliases.contains(a) && !(namespace === self) {
      // Redefining an alias that currently points to 'self' to point to another namespace (not allowed)
      return EvalError(.AliasRebindingError)
    }
    if namespace === self {
      selfAliases.insert(a)
      aliases.removeValueForKey(a)
    }
    else {
      aliases[a] = namespace
      selfAliases.remove(a)
    }
    return nil
  }

  /// Unregister an alias for another namespace. Returns whether or not the alias is valid.
  func unalias(a: NamespaceName) -> Bool {
    return aliases.removeValueForKey(a) != nil || selfAliases.remove(a) != nil
  }

  /// Return a map of all aliases, each key-value pair matching a symbol to a Namespace object.
  func aliasesAsMap() -> EvalResult {
    var buffer : MapType = [:]
    // Add all aliases to other namespaces
    for (alias, namespace) in aliases {
      switch alias.asSymbol(interpreter.internStore) {
      case let .Symbol(sym):
        buffer[.Symbol(sym)] = .Namespace(namespace)
      case let .Error(err):
        // Not expected to ever get here
        return .Failure(err)
      }
    }
    // Add all aliases to this namespace
    for alias in selfAliases {
      switch alias.asSymbol(interpreter.internStore) {
      case let .Symbol(sym):
        buffer[.Symbol(sym)] = .Namespace(self)
      case let .Error(err):
        // Not expected to ever get here
        return .Failure(err)
      }
    }
    return .Success(.Map(buffer))
  }

  /// Given a symbol, return the Var to which that symbol would resolve within this namespace, if any.
  func resolveSymbolFor(symbol: InternedSymbol) -> VarType? {
    if let ns = symbol.ns where ns != internedName {
      // Symbol is qualified with a namespace not the same as this one
      if let aliasedNamespace = aliases[ns] {
        // Namespace of this symbol is an alias for another namespace
        return aliasedNamespace.resolveSymbolFor(symbol)
      }
      else if selfAliases.contains(ns) {
        // Namespace of this symbol is an alias to this namespace
        return vars[symbol.unqualified]
      }
      else if let otherNamespace = interpreter.namespaces[ns] {
        // Namespace of this symbol is another real namespace
        return otherNamespace.resolveSymbolFor(symbol)
      }
      // Symbol can't be resolved
      return nil
    }
    else {
      // Symbol is unqualified, or qualified to this namespace
      if vars[symbol.unqualified] != nil {
        // Var can be found in this namespace
        return vars[symbol.unqualified]
      }
      else if let next = refers[symbol.unqualified] {
        // Symbol resolves to a refer binding
        return next
      }
      // Symbol can't be resolved
      return nil
    }
  }

  /// Given another namespace, refer it by mapping all its Vars.
  func refer(namespace: NamespaceContext) -> EvalError? {
    if namespace === self || isDeleted {
      return nil
    }
    for (symbol, aVar) in namespace.vars {
      let unqualified = symbol.unqualified
      if vars[unqualified] != nil {
        // Do nothing
      }
      if let otherRefer = refers[unqualified] where otherRefer.name.ns != namespace.internedName {
        // Trying to refer a symbol that was previously referred from another namespace; this is an error
        return EvalError(.VarRebindingError)
      }
      // Unbind the existing Var, if one exists
      vars.removeValueForKey(unqualified)
      refers[unqualified] = aVar
    }
    return nil
  }

  /// Given another namespace name, map all the namespace's bindings into this namespace.
  func refer(ns: NamespaceName) -> EvalError? {
    if let namespace = interpreter.namespaces[ns] {
      return refer(namespace)
    }
    return EvalError(.InvalidNamespaceError)
  }

  /// Return a map of all refers, each key-value pair matching a symbol to a Var.
  func refersAsMap() -> MapType {
    var buffer : MapType = [:]
    for (symbol, aVar) in refers {
      buffer[.Symbol(symbol)] = .Var(aVar)
    }
    return buffer
  }

  /// Return a map of all locally stored values, each key-value pair matching a symbol to a Var.
  func internsAsMap() -> MapType {
    var buffer : MapType = [:]
    for (symbol, aVar) in vars {
      let symbolName = symbol.nameComponent(self)
      buffer[.Symbol(symbol)] = .Var(aVar)
    }
    return buffer
  }


  // MARK: Context API

  /// Return whether the given symbol corresponds to a bound, valid Var.
  func varIsValid(symbol: UnqualifiedSymbol) -> Bool {
    return vars[symbol]?.isBound == true
  }

//  var debugDescription : String {
//    let descs : [String] = map(vars) { symbol, binding in
//      let symbolDesc = "\"\(symbol.fullName(self))\"(\(symbol.identifier))"
//      return "\(symbolDesc) : \(binding.description)"
//    }
//    return "NamespaceContext"
//      + (isSystemNamespace ? "(system)" : "")
//      + ":\nVars: [\n"
//      + join("\n", descs)
//      + "\n]\nAliases: \(aliases)\nSelf aliases: \(selfAliases)"
//  }

  /// Create a new unbound Var, or unbind a locally interned Var.
  func setUnboundVar(varName: UnqualifiedSymbol, shouldUnbind: Bool) -> VarResult {
    if let thisVar = vars[varName] {
      if thisVar.isBound && shouldUnbind == false {
        // Don't unbind the var, just return it
        return .Var(thisVar)
      }
      // Don't do anything for now
      return .Var(thisVar)
    }
    if let alreadyReferred = refers[varName] {
      return .Error(EvalError(.VarRebindingError))
    }
    else {
      // Create a new Var and intern it
      let qualifiedName = InternedSymbol(varName.nameComponent(self), namespace: name, ivs: ivs)
      let newVar = VarType(qualifiedName, value: nil)
      vars[qualifiedName.unqualified] = newVar
      return .Var(newVar)
    }
  }

  /// Create or update a binding between a symbol and a Var.
  func setVar(varName: UnqualifiedSymbol, newValue: ConsValue) -> VarResult {
    if let alreadyReferred = refers[varName] {
      // If we've referred this var before, we should error out if the referred var isn't in a system namespace
      if let ns = alreadyReferred.name.ns where interpreter.namespaces[ns]?.isSystemNamespace == true {
        alreadyReferred.bindValue(newValue)
        return .Var(alreadyReferred)
      }
      return .Error(EvalError(.VarRebindingError))
    }
    else if let alreadyInterned = vars[varName] {
      // The Var was previously interned locally; update it
      alreadyInterned.bindValue(newValue)
      return .Var(alreadyInterned)
    }
    else {
      // Create a new Var and intern it
      let qualifiedName = InternedSymbol(varName.nameComponent(self), namespace: name, ivs: ivs)
      let newVar = VarType(qualifiedName, value: newValue)
      vars[qualifiedName.unqualified] = newVar
      return .Var(newVar)
    }
  }

  /// Remove a Var from the mapping dictionary.
  func unmapVar(name: UnqualifiedSymbol) {
    vars.removeValueForKey(name)
  }

  /// Retrieve the interned Var corresponding to the given unqualified symbol. This method does not look up any symbols
  /// that have been locally aliased by a call to 'refer'. This method should only be called by the interpreter when
  /// resolving a qualified symbol.
  func resolveVar(symbol: UnqualifiedSymbol) -> ConsValue? {
    return vars[symbol]?.value(usingContext: self)
  }

  func resolveBindingForSymbol(symbol: InternedSymbol) -> ConsValue? {
    if let ns = symbol.ns {
      // Check to see if ns is mapped in the aliases dictionary to a namespace already
      if let aliasedNamespace = aliases[ns] {
        return aliasedNamespace.resolveVar(symbol.unqualified)
      }
      else if selfAliases.contains(ns) {
        // Alias is for this namespace; resolve the Var (note that refers aren't examined in this case)
        return resolveVar(symbol.unqualified)
      }
      return interpreter.resolveBinding(symbol.unqualified, inNamespace: ns)
    }
    else {
      // Unqualified symbol; resolve locally
      return self[symbol.unqualified]
    }
  }

  // Note: subscript should only be used for the case where symbols are being resolved when this namespace is the
  // current namespace. It looks up both interned Vars as well as refer'ed Vars.
  subscript(symbol: UnqualifiedSymbol) -> ConsValue? {
    get {
      precondition(symbol.ns == nil,
        "Symbol \(symbol.fullName(self)) passed into NamespaceContext's subscript was not unqualified")
      if let local = vars[symbol] {
        return local.value(usingContext: self)
      }
      else if let reference = refers[symbol] {
        return reference.value(usingContext: self)
      }
      return nil
    }
  }

  init(interpreter: Interpreter, ns: NamespaceName, asSystemNamespace isSystem: Bool = false) {
    self.interpreter = interpreter
    internedName = ns
    name = interpreter.internStore.nameForInternedString(ns.name)
    isSystemNamespace = isSystem
  }
}


// MARK: Lexical scope context

/// A class representing a context representing any lexical scope created by a fn, let, or loop.
final class LexicalScopeContext : Context {
  private var otherBindings : [UnqualifiedSymbol : ConsValue]? = nil
  private let parent : Context
  let root : NamespaceContext

  // A ChildContext houses up to 16 symbols locally. This allows it to avoid using the dictionary if possible.
  var b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14, b15 : (symbol: UnqualifiedSymbol, binding: ConsValue)?
  private var count = 0

  /// Push a binding into the context.
  func pushBinding(binding: ConsValue, forSymbol symbol: UnqualifiedSymbol) {
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
  private func findBindingForSymbol(symbol: UnqualifiedSymbol) -> ConsValue? {
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
  func updateBinding(binding: ConsValue, forSymbol symbol: UnqualifiedSymbol) {
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
    preconditionFailure("Binding passed into this function was not previously declared; this is a logic error")
  }

  var interpreter : Interpreter { return root.interpreter }
  var ivs : InternedValueStore { return root.ivs }

  func resolveBindingForSymbol(symbol: InternedSymbol) -> ConsValue? {
    return findBindingForSymbol(symbol) ?? parent.resolveBindingForSymbol(symbol)
  }

  subscript(x: UnqualifiedSymbol) -> ConsValue? {
    get { return findBindingForSymbol(x) ?? parent[x] }
  }

  init(parent: Context) {
    self.parent = parent
    root = parent.root
  }
}
