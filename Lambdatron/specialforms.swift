//
//  specialforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/10/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronSpecialForm = ([ConsValue], Context, EvalEnvironment) -> EvalResult

/// An enum describing all the special forms recognized by the interpreter
enum SpecialForm : String, Printable {
  // Add special forms below. The string is the name of the special form, and takes precedence over all functions, macros, and user defs
  case Quote = "quote"
  case If = "if"
  case Do = "do"
  case Def = "def"
  case Let = "let"
  case Fn = "fn"
  case Defmacro = "defmacro"
  case Loop = "loop"
  case Recur = "recur"
  case Apply = "apply"
  
  var function : LambdatronSpecialForm {
    switch self {
    case Quote: return sf_quote
    case If: return sf_if
    case Do: return sf_do
    case Def: return sf_def
    case Let: return sf_let
    case Fn: return sf_fn
    case Defmacro: return sf_defmacro
    case Loop: return sf_loop
    case Recur: return sf_recur
    case Apply: return sf_apply
    }
  }
  
  var description : String {
    return self.rawValue
  }
}


// MARK: Special forms

/// Return the argument as its literal value (without performing any evaluation).
func sf_quote(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Success(.NilLiteral)
  }
  let first = args[0]
  return .Success(first)
}

/// Evaluate a conditional, and evaluate one or one of two expressions based on its boolean value.
func sf_if(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 2 && args.count != 3 {
    return .Failure(.ArityError)
  }
  let test = args[0].evaluate(ctx, env)
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
    return .Success(then.evaluate(ctx, env))
  }
  else if let actualOtherwise = otherwise {
    return .Success(actualOtherwise.evaluate(ctx, env))
  }
  else {
    return .Success(.NilLiteral)
  }
}

/// Evaluate all expressions, returning the value of the final expression.
func sf_do(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  var finalValue : ConsValue = .NilLiteral
  for (idx, expr) in enumerate(args) {
    finalValue = expr.evaluate(ctx, env)
    if idx != args.count - 1 && finalValue.isRecurSentinel {
      return .Failure(.RecurMisuseError)
    }
  }
  return .Success(finalValue)
}

/// Bind or re-bind a global identifier, optionally assigning it a value.
func sf_def(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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
      let result = actualInit.evaluate(ctx, env)
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

/// Create a new lexical scope in which zero or more symbols are bound to the results of corresponding forms; all forms
/// after the binding vector are evaluated in an implicit 'do' form within the context of the new scope.
func sf_let(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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
        let result = expression.evaluate(Context(parent: ctx, bindings: newBindings), env)
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
    let result = sf_do(restOfArgs, newContext, env)
    return result
  default:
    return .Failure(.InvalidArgumentError)
  }
}

/// Define a user-defined function, consisting of an parameter vector followed by zero or more forms comprising the
/// body, or one or more lists comprised of parameter vectors and body forms. When the function is called, argument
/// values are bound to the parameter symbols, and the body forms are evaluated in an implicit 'do' form. A name can
/// optionally be provided before the argument vector or first arity list, allowing the function to be referenced from
/// within itself.
func sf_fn(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let name : String? = args[0].asSymbol()
  let rest = (name == nil) ? args : Array(args[1..<args.count])
  if rest[0].asVector() != nil {
    // Single arity
    let singleArity = buildSingleFnFor(.VectorLiteral(rest), type: .Function)
    if let actualSingleArity = singleArity {
      return Function.buildFunction([actualSingleArity], name: name, ctx: ctx)
    }
  }
  else {
    var arityBuffer : [SingleFn] = []
    for potential in rest {
      if let nextFn = buildSingleFnFor(potential, type: .Function) {
        arityBuffer.append(nextFn)
      }
      else {
        return .Failure(.InvalidArgumentError)
      }
    }
    return Function.buildFunction(arityBuffer, name: name, ctx: ctx)
  }
  return .Failure(.InvalidArgumentError)
}

/// Define a macro. A macro is defined in a similar manner to a function, except that macros must be bound to a global
/// binding and cannot be treated as values.
func sf_defmacro(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count < 2 {
    return .Failure(.ArityError)
  }
  if let name = args[0].asSymbol() {
    // NOTE: at this time, macros are unhygenic. Symbols will be evaluated with their meanings at expansion time,
    //  rather than when they are defined. This also means macros will break if defined with argument names that
    //  are later rebound using def, let, etc.
    // Macros also don't capture their context. They use the context provided at the time they are expanded.
    let rest = Array(args[1..<args.count])
    if rest[0].asVector() != nil {
      // Single arity
      let singleArity = buildSingleFnFor(.VectorLiteral(rest), type: .Macro)
      if let actualSingleArity = singleArity {
        let macroResult = Macro.buildMacro([actualSingleArity], name: name, ctx: ctx)
        switch macroResult {
        case let .Success(macro):
          ctx.setTopLevelBinding(name, value: .BoundMacro(macro))
          return .Success(args[0])
        case let .Failure(f):
          return .Failure(f)
        }
      }
    }
    else {
      var arityBuffer : [SingleFn] = []
      for potential in rest {
        if let nextFn = buildSingleFnFor(potential, type: .Macro) {
          arityBuffer.append(nextFn)
        }
        else {
          return .Failure(.InvalidArgumentError)
        }
      }
      let macroResult = Macro.buildMacro(arityBuffer, name: name, ctx: ctx)
      switch macroResult {
      case let .Success(macro):
        ctx.setTopLevelBinding(name, value: .BoundMacro(macro))
        return .Success(args[0])
      case let .Failure(f):
        return .Failure(f)
      }
    }
  }
  return .Failure(.InvalidArgumentError)
}

/// Define a loop. Loops define a set of zero or more bindings in a new lexical environment, followed by zero or more
/// forms which are evaluated within an implicit 'do' form. The loop body may return either a normal value, in which
/// case the loop terminates, or the value of a 'recur' form, in which case the new arguments are re-bound and the loop
/// forms are evaluated again.
func sf_loop(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  if let bindingsVector = args[0].asVector() {
    // The first argument must be a vector of bindings and values
    // Evaluate each binding's initializer and bind it to the corresponding symbol
    if bindingsVector.count % 2 != 0 {
      return .Failure(.CustomError("loop binding vector must have an even number of elements"))
    }
    var bindings : [String : Binding] = [:]
    var symbols : [String] = []
    var ctr = 0
    while ctr < bindingsVector.count {
      let name = bindingsVector[ctr]
      switch name {
      case let .Symbol(s):
        let expression = bindingsVector[ctr+1]
        let result = expression.evaluate(Context(parent: ctx, bindings: bindings), env)
        bindings[s] = .Literal(result)
        symbols.append(s)
      default:
        return .Failure(.InvalidArgumentError)
      }
      ctr += 2
    }
    let forms = args.count > 1 ? Array(args[1..<args.count]) : []
    // Now, run the loop body
    var context = bindings.count == 0 ? ctx : Context(parent: ctx, bindings: bindings)
    while true {
      let result = sf_do(forms, context, env)
      switch result {
      case let .Success(resultValue):
        switch resultValue {
        case let .RecurSentinel(newBindingValues):
          // If result is 'recur', we need to rebind and run the loop again from the start.
          if newBindingValues.count != symbols.count {
            return .Failure(.ArityError)
          }
          var newBindings : [String : Binding] = [:]
          for (idx, newValue) in enumerate(newBindingValues) {
            newBindings[symbols[idx]] = .Literal(newValue)
          }
          context = bindings.count == 0 ? ctx : Context(parent: ctx, bindings: newBindings)
          continue
        default: return result
        }
      default: return result
      }
    }
  }
  return .Failure(.InvalidArgumentError)
}

/// When in the context of a function or a loop, indicate that execution of the current iteration has completed and
/// provide updated bindings for re-running the function or loop as part of tail-call optimized recursion. Use outside
/// these contexts is considered an error.
func sf_recur(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  // recur can *only* be used inside the context of a 'loop' or a fn declaration
  // Evaluate all arguments, and then create a sentinel value
  var newArgs : [ConsValue] = []
  for arg in args {
    let result = arg.evaluate(ctx, env)
    newArgs.append(result)
  }
  return .Success(.RecurSentinel(newArgs))
}

/// Given a function, zero or more leading arguments, and a sequence of args, apply the function with the arguments.
func sf_apply(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count < 2 {
    return .Failure(.ArityError)
  }
  // First argument must be a function, built-in, or special form
  // TODO: There should be a less ad-hoc way of determining whether the first argument is eval'able.
  let first = args[0].evaluate(ctx, env)
  switch first {
  case .FunctionLiteral, .BuiltInFunction, .Special, .MapLiteral, .Symbol: break
  default: return .Failure(.InvalidArgumentError)
  }
  
  // Straightforward implementation: build a list and then eval it
  let head = Cons(first)
  var this = head
  
  for var i=1; i<args.count - 1; i++ {
    // Add all leading args (after being evaluated) to the list directly
    let evaluatedResult = args[i].evaluate(ctx, env)
    let next = Cons(evaluatedResult)
    this.next = next
    this = next
  }
  
  // Evaluate the last argument, which should be some sort of collection.
  // Note that, since there can never be zero arguments, last will always be non-nil.
  let last = args.last!.evaluate(ctx, env)
  switch last {
  case let .ListLiteral(l) where !l.isEmpty:
    this.next = l
  case let .VectorLiteral(v):
    for item in v {
      let next = Cons(item)
      this.next = next
      this = next
    }
  case let .MapLiteral(m):
    for (key, value) in m {
      let next = Cons(.VectorLiteral([key, value]))
      this.next = next
      this = next
    }
  default:
    return .Failure(.InvalidArgumentError)
  }
  
  // With the entire list constructed, evaluate it as a function call and then return the result.
  let result = head.evaluate(ctx, env)
  return .Success(result)
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

/// Given an item (expected to be a vector or a list), with the first item a vector of argument bindings, return a new
/// SingleFn instance.
private func buildSingleFnFor(item: ConsValue, #type: FnType) -> SingleFn? {
  let itemAsVector : Vector? = {
    switch item {
    case let .ListLiteral(l): return Cons.collectSymbols(l)
    case let .VectorLiteral(v): return v
    default: return nil
    }
  }()
  if let vector = itemAsVector {
    // The argument 'item' was a valid list or vector
    if vector.count == 0 {
      return nil
    }
    if let params = vector[0].asVector() {
      if let paramTuple = extractParameters(params) {
        // Now we've taken out the parameters (they are symbols in a vector
        let (paramNames, variadic) = paramTuple
        let forms = vector.count > 1 ? Array(vector[1..<vector.count]) : []
        return SingleFn(fnType: type, parameters: paramNames, forms: forms, variadicParameter: variadic)
      }
    }
  }
  return nil
}

