//
//  namespaces.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/26/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Given a symbol naming a namespace, return the namespace, creating it if necessary.
func ns_create(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-create"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  guard case let .symbol(nameSymbol) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a symbol naming a namespace"))
  }
  return actuate(nameSymbol, ctx, ctx.interpreter.create)
}

/// Given a symbol naming a namespace, set the current namespace, creating it if necessary.
func ns_set(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-set"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  guard case let .symbol(nameSymbol) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a symbol naming a namespace"))
  }
  return actuate(nameSymbol, ctx, ctx.interpreter.switchToNamespace)
}

/// Given either a symbol naming a namespace, or a namespace itself, return the corresponding namespace.
func ns_get(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-get"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  return extractNamespace(args[0], ctx, false, fn).then { .Success(.namespace($0)) }
}

/// Given either a symbol naming an actual namespace or a namespace, return a symbol representing the namespace name.
func ns_name(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-name"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  return extractNamespace(args[0], ctx, false, fn).then { namespace in
    if case .symbol = args[0] {
      return .Success(args[0])
    }
    return namespace.internedName.asSymbol(ctx.ivs).then { .Success(.symbol($0)) }
  }
}

/// Return a sequence of all namespaces currently defined within the interpreter.
func ns_all(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-all"
  if args.count != 0 {
    return .Failure(EvalError.arityError(expected: "0", actual: args.count, fn))
  }
  return .Success(.seq(VectorSequenceView(ctx.root.interpreter.allNamespaces())))
}

/// Return the namespace named by the symbol, or nil if it doesn't exist.
func ns_find(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-find"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  guard case let .symbol(sym) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol naming a namespace"))
  }
  let ns = NamespaceName(sym)
  if let namespace = ctx.interpreter.namespaces[ns] {
    return .Success(.namespace(namespace))
  }
  return .Success(.nilValue)
}

/// Unmap the given symbol from the namespace.
func ns_unmap(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-unmap"
  if args.count != 2 {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  // Extract namespace
  return extractNamespace(args[0], ctx, false, fn).then { namespace in
    // Extract symbol
    guard case let .symbol(symbolToRemove) = args[1] else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be symbol"))
    }
    if !symbolToRemove.isUnqualified {
      return .Failure(EvalError(.QualifiedSymbolMisuseError))
    }
    if let error = ctx.interpreter.unmap(symbol: symbolToRemove.unqualified, fromNamespace: namespace) {
      return .Failure(error)
    }
    return .Success(.nilValue)
  }
}

/// Add an alias in the current namespace to another namespace. The first argument is the alias, the second the ns.
func ns_alias(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-alias"
  if args.count != 2 {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  // Extract symbol representing alias
  guard case let .symbol(alias) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be symbol"))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[1], ctx, true, fn) {
  case let .Just(n): namespace = n
  case let .Error(err): return .Failure(err)
  }
  let result = ctx.root.alias(namespace: namespace, usingAlias: NamespaceName(alias))
  if let error = result {
    return .Failure(error)
  }
  return .Success(.nilValue)
}

/// Remove the given alias from the given namespace.
func ns_unalias(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-unalias"
  if args.count != 2 {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  // Extract namespace
  return extractNamespace(args[0], ctx, false, fn).then { namespace in
    // Extract symbol representing alias
    guard case let .symbol(alias) = args[1] else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be symbol"))
    }
    let result = ctx.interpreter.remove(alias: NamespaceName(alias), fromNamespace: namespace)
    if let error = result {
      return .Failure(error)
    }
    return .Success(.nilValue)
  }
}

/// Return a map of namespace aliases defined for the given namespace.
func ns_aliases(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-aliases"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  return extractNamespace(args[0], ctx, false, fn).then { $0.aliasesAsMap() }
}

/// Given a symbol referring to a namespace, create a mapping for each name-var binding in that namespace.
func ns_refer(args: Params, _ ctx: Context) -> EvalResult {
  let fn = "ns-refer"
  if args.count != 1 {
    // TODO: Support the filters :exclude, :only, and :rename?
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  guard case let .symbol(namespaceSymbol) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol naming a namespace"))
  }
  let result = ctx.root.refer(NamespaceName(namespaceSymbol))
  if let error = result {
    return .Failure(error)
  }
  return .Success(.nilValue)
}

/// Given a namespace, return a map of all mappings for that namespace.
func ns_map(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-map"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  // Extract namespace
  return extractNamespace(args[0], ctx, false, fn).then { namespace in
    var buffer = namespace.internsAsMap()
    let refers = namespace.refersAsMap()
    for (key, value) in refers {
      buffer[key] = value
    }
    return .Success(.map(buffer))
  }
}

/// Given a namespace, return a map of the local mappings for that namespace.
func ns_interns(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-interns"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  return extractNamespace(args[0], ctx, false, fn).then { .Success(.map($0.internsAsMap())) }
}

/// Given a namespace, return a map of the refer mappings for that namespace.
func ns_refers(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-refers"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  return extractNamespace(args[0], ctx, false, fn).then { .Success(.map($0.refersAsMap())) }
}

/// Given a namespace and a symbol, return the Var to which it will resolve in the namespace.
func ns_resolve(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-resolve"
  if args.count != 2 {
    return .Failure(EvalError.arityError(expected: "2", actual: args.count, fn))
  }
  // Extract namespace
  return extractNamespace(args[0], ctx, false, fn).then { namespace in
    // Extract symbol
    guard case let .symbol(symbol) = args[1] else {
      return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol"))
    }
    if let thisVar : VarType = namespace.resolveVar(for: symbol) {
      return .Success(.`var`(thisVar))
    }
    return .Success(.nilValue)
  }
}

/// Remove a namespace.
func ns_remove(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-remove"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  guard case let .symbol(nameSymbol) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol naming a namespace"))
  }
  return actuate(nameSymbol, ctx, ctx.interpreter.remove)
}


// MARK: Private functions

// TODO: (az) Is there a way we can make this less clumsy?
/// Given one of several possible canonical representations of a namespace (either a namespace object or a symbol naming
/// a namespace), extract the namespace, or return an error. Note that, if the Value represents a namespace object, that
/// namespace object will be returned, even if it has been removed from the interpreter.
private func extractNamespace(_ value: Value, _ ctx: Context, _ shouldValidate: Bool, _ fn: String) -> EvalOptional<NamespaceContext> {
  switch value {
  case let .symbol(sym):
    if let namespace = ctx.interpreter.namespaces[NamespaceName(sym)] {
      return .Just(namespace)
    }
    else {
      return .Error(EvalError(.InvalidNamespaceError))
    }
  case let .namespace(namespace):
    if shouldValidate && ctx.interpreter.namespaces[namespace.internedName] == nil {
      return .Error(EvalError(.InvalidNamespaceError))
    }
    return .Just(namespace)
  default:
    return .Error(EvalError.invalidArgumentError(fn, message: "argument must be a symbol or namespace"))
  }
}

// TODO: (az) Is there a way we can make this less clumsy?
/// Run one of the namespace-management methods on a context's interpreter, returning the result.
private func actuate(_ n: InternedSymbol, _ ctx: Context, _ f: (NamespaceName) -> Interpreter.NamespaceResult) -> EvalResult {
  let name = NamespaceName(n)
  let result = f(name)
  switch result {
  case let .Success(namespace):
    return .Success(.namespace(namespace))
  case .Nil:
    return .Success(.nilValue)
  case let .Error(err):
    return .Failure(err)
  }
}
