//
//  InternedValueStore.swift
//  Cormorant
//
//  Created by Austin Zheng on 12/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum describing hard-coded strings that are automatically interned within the intern store at startup and
/// subsequently available to all code.
enum InternedConstant : String {
  case Core = "core"
  case User = "user"
  case _And = "&"
  case _Ns = "*ns*"
  case _1 = "*1"
  case _2 = "*2"
  case _3 = "*3"
}


// MARK: Two-way dictionary

/// A two-way dictionary containing one-to-one key-value pairings that guarantees similar asymptotic lookup times for
/// both keys and values (but requires twice as much memory as a standard one-way dictionary).
private struct BidirectionalDictionary<T : Hashable, U : Hashable> {
  private var keysToValues : [T : U] = [:]
  private var valuesToKeys : [U : T] = [:]

  func hasKey(key: T) -> Bool { return keysToValues[key] != nil }
  func hasValue(value: U) -> Bool { return valuesToKeys[value] != nil }

  var description : String { return keysToValues.description + "\n" + valuesToKeys.description }

  subscript(key: T) -> U? {
    get {
      return keysToValues[key]
    }
    set {
      // Note that the mapping between keys and values must be one-to-one.
      if let newValue = newValue {
        // Update the value, but only if the new value is not already associated to another key
        precondition(valuesToKeys[newValue] == key || valuesToKeys[newValue] == nil,
          "New value is already associated with a different key: \(valuesToKeys[newValue])")
        if let value = keysToValues[key] {
          valuesToKeys[value] = nil
        }
        valuesToKeys[newValue] = key
        keysToValues[key] = newValue
      }
      else {
        // Remove this key-value pair from the dictionary.
        if let value = keysToValues[key] {
          keysToValues[key] = nil
          valuesToKeys[value] = nil
        }
      }
    }
  }

  subscript(value: U) -> T? {
    get {
      return valuesToKeys[value]
    }
    set(newKey) {
      // Note that the mapping between keys and values must be one-to-one.
      if let newKey = newKey {
        // Update the value, but only if the new value is not already associated to another key
        precondition(keysToValues[newKey] == value || keysToValues[newKey] == nil,
          "New key is already associated with a different value: \(keysToValues[newKey])")
        if let key = valuesToKeys[value] {
          keysToValues[key] = nil
        }
        valuesToKeys[value] = newKey
        keysToValues[newKey] = value
      }
      else {
        // Remove this key-value pair from the dictionary.
        if let key = valuesToKeys[value] {
          valuesToKeys[value] = nil
          keysToValues[key] = nil
        }
      }
    }
  }
}


// MARK: Interned value store

/// An interned string. Interned strings form the basis of interned symbols, keywords, and namespaces.
typealias InternedString = UInt

/// A module that handles interning keywords and symbols, and generating gensyms, for a given interpreter.
final class InternedValueStore {
  private var internedNames = BidirectionalDictionary<String, InternedString>()
  private var identifierCounter : UInt = 0
  private var gensymCounter : UInt = 0

  /// Produce a gensym. Gensyms are always unqualified.
  func produceGensym(prefix: String, suffix: String?) -> InternedSymbol {
    let name = "\(prefix)\(gensymCounter)" + (suffix ?? "")
    gensymCounter += 1
    return InternedSymbol(name, namespace: nil, ivs: self)
  }

  /// Given an interned string, return the actual string. The interned string must be valid.
  func name(forInternedString interned: InternedString) -> String {
    if let name = internedNames[interned] {
      return name
    }
    preconditionFailure("Previously interned string doesn't have a name")
  }

  /// Given a string representing a symbol or other identifier, return the corresponding interned string value.
  func internedString(forName name: String) -> InternedString {
    if let internedName = internedNames[name] {
      return internedName
    }
    else {
      // Intern the namespace's name, and return a new namespace.
      let newNs = identifierCounter
      identifierCounter += 1
      internedNames[newNs] = name
      return newNs
    }
  }


  // MARK: Predefined symbols
  private let s_core, s_user, s__and, s__ns, s_1, s_2, s_3 : InternedString

  /// Given the name of an interned constant, return the corresponding interned string value.
  func internedString(for name: InternedConstant) -> InternedString {
    switch name {
    case .Core: return s_core
    case .User: return s_user
    case ._And: return s__and
    case ._Ns: return s__ns
    case ._1: return s_1
    case ._2: return s_2
    case ._3: return s_3
    }
  }

  /// Given the name of an interned constant, return the corresponding unqualified symbol.
  func internedSymbol(for name: InternedConstant) -> InternedSymbol {
    return InternedSymbol(internedString(for: name))
  }

  /// Given the name of an interned constant, return the corresponding unqualified keyword.
  func internedKeyword(for name: InternedConstant) -> InternedKeyword {
    return InternedKeyword(internedString(for: name))
  }


  // MARK: Initializer

  init() {
    internedNames = BidirectionalDictionary<String, InternedString>()

    // Set up the predefined constants
    var ctr : InternedString = 0
    s_core = ctr; internedNames[ctr] = InternedConstant.Core.rawValue; ctr += 1
    s_user = ctr; internedNames[ctr] = InternedConstant.User.rawValue; ctr += 1
    s__and = ctr; internedNames[ctr] = InternedConstant._And.rawValue; ctr += 1
    s__ns = ctr; internedNames[ctr] = InternedConstant._Ns.rawValue; ctr += 1
    s_1 = ctr; internedNames[ctr] = InternedConstant._1.rawValue; ctr += 1
    s_2 = ctr; internedNames[ctr] = InternedConstant._2.rawValue; ctr += 1
    s_3 = ctr; internedNames[ctr] = InternedConstant._3.rawValue; ctr += 1

    identifierCounter = ctr
    gensymCounter = 0
  }
}


// MARK: Interned types

/// An value representing an interned symbol. This is a lightweight fixed-size struct. There is a one-to-one mapping
/// between every symbol name used in the program (no matter the context) and a distinct InternedSymbol value.
public struct InternedSymbol : Hashable {
  let identifier : InternedString

  /// If the symbol is qualified, a NamespaceName representing the name of the symbol's namespace.
  let ns : NamespaceName?

  /// An interned string representing the qualified name of the symbol, which is the namespace and identifier joined by
  /// a forward slash (e.g. "foo/mySymbol").
  let qualified : InternedString

  public var hashValue : Int { return identifier.hashValue }

  /// Return an unqualified (no namespace) version of the symbol.
  var unqualified : InternedSymbol {
    return InternedSymbol(identifier)
  }

  var isUnqualified : Bool { return ns == nil }

  /// Return a description of the object, using the literal values of the interned identifier and namespace.
  var rawDescription : String {
    if let ns = ns {
      return "ns:\(ns)/id:\(identifier)"
    }
    return "id:\(identifier)"
  }

  /// Get the symbol's actual name.
  func nameComponent(_ ctx: Context) -> String {
    return ctx.ivs.name(forInternedString: identifier)
  }

  /// Get the symbol's actual namespace.
  func namespaceComponent(_ ctx: Context) -> String? {
    if let ns = ns {
      return ns.asString(ctx.ivs)
    }
    return nil
  }

  /// Get the symbol's actual name, including the namespace if it's qualified.
  func fullName(_ ctx: Context) -> String {
    let symbolName = nameComponent(ctx)
    if let namespace = namespaceComponent(ctx) {
      return "\(namespace)/\(symbolName)"
    }
    return symbolName
  }

  init(_ identifier: InternedString) {
    self.identifier = identifier; ns = nil; qualified = identifier
  }

  init(_ name: String, namespace nsName: String? = nil, ivs: InternedValueStore) {
    identifier = ivs.internedString(forName: name)
    if let nsName = nsName {
      ns = NamespaceName(InternedSymbol(ivs.internedString(forName: nsName)))
      qualified = ivs.internedString(forName: "\(name)/\(nsName)")
    }
    else {
      ns = nil
      qualified = identifier
    }
  }
}

public func ==(lhs: InternedSymbol, rhs: InternedSymbol) -> Bool {
  return lhs.qualified == rhs.qualified
}

/// A value representing an interned keyword.
public struct InternedKeyword : Hashable {
  let identifier : InternedString
  let ns : NamespaceName?
  let qualified : InternedString

  public var hashValue : Int { return identifier.hashValue }
  var isUnqualified : Bool { return ns == nil }

  /// Return an unqualified (no namespace) version of the keyword.
  var unqualified : InternedKeyword {
    return InternedKeyword(identifier)
  }

  /// Return a description of the object, using the literal values of the interned identifier and namespace.
  var rawDescription : String {
    if let ns = ns {
      return "ns:\(ns)/id:\(identifier)"
    }
    return "id:\(identifier)"
  }

  /// Get the keyword's actual name.
  func nameComponent(_ ctx: Context) -> String {
    return ctx.ivs.name(forInternedString: identifier)
  }

  /// Get the keyword's actual namespace.
  func namespaceComponent(_ ctx: Context) -> String? {
    if let ns = ns {
      return ns.asString(ctx.ivs)
    }
    return nil
  }

  /// Get the keyword's actual name, including a namespace if one exists.
  func fullName(_ ctx: Context) -> String {
    let keywordName = nameComponent(ctx)
    if let namespace = namespaceComponent(ctx) {
      return ":\(namespace)/\(keywordName)"
    }
    return ":\(keywordName)"
  }

  private init(_ identifier: InternedString) {
    self.identifier = identifier; ns = nil; qualified = identifier
  }

  init(symbol: InternedSymbol) {
    identifier = symbol.identifier; ns = symbol.ns; qualified = symbol.qualified
  }

  init(_ name: String, namespace nsName: String? = nil, ivs: InternedValueStore) {
    precondition(!name.isEmpty, "The name of a symbol cannot be an empty string")
    precondition(nsName?.isEmpty != true, "If present, the namespace of a symbol cannot be an empty string")
    identifier = ivs.internedString(forName: name)
    if let nsName = nsName {
      ns = NamespaceName(InternedSymbol(ivs.internedString(forName: nsName)))
      qualified = ivs.internedString(forName: "\(name)/\(nsName)")
    }
    else {
      ns = nil
      qualified = identifier
    }
  }
}

public func ==(lhs: InternedKeyword, rhs: InternedKeyword) -> Bool {
  return lhs.qualified == rhs.qualified
}

struct NamespaceName : Hashable {
  let name : InternedString
  let isUnqualified : Bool

  var hashValue : Int { return name.hashValue }

  /// Return an InternedSymbolResult that represents the symbol naming this namespace.
  func asSymbol(_ ivs: InternedValueStore) -> EvalOptional<InternedSymbol> {
    if isUnqualified {
      return .Just(InternedSymbol(name))
    }
    else {
      // Slow path: retrieve the string and parse the string back into a symbol
      let fqn = ivs.name(forInternedString: name)
      switch split(symbol: fqn) {
      case let .Just(symbolStruct):
        let name = symbolStruct.name
        let namespaceName = symbolStruct.namespace
        return .Just(InternedSymbol(name, namespace: namespaceName, ivs: ivs))
      case let .Error(err):
        return .Error(EvalError.readError(forFn: "(none)", error: err))
      }
    }
  }

  func asString(_ ivs: InternedValueStore) -> String {
    return ivs.name(forInternedString: name)
  }

  init(_ symbol: InternedSymbol) {
    name = symbol.qualified
    isUnqualified = symbol.ns == nil
  }
}

func ==(lhs: NamespaceName, rhs: NamespaceName) -> Bool {
  return lhs.name == rhs.name
}

typealias UnqualifiedSymbol = InternedSymbol
typealias UnqualifiedKeyword = InternedKeyword
