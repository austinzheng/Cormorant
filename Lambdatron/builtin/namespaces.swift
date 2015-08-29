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
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  if let nameSymbol = args[0].asSymbol {
    return actuate(nameSymbol, ctx, ctx.interpreter.createNamespace)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a symbol naming a namespace"))
}

/// Given a symbol naming a namespace, set the current namespace, creating it if necessary.
func ns_set(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-set"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  if let nameSymbol = args[0].asSymbol {
    return actuate(nameSymbol, ctx, ctx.interpreter.switchNamespace)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a symbol naming a namespace"))
}

/// Given either a symbol naming a namespace, or a namespace itself, return the corresponding namespace.
func ns_get(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-get"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): return .Success(.Namespace(n))
  case let .Failure(err): return .Failure(err)
  }
}

/// Given either a symbol naming an actual namespace or a namespace, return a symbol representing the namespace name.
func ns_name(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-name"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n):
    if args[0].asSymbol != nil {
      return .Success(args[0])
    }
    let result = n.internedName.asSymbol(ctx.ivs)
    switch result {
    case let .Symbol(sym): return .Success(.Symbol(sym))
    case let .Error(err): return .Failure(err)
    }
  case let .Failure(err): return .Failure(err)
  }
}

/// Return a sequence of all namespaces currently defined within the interpreter.
func ns_all(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-all"
  if args.count != 0 {
    return .Failure(EvalError.arityError("0", actual: args.count, fn))
  }
  return .Success(.Seq(VectorSequenceView(ctx.root.interpreter.allNamespaces())))
}

/// Return the namespace named by the symbol, or nil if it doesn't exist.
func ns_find(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-find"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  if let sym = args[0].asSymbol {
    let ns = NamespaceName(sym)
    if let namespace = ctx.interpreter.namespaces[ns] {
      return .Success(.Namespace(namespace))
    }
    return .Success(.Nil)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol naming a namespace"))
}

/// Unmap the given symbol from the namespace.
func ns_unmap(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-unmap"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): namespace = n
  case let .Failure(err): return .Failure(err)
  }
  // Extract symbol
  if let symbolToRemove = args[1].asSymbol {
    if !symbolToRemove.isUnqualified {
      return .Failure(EvalError(.QualifiedSymbolMisuseError))
    }
    let result = ctx.interpreter.unmapVar(symbolToRemove.unqualified, fromNamespace: namespace)
    if let error = result {
      return .Failure(error)
    }
    return .Success(.Nil)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be symbol"))
}

/// Add an alias in the current namespace to another namespace. The first argument is the alias, the second the ns.
func ns_alias(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-alias"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  // Extract symbol representing alias
  if let alias = args[0].asSymbol {
    // Extract namespace
    let namespace : NamespaceContext
    switch extractNamespace(args[1], ctx, true, fn) {
    case let .Success(n): namespace = n
    case let .Failure(err): return .Failure(err)
    }
    let result = ctx.root.alias(namespace, usingAlias: NamespaceName(alias))
    if let error = result {
      return .Failure(error)
    }
    return .Success(.Nil)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be symbol"))
}

/// Remove the given alias from the given namespace.
func ns_unalias(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-unalias"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): namespace = n
  case let .Failure(err): return .Failure(err)
  }
  // Extract symbol representing alias
  if let alias = args[1].asSymbol {
    let result = ctx.interpreter.removeAlias(NamespaceName(alias), fromNamespace: namespace)
    if let error = result {
      return .Failure(error)
    }
    return .Success(.Nil)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "second argument must be symbol"))
}

/// Return a map of namespace aliases defined for the given namespace.
func ns_aliases(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-aliases"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): namespace = n
  case let .Failure(err): return .Failure(err)
  }
  return namespace.aliasesAsMap()
}

/// Given a symbol referring to a namespace, create a mapping for each name-var binding in that namespace.
func ns_refer(args: Params, _ ctx: Context) -> EvalResult {
  let fn = "ns-refer"
  if args.count != 1 {
    // TODO: Support the filters :exclude, :only, and :rename?
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  if let nsSymbol = args[0].asSymbol {
    let result = ctx.root.refer(NamespaceName(nsSymbol))
    if let error = result {
      return .Failure(error)
    }
    return .Success(.Nil)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol naming a namespace"))
}

/// Given a namespace, return a map of all mappings for that namespace.
func ns_map(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-map"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): namespace = n
  case let .Failure(err): return .Failure(err)
  }
  var buffer = namespace.internsAsMap()
  let refers = namespace.refersAsMap()
  for (key, value) in refers {
    buffer[key] = value
  }
  return .Success(.Map(buffer))
}

/// Given a namespace, return a map of the local mappings for that namespace.
func ns_interns(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-interns"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): namespace = n
  case let .Failure(err): return .Failure(err)
  }
  return .Success(.Map(namespace.internsAsMap()))
}

/// Given a namespace, return a map of the refer mappings for that namespace.
func ns_refers(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-refers"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): namespace = n
  case let .Failure(err): return .Failure(err)
  }
  return .Success(.Map(namespace.refersAsMap()))
}

/// Given a namespace and a symbol, return the Var to which it will resolve in the namespace.
func ns_resolve(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-resolve"
  if args.count != 2 {
    return .Failure(EvalError.arityError("2", actual: args.count, fn))
  }
  // Extract namespace
  let namespace : NamespaceContext
  switch extractNamespace(args[0], ctx, false, fn) {
  case let .Success(n): namespace = n
  case let .Failure(err): return .Failure(err)
  }
  // Extract symbol
  if let symbol = args[1].asSymbol {
    if let thisVar = namespace.resolveSymbolFor(symbol) {
      return .Success(.Var(thisVar))
    }
    return .Success(.Nil)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol"))
}

/// Remove a namespace.
func ns_remove(args: Params, _ ctx: Context) -> EvalResult {
  let fn = ".ns-remove"
  if args.count != 1 {
    return .Failure(EvalError.arityError("1", actual: args.count, fn))
  }
  if let nameSymbol = args[0].asSymbol {
    return actuate(nameSymbol, ctx, ctx.interpreter.removeNamespace)
  }
  return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol naming a namespace"))
}


// MARK: Private functions

private enum NamespaceResult {
  case Success(NamespaceContext)
  case Failure(EvalError)
}

// TODO: (az) Is there a way we can make this less clumsy?
/// Given one of several possible canonical representations of a namespace (either a namespace object or a symbol naming
/// a namespace), extract the namespace, or return an error. Note that, if the Value represents a namespace object, that
/// namespace object will be returned, even if it has been removed from the interpreter.
private func extractNamespace(value: Value, _ ctx: Context, _ shouldValidate: Bool, _ fn: String) -> NamespaceResult {
  switch value {
  case let .Symbol(sym):
    if let namespace = ctx.interpreter.namespaces[NamespaceName(sym)] {
      return .Success(namespace)
    }
    else {
      return .Failure(EvalError(.InvalidNamespaceError))
    }
  case let .Namespace(namespace):
    if shouldValidate && ctx.interpreter.namespaces[namespace.internedName] == nil {
      return .Failure(EvalError(.InvalidNamespaceError))
    }
    return .Success(namespace)
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol or namespace"))
  }
}

// TODO: (az) Is there a way we can make this less clumsy?
/// Run one of the namespace-management methods on a context's interpreter, returning the result.
private func actuate(n: InternedSymbol, _ ctx: Context, _ f: NamespaceName -> Interpreter.NamespaceResult) -> EvalResult {
  let name = NamespaceName(n)
  let result = f(name)
  switch result {
  case let .Success(namespace):
    return .Success(.Namespace(namespace))
  case .Nil:
    return .Success(.Nil)
  case let .Error(err):
    return .Failure(err)
  }
}
