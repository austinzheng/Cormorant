//
//  interpreter.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// An opaque struct representing a ConsValue.
public struct Form {
  internal let value : ConsValue
  internal init(_ value: ConsValue) { self.value = value }
}

/// An enum describing possible results from evaluating an input to the interpreter.
public enum Result {
  case Success(ConsValue)
  case ReadFailure(ReadError)
  case EvalFailure(EvalError)
}

/// An enum describing logging domains that can be individually enabled or disabled as necessary.
public enum LogDomain : String {
  case Eval = "eval"

  static var allDomains : [LogDomain] { return [.Eval] }
}

typealias LoggingFunction = (() -> String) -> ()

/// An opaque type representing a function allowing the interpreter to write output.
public typealias OutputFunction = (String) -> ()

/// An opaque type representing a function allowing the intepreter to read input.
public typealias InputFunction = () -> String

/// A class representing a Lambdatron interpreter.
public class Interpreter {
  var userNamespaceName : NamespaceName { return NamespaceName(internStore.internedSymbolFor(.User)) }
  var coreNamespaceName : NamespaceName { return NamespaceName(internStore.internedSymbolFor(.Core)) }

  /// The core namespace.
  private var coreNamespace : NamespaceContext?

  /// The currently active namespace. There must always be an active namespace.
  private(set) var currentNamespace : NamespaceContext! {
    willSet {
      // Namespace is being changed; change *ns* as well
      if let core = coreNamespace, newValue = newValue {
        core.setVar(internStore.internedSymbolFor(._Ns), newValue: .Namespace(newValue))
      }
    }
  }

  var currentNsName : NamespaceName! { return currentNamespace.internedName }
  var currentNsNameString : String! { return currentNamespace.name }

  /// All namespaces registered to this interpreter.
  private(set) var namespaces : [NamespaceName : NamespaceContext] = [:]

  let internStore = InternedValueStore()
  var evalLogging : LoggingFunction? = nil


  // MARK: Public API

  /// A function that the interpreter calls in order to write out data. Defaults to 'print'.
  public var writeOutput : OutputFunction? = print

  /// A function that the interpreter calls in order to read in data.
  public var readInput : InputFunction? = nil

  /// Given a string, evaluate it as Lambdatron code and return a successful result or error.
  public func evaluate(form: String) -> Result {
    let context = currentNamespace
    let lexed = lex(form)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.expand(context)
        switch expanded {
        case let .Success(expanded):
          let result = evaluateForm(expanded, context)
          switch result {
          case let .Success(s): return .Success(s)
          case .Recur:
            return .EvalFailure(EvalError(.RecurMisuseError, message: "recur object was returned to the top level"))
          case let .Failure(f): return .EvalFailure(f)
          }
        case let .Failure(f): return .ReadFailure(f)
        }
      case let .Failure(f): return .ReadFailure(f)
      }
    case let .Failure(f): return .ReadFailure(f)
    }
  }

  /// Given a form, evaluate it and return a successful result or error.
  public func evaluate(form: Form) -> Result {
    let context = currentNamespace
    let result = evaluateForm(form.value, context)
    switch result {
    case let .Success(s): return .Success(s)
    case .Recur:
      return .EvalFailure(EvalError(.RecurMisuseError, message: "recur object was returned to the top level"))
    case let .Failure(f): return .EvalFailure(f)
    }
  }

  /// Given a string, return a form that can be directly evaluated later or repeatedly.
  public func readIntoForm(form: String) -> Form? {
    let context = currentNamespace
    let lexed = lex(form)
    switch lexed {
    case let .Success(lexed):
      let parsed = parse(lexed, context)
      switch parsed {
      case let .Success(parsed):
        let expanded = parsed.expand(context)
        switch expanded {
        case let .Success(expanded):
          return Form(expanded)
        case .Failure: return nil
        }
      case .Failure: return nil
      }
    case .Failure: return nil
    }
  }

  /// Given a Lambdatron form, return a prettified description.
  public func describe(form: ConsValue) -> DescribeResult {
    return form.describe(currentNamespace)
  }

  /// Reset the interpreter, removing any Vars or other state. This does not affect the logging, input, or output
  /// functions.
  public func reset() {
    // Remove all non-system namespaces from the namespace store.
    var toRemove : [NamespaceName] = []
    for (ns, namespace) in namespaces {
      if !namespace.isSystemNamespace {
        toRemove.append(ns)
      }
    }
    for ns in toRemove {
      namespaces.removeValueForKey(ns)
    }

    // Create a new "user" namespace, and set it as current.
    let user = NamespaceContext(interpreter: self, ns: userNamespaceName)
    namespaces[userNamespaceName] = user
    if let core = namespaces[coreNamespaceName] {
      user.refer(core)
    }
    else {
      internalError("Core namespace could not be found. This is an interpreter logic error.")
    }
    currentNamespace = user
  }


  // MARK: Internal API

  /// Given a domain and a message, pass the message on to the appropriate logging function (if one exists).
  func log(domain: LogDomain, message: () -> String) {
    switch domain {
    case .Eval:
      evalLogging?(message)
    }
  }

  /// Given a domain and a function, set the function as a designated handler for logging messages in the domain.
  func setLoggingFunction(domain: LogDomain, function: LoggingFunction) {
    switch domain {
    case .Eval:
      evalLogging = function
    }
  }

  /// Look up the Var bound to a symbol in a particular namespace.
  func resolveBinding(symbol: UnqualifiedSymbol, inNamespace ns: NamespaceName) -> ConsValue? {
    if let namespace = namespaces[ns] {
      return namespace.resolveVar(symbol)
    }
    // Namespace in question doesn't exist; very sad
    return nil
  }


  // MARK: Namespace API

  enum NamespaceResult {
    case Success(NamespaceContext)
    case Nil
    case Error(EvalError)
  }

  /// Given a symbol and a namespace, unmap the symbol from the namespace.
  func unmapVar(symbol: UnqualifiedSymbol, fromNamespace namespace: NamespaceContext) -> EvalError? {
    precondition(namespaces[namespace.internedName] != nil,
      "Namespace being unmapped must exist in interpreter")
    if namespace.isSystemNamespace {
      return EvalError(.ReservedNamespaceError)
    }
    namespace.unmapVar(symbol)
    return nil
  }

  /// Given an alias (to some other namespace) and a namespace name, remove the alias from that namespace.
  func removeAlias(alias: NamespaceName, fromNamespace namespace: NamespaceContext) -> EvalError? {
    precondition(namespaces[namespace.internedName] != nil,
      "Namespace for which alias is being removed must exist in interpreter")
    if namespace.isSystemNamespace {
      return EvalError(.ReservedNamespaceError)
    }
    namespace.unalias(alias)
    return nil
  }

  /// Given the name of a namespace, create the namespace (or return it if it already exists).
  func createNamespace(ns: NamespaceName) -> NamespaceResult {
    if let nsToUse = namespaces[ns] {
      return .Success(nsToUse)
    }
    else {
      // Namespace doesn't exist; make it
      let nsToUse = NamespaceContext(interpreter: self, ns: ns)
      namespaces[ns] = nsToUse
      return .Success(nsToUse)
    }
  }

  /// Given the name of a namespace to switch to, switch to that namespace. If the namespace does not exist, the
  /// interpreter will create the namespace and switch to it.
  func switchNamespace(ns: NamespaceName) -> NamespaceResult {
    let result = createNamespace(ns)
    switch result {
    case let .Success(namespace):
      if namespace.isSystemNamespace {
        // Namespace is system namespace; user cannot switch to it
        return .Error(EvalError(.ReservedNamespaceError))
      }
      currentNamespace = namespace
      // TODO: Any way to do this without the optional?
      coreNamespace?.setVar(internStore.internedSymbolFor(._Ns), newValue: .Namespace(namespace))
      return result
    case .Nil, .Error:
      return result
    }
  }

  /// Given the name of a namespace to remove, remove that namespace. If the namespace to be removed is the current
  /// namespace, the namespace will remain usable until switched, but the namespace will be removed from the map of
  /// namespaces kept by the interpreter. Note that the system namespaces cannot be removed. Also note that removed
  /// namespaces have all aliases destroyed in order to prevent retain cycles.
  func removeNamespace(ns: NamespaceName) -> NamespaceResult {
    if let namespaceToDelete = namespaces[ns] where namespaceToDelete.isSystemNamespace {
      return .Error(EvalError(.ReservedNamespaceError))
    }
    let namespace = namespaces.removeValueForKey(ns)
    if let namespace = namespace {
      namespace.prepareForRemoval()
      if namespace.name == currentNamespace.name {
        // Current namespace removed; unbind *ns* in core
        coreNamespace?.unmapVar(internStore.internedSymbolFor(._Ns).unqualified)
      }
      return .Success(namespace)
    }
    return .Nil
  }

  /// Return a sequence of all namespaces loaded in the interpreter.
  func allNamespaces() -> VectorType {
    return map(namespaces.values) { .Namespace($0) }
  }


  // MARK: Initializer(s)

  init() {
    // Load the standard library
    // TODO: Fix this when we rewrite the hideous loader
    let stdlib = NamespaceContext(interpreter: self, ns: coreNamespaceName, asSystemNamespace: true)
    namespaces[coreNamespaceName] = stdlib
    currentNamespace = stdlib
    loadStdlibInto(stdlib, stdlib_files)
    coreNamespace = stdlib

    // Create the user namespace.
    let user = NamespaceContext(interpreter: self, ns: userNamespaceName)
    namespaces[userNamespaceName] = user
    currentNamespace = user

    // Manually bind *ns* the first time
    stdlib.setVar(internStore.internedSymbolFor(._Ns), newValue: .Namespace(user))

    // Once the stdlib has been completely prepared, have 'user' refer to it
    user.refer(stdlib)
  }
}

// Testing-related extension
extension Interpreter {
  func testOnly_addNamespace(namespace: NamespaceContext, named name: NamespaceName) {
    namespaces[name] = namespace
  }
}
