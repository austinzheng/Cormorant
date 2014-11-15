//
//  specialforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/10/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum describing all the special forms recognized by the interpreter
enum SpecialForm : String {
  // Add special forms below. The string is the name of the special form, and takes precedence over all functions, macros, and user defs
  case Quote = "quote"
  case Cons = "cons"
  case First = "first"
  case Rest = "rest"
  case If = "if"
  case Do = "do"
  case Def = "def"
  case Let = "let"
  case Fn = "fn"
  case Defmacro = "defmacro"
  
  var function : LambdatronBuiltIn {
    switch self {
    case .Quote: return sf_quote
    case .Cons: return sf_cons
    case .First: return sf_first
    case .Rest: return sf_rest
    case .If: return sf_if
    case .Do: return sf_do
    case .Def: return sf_def
    case .Let: return sf_let
    case .Fn: return sf_fn
    case .Defmacro: return sf_defmacro
    }
  }
}


// MARK: Special forms

/// Return the raw form, without any evaluation
func sf_quote(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.NilLiteral)
  }
  let first = args[0]
  return .Success(first)
}

func sf_cons(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let first = args[0].evaluate(ctx)
  let second = args[1].evaluate(ctx)
  switch second {
  case .NilLiteral:
    // Create a new list consisting of just the first object
    return .Success(.ListLiteral(Cons(first)))
  case let .ListLiteral(l):
    // Create a new list consisting of the first object, followed by the second list (if not empty)
    switch l.value {
    case .None: return .Success(.ListLiteral(Cons(first)))
    default: return .Success(.ListLiteral(Cons(first, next: l)))
    }
  case let .VectorLiteral(v):
    // Create a new list consisting of the first object, followed by a list comprised of the vector's items
    if v.count == 0 {
      return .Success(.ListLiteral(Cons(first)))
    }
    let head = Cons(first)
    var current = head
    for item in v {
      let this = Cons(item)
      current.next = this
      current = this
    }
    return .Success(.ListLiteral(head))
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Given a sequence, return the first item
func sf_first(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let first = args[0].evaluate(ctx)
  switch first {
  case .NilLiteral:
    return .Success(.NilLiteral)
  case let .ListLiteral(l):
    switch l.value {
    case .None: return .Success(.NilLiteral)
    default: return .Success(l.value)
    }
  case let .VectorLiteral(v):
    return .Success(v.count == 0 ? .NilLiteral : v[0])
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Given a sequence, return the sequence comprised of all items but the first
func sf_rest(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let first = args[0].evaluate(ctx)
  switch first {
  case .NilLiteral: return .Success(.ListLiteral(Cons()))
  case let .ListLiteral(l):
    if let actualNext = l.next {
      // List has more than one item
      return .Success(.ListLiteral(actualNext))
    }
    else {
      // List has zero or one items, return the empty list
      return .Success(.ListLiteral(Cons()))
    }
  case let .VectorLiteral(v):
    if v.count < 2 {
      // Vector has zero or one items
      return .Success(.ListLiteral(Cons()))
    }
    let head = Cons(v[1])
    var current = head
    for var i=2; i<v.count; i++ {
      let this = Cons(v[i])
      current.next = this
      current = this
    }
    return .Success(.ListLiteral(head))
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Evaluate a conditional, and evaluate one or one of two expressions
func sf_if(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 && args.count != 3 {
    return .Failure(.ArityError)
  }
  let test = args[0].evaluate(ctx)
  let then = args[1]
  let otherwise : ConsValue? = args.count == 3 ? args[2] : nil
  
  // Decide what to do with test
  let testIsTrue : Bool = {
    switch test {
    case .NilLiteral: return false
    case let .BoolLiteral(x): return x
    default: return true
    }
    }()
  
  if testIsTrue {
    return .Success(then.evaluate(ctx))
  }
  else if let actualOtherwise = otherwise {
    return .Success(actualOtherwise.evaluate(ctx))
  }
  else {
    return .Success(.NilLiteral)
  }
}

/// Evaluate all expressions, returning the value of the final expression
func sf_do(args: [ConsValue], ctx: Context) -> EvalResult {
  var finalValue : ConsValue = .NilLiteral
  for expr in args {
    finalValue = expr.evaluate(ctx)
  }
  return .Success(finalValue)
}

func sf_def(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count < 1 {
    return .Failure(.ArityError)
  }
  let symbol = args[0]
  let initializer : ConsValue? = {
    if args.count > 1 {
      return args[1]
    }
    return nil
  }()
  
  switch symbol {
  case let .Symbol(s):
    // Do stuff
    if let actualInit = initializer {
      // If a value is provided, always use that value
      let result = actualInit.evaluate(ctx)
      ctx.setTopLevelBinding(s, value: .Literal(result))
    }
    else {
      // No value is provided
      // If invalid, create the var as unbound
      if !ctx.nameIsValid(s) {
        ctx.setTopLevelBinding(s, value: .Unbound)
      }
    }
    return .Success(symbol)
  default:
    return .Failure(.InvalidArgumentError)
  }
}

func sf_let(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let bindingsForm = args[0]
  switch bindingsForm {
  case let .VectorLiteral(bindingsVector):
    // The first argument is a vector, which is what we want
    if bindingsVector.count % 2 != 0 {
      return .Failure(.CustomError("let binding vector must have an even number of elements"))
    }
    // Create a bindings dictionary for our new context
    var newBindings : [String : Binding] = [:]
    var ctr = 0
    while ctr < bindingsVector.count {
      let name = bindingsVector[ctr]
      switch name {
      case let .Symbol(s):
        // Evaluate expression
        // Note that each binding pair benefits from the result of the binding from the previous pair
        let expression = bindingsVector[ctr+1]
        let result = expression.evaluate(Context(parent: ctx, bindings: newBindings))
        newBindings[s] = .Literal(result)
      default:
        return .Failure(.InvalidArgumentError)
      }
      ctr += 2
    }
    // Create a new context, which is a child of the old context
    let newContext = Context(parent: ctx, bindings: newBindings)
    
    // Create an implicit 'do' statement with the remainder of the args
    if args.count == 1 {
      // No additional statements is fine
      return .Success(.NilLiteral)
    }
    let restOfArgs = Array(args[1..<args.count])
    let result = sf_do(restOfArgs, newContext)
    return result
  default:
    return .Failure(.InvalidArgumentError)
  }
}

func sf_fn(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  if let name = args[0].asSymbol() {
    if args.count == 1 {
      return .Failure(.ArityError)
    }
    if let argsVector = args[1].asVector() {
      // SINGLE ARITY
      // After the name comes the vector of arguments
      if let paramTuple = extractParameters(argsVector) {
        let (paramNames, variadic) = paramTuple
        let forms = args.count > 2 ? Array(args[2..<args.count]) : []
        let fn = Function(parameters: paramNames, forms: forms, variadicParam: variadic, name: name, ctx: ctx)
        return .Success(.FunctionLiteral(fn))
      }
    }
    else {
      // MULTIPLE ARITY
      // After the name comes multiple Cons, each with a separate definition
      fatal("Not yet implemented")
    }
    return .Failure(.InvalidArgumentError)
  }
  else {
    // No name provided
    if let argsVector = args[0].asVector() {
      // SINGLE ARITY
      // The vector of args comes first
      if let paramTuple = extractParameters(argsVector) {
        let (paramNames, variadic) = paramTuple
        let forms = args.count > 1 ? Array(args[1..<args.count]) : []
        let fn = Function(parameters: paramNames, forms: forms, variadicParam: variadic, name: nil, ctx: ctx)
        return .Success(.FunctionLiteral(fn))
      }
    }
    else {
      // MULTIPLE ARITY
      // After the name comes multiple Cons, each with a separate definition
      fatal("Not yet implemented")
    }
    return .Failure(.InvalidArgumentError)
  }
}

func sf_defmacro(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count < 2 {
    return .Failure(.ArityError)
  }
  if let name = args[0].asSymbol() {
    if let argsVector = args[1].asVector() {
      if let paramTuple = extractParameters(argsVector) {
        let (paramNames, variadic) = paramTuple
        // NOTE: at this time, macros are unhygenic. Symbols will be evaluated with their meanings at expansion time,
        //  rather than when they are defined. This also means macros will break if defined with argument names that
        //  are later rebound using def, let, etc.
        // Macros also don't capture their context. They use the context provided at the time they are expanded.
        let forms = args.count > 2 ? Array(args[2..<args.count]) : []
        let macro = Macro(parameters: paramNames, forms: forms, variadicParam: variadic, name: name)
        // Register the macro to the global context
        ctx.setTopLevelBinding(name, value: .BoundMacro(macro))
        return .Success(args[0])
      }
    }
  }
  return .Failure(.InvalidArgumentError)
}


// MARK: Helper functions

/// Given a list of args (all of which should be symbols), extract the strings corresponding with their argument names,
/// as well as any variadic parameter that exists.
private func extractParameters(args: [ConsValue]) -> ([String], String?)? {
  // Returns a list of symbol names representing the parameter names, as well as the variadic parameter name (if any)
  var names : [String] = []
  for arg in args {
    switch arg {
    case let .Symbol(s): names.append(s)
    default: return nil // Non-symbol objects in argument list are invalid
    }
  }
  // No '&' allowed anywhere except for second-last position
  for (idx, name) in enumerate(names) {
    if name == "&" && idx != names.count - 2 {
      return nil
    }
  }
  // Check to see if there's a variadic argument
  if names.count >= 2 && names[names.count - 2] == "&" {
    return (Array(names[0..<names.count-2]), names[names.count-1])
  }
  else {
    return (names, nil)
  }
}
