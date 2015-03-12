//
//  specialforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/10/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronSpecialForm = (Params, Context) -> EvalResult

// Constants for ConsValue-wrapped special forms.
internal let QUOTE = ConsValue.Special(.Quote)
internal let IF = ConsValue.Special(.If)
internal let DO = ConsValue.Special(.Do)
internal let DEF = ConsValue.Special(.Def)
internal let LET = ConsValue.Special(.Let)
internal let FN = ConsValue.Special(.Fn)
internal let DEFMACRO = ConsValue.Special(.Defmacro)
internal let LOOP = ConsValue.Special(.Loop)
internal let RECUR = ConsValue.Special(.Recur)
internal let APPLY = ConsValue.Special(.Apply)

/// An enum describing all the special forms recognized by the interpreter.
public enum SpecialForm : String, Printable {
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
  case Attempt = "attempt"
  
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
    case Attempt: return sf_attempt
    }
  }

  public var description : String {
    return self.rawValue
  }
}


// MARK: Special forms

/// Return the argument as its literal value (without performing any evaluation).
func sf_quote(args: Params, ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.Nil)
  }
  let first = args[0]
  return .Success(first)
}

/// Evaluate a conditional, and evaluate one or one of two expressions based on its boolean value.
func sf_if(args: Params, ctx: Context) -> EvalResult {
  let fn = "if"
  if args.count != 2 && args.count != 3 {
    return .Failure(EvalError.arityError("2 or 3", actual: args.count, fn))
  }
  let testResult = args[0].evaluate(ctx)

  let result = next(testResult) { testForm in
    let then = args[1]
    let otherwise : ConsValue? = args.count == 3 ? args[2] : nil

    // Decide what to do with test
    let testIsTrue : Bool = {
      switch testForm {
      case .Nil: return false
      case let .BoolAtom(x): return x
      default: return true
      }
      }()

    if testIsTrue {
      return then.evaluate(ctx)
    }
    else if let otherwise = otherwise {
      return otherwise.evaluate(ctx)
    }
    else {
      return .Success(.Nil)
    }
  }
  return result
}

/// Evaluate all expressions, returning the value of the final expression.
func sf_do(args: Params, ctx: Context) -> EvalResult {
  return do_exprs(args, ctx)
}

/// Evaluate all expressions, returning the value of the final expression. (This version takes an array instead of a
/// Params object as its first argument.)
func sf_do(args: [ConsValue], ctx: Context) -> EvalResult {
  return do_exprs(args, ctx)
}

/// Bind or re-bind a global identifier, optionally assigning it a value.
func sf_def(args: Params, ctx: Context) -> EvalResult {
  let fn = "def"
  if args.count == 0 || args.count > 2 {
    return .Failure(EvalError.arityError("0 or 2", actual: args.count, fn))
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
    if let initializer = initializer {
      // If a value is provided, always use that value
      let result = initializer.evaluate(ctx)
      switch result {
      case let .Success(result):
        ctx.setVar(s, value: .Literal(result))
      case .Recur:
        return .Failure(EvalError(.RecurMisuseError, fn,
          message: "recur was used as the initializer when defining a var"))
      case .Failure:
        return result
      }
    }
    else {
      // No value is provided
      // If invalid, create the var as unbound
      if !ctx.varIsValid(s) {
        ctx.setVar(s, value: .Unbound)
      }
    }
    return .Success(symbol)
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a symbol"))
  }
}

/// Create a new lexical scope in which zero or more symbols are bound to the results of corresponding forms; all forms
/// after the binding vector are evaluated in an implicit 'do' form within the context of the new scope.
func sf_let(args: Params, ctx: Context) -> EvalResult {
  let fn = "let"
  if args.count == 0 {
    return .Failure(EvalError.arityError("> 0", actual: args.count, fn))
  }
  let bindingsForm = args[0]
  switch bindingsForm {
  case let .Vector(bindingsVector):
    // The first argument is a vector, which is what we want
    if bindingsVector.count % 2 != 0 {
      return .Failure(EvalError(.BindingMismatchError, fn))
    }
    // Create a new context whose parent is the current context. This new context will be updated in-place for each
    //  expression in the binding vector that is evaluated.
    let newContext = ChildContext(parent: ctx)
    var ctr = 0
    while ctr < bindingsVector.count {
      let bindingSymbol = bindingsVector[ctr]
      switch bindingSymbol {
      case let .Symbol(s):
        // Evaluate expression
        // Note that each binding pair benefits from the result of the binding from the previous pair
        let expression = bindingsVector[ctr+1]
        let result = expression.evaluate(newContext)
        switch result {
        case let .Success(result):
          newContext.pushBinding(.Literal(result), forSymbol: s)
        default: return result
        }
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "even-indexed arguments in a binding vector must be symbols"))
      }
      ctr += 2
    }
    
    // Create an implicit 'do' statement with the remainder of the args
    if args.count == 1 {
      // No additional statements is fine
      return .Success(.Nil)
    }
    let rest = args.rest()
    let result = sf_do(rest, newContext)
    return result
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be an binding vector"))
  }
}

/// Define a user-defined function, consisting of an parameter vector followed by zero or more forms comprising the
/// body, or one or more lists comprised of parameter vectors and body forms. When the function is called, argument
/// values are bound to the parameter symbols, and the body forms are evaluated in an implicit 'do' form. A name can
/// optionally be provided before the argument vector or first arity list, allowing the function to be referenced from
/// within itself.
func sf_fn(args: Params, ctx: Context) -> EvalResult {
  let fn = "fn"
  if args.count == 0 {
    return .Failure(EvalError.arityError("> 0", actual: args.count, fn))
  }
  let name : InternedSymbol? = args[0].asSymbol
  let rest = (name == nil) ? args : args.rest()
  if rest.count == 0 {
    return .Failure(EvalError.arityError("at least 2 (if first arg is a name)", actual: args.count, fn))
  }
  if rest[0].asVector != nil {
    // Single arity
    let singleArity = buildSingleFnFor(.Vector(rest.asArray), ctx: ctx)
    if let actualSingleArity = singleArity {
      return Function.buildFunction([actualSingleArity], name: name, ctx: ctx)
    }
  }
  else {
    var arityBuffer : [SingleFn] = []
    for potential in rest {
      if let nextFn = buildSingleFnFor(potential, ctx: ctx) {
        arityBuffer.append(nextFn)
      }
      else {
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "arguments must be lists describing a single arity for a function"))
      }
    }
    return Function.buildFunction(arityBuffer, name: name, ctx: ctx)
  }
  return .Failure(EvalError.invalidArgumentError(fn,
    message: "first argument must be a name, a binding vector, or a single arity function definition"))
}

/// Define a macro. A macro is defined in a similar manner to a function, except that macros must be bound to a global
/// binding and cannot be treated as values.
func sf_defmacro(args: Params, ctx: Context) -> EvalResult {
  let fn = "defmacro"
  if args.count < 2 {
    return .Failure(EvalError.arityError("2 or more", actual: args.count, fn))
  }
  if let name = args[0].asSymbol {
    let rest = args.rest()
    if rest[0].asVector != nil {
      // Single arity
      let singleArity = buildSingleFnFor(.Vector(rest.asArray), ctx: ctx)
      if let actualSingleArity = singleArity {
        let macroResult = Macro.buildMacro([actualSingleArity], name: name, ctx: ctx)
        switch macroResult {
        case let .Success(macro):
          ctx.setVar(name, value: .BoundMacro(macro))
          return .Success(args[0])
        case let .Failure(f):
          return .Failure(f)
        }
      }
    }
    else {
      var arityBuffer : [SingleFn] = []
      for potential in rest {
        if let nextFn = buildSingleFnFor(potential, ctx: ctx) {
          arityBuffer.append(nextFn)
        }
        else {
          return .Failure(EvalError.invalidArgumentError(fn,
            message: "arguments must be lists describing a single arity for a macro"))
        }
      }
      let macroResult = Macro.buildMacro(arityBuffer, name: name, ctx: ctx)
      switch macroResult {
      case let .Success(macro):
        ctx.setVar(name, value: .BoundMacro(macro))
        return .Success(args[0])
      case let .Failure(f):
        return .Failure(f)
      }
    }
  }
  return .Failure(EvalError.invalidArgumentError(fn,
    message: "first argument must be a name for the macro"))
}

/// Define a loop. Loops define a set of zero or more bindings in a new lexical environment, followed by zero or more
/// forms which are evaluated within an implicit 'do' form. The loop body may return either a normal value, in which
/// case the loop terminates, or the value of a 'recur' form, in which case the new arguments are re-bound and the loop
/// forms are evaluated again.
func sf_loop(args: Params, ctx: Context) -> EvalResult {
  let fn = "loop"
  if args.count == 0 {
    return .Failure(EvalError.arityError("> 0", actual: args.count, fn))
  }
  if let bindingsVector = args[0].asVector {
    // The first argument must be a vector of bindings and values
    // Evaluate each binding's initializer and bind it to the corresponding symbol
    if bindingsVector.count % 2 != 0 {
      return .Failure(EvalError(.BindingMismatchError, fn))
    }
    // thisContext is the new context within which the loop executes. If there are any bindings they are added into this
    //  context.
    let thisContext = ChildContext(parent: ctx)
    var symbols : [InternedSymbol] = []
    var ctr = 0
    while ctr < bindingsVector.count {
      let name = bindingsVector[ctr]
      switch name {
      case let .Symbol(s):
        let expression = bindingsVector[ctr+1]
        let result = expression.evaluate(thisContext)
        switch result {
        case let .Success(result):
          thisContext.pushBinding(.Literal(result), forSymbol: s)
        case .Recur:
          return .Failure(EvalError(.RecurMisuseError, fn,
            message: "recur came before the final expression in a loop"))
        case .Failure:
          return result
        }
        symbols.append(s)
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "even-indexed arguments in a binding vector must be symbols"))
      }
      ctr += 2
    }
    let forms = args.rest()
    // Now, run the loop body
    while true {
      let result = sf_do(forms, thisContext)
      switch result {
      case let .Recur(newBindingValues):
        // If result is 'recur', we need to rebind and run the loop again from the start.
        if newBindingValues.count != symbols.count {
          return .Failure(EvalError.arityError("\(symbols.count)", actual: newBindingValues.count, fn))
        }
        for (idx, newValue) in enumerate(newBindingValues) {
          thisContext[symbols[idx]] = .Literal(newValue)
        }
        continue
      case .Success, .Failure:
        return result
      }
    }
  }
  return .Failure(EvalError.invalidArgumentError(fn,
    message: "first argument must be a binding vector"))
}

/// When in the context of a function or a loop, indicate that execution of the current iteration has completed and
/// provide updated bindings for re-running the function or loop as part of tail-call optimized recursion. Use outside
/// these contexts is considered an error.
func sf_recur(args: Params, ctx: Context) -> EvalResult {
  let fn = "recur"
  // recur can *only* be used inside the context of a 'loop' or a fn declaration
  // Evaluate all arguments, and then create a sentinel value
  var buffer = Params()
  for arg in args {
    let result = arg.evaluate(ctx)
    switch result {
    case let .Success(result): buffer.append(result)
    case .Recur: return .Failure(EvalError(.RecurMisuseError, fn))
    case .Failure: return result
    }
  }
  return .Recur(buffer)
}

/// Given a function, zero or more leading arguments, and a sequence of args, apply the function with the arguments.
func sf_apply(args: Params, ctx: Context) -> EvalResult {
  let fn = "apply"
  if args.count < 2 {
    return .Failure(EvalError.arityError("2 or more", actual: args.count, fn))
  }
  let first = args[0].evaluate(ctx)
  let result = next(first) { first in
    // Collect all remaining args
    var buffer = Params()
    
    // Add all leading args (after being evaluated) to the list directly
    for var i=1; i<args.count - 1; i++ {
      let res = args[i].evaluate(ctx)
      switch res {
      case let .Success(res): buffer.append(res)
      case let .Recur: return .Failure(EvalError(.RecurMisuseError, fn))
      case .Failure: return res
      }
    }

    // Evaluate the last argument, which should be some sort of collection.
    // Note that, since there can never be zero arguments, last will always be non-nil.
    let last = args.last!.evaluate(ctx)
    switch last {
    case let .Success(last):
      // If the result is a collection, add all items in the collection to the arguments buffer
      switch last {
      case let .Nil: break
      case let .List(l):
        for item in l {
          buffer.append(item)
        }
      case let .Vector(v):
        for item in v {
          buffer.append(item)
        }
      case let .Map(m):
        for vector in MapSequence(m) {
          buffer.append(vector)
        }
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "last argument must be a collection or nil"))
      }
    case .Recur: return .Failure(EvalError(.RecurMisuseError, fn))
    case .Failure: return last
    }
    
    // Apply the function to the arguments in the buffer
    return apply(first, buffer, ctx, fn)
  }
  return result
}

/// Given at least one form, evaluate forms until one of them doesn't return an error, or return the error from the last
/// form to be executed.
func sf_attempt(args: Params, ctx: Context) -> EvalResult {
  let fn = "attempt"
  if args.count == 0 {
    return .Failure(EvalError.arityError("> 0", actual: args.count, fn))
  }
  var error : EvalError? = nil
  for form in args {
    let try = form.evaluate(ctx)
    switch try {
    case .Success: return try
    case .Recur: error = EvalError(.RecurMisuseError, fn)
    case let .Failure(e): error = e
    }
  }
  return .Failure(error!)
}


// MARK: Helper functions

/// Given a list of args (all of which should be symbols), extract the strings corresponding with their argument names,
/// as well as any variadic parameter that exists.
private func extractParameters(args: [ConsValue], ctx: Context) -> ([InternedSymbol], InternedSymbol?)? {
  // Returns a list of symbol names representing the parameter names, as well as the variadic parameter name (if any)
  var names : [InternedSymbol] = []
  for arg in args {
    switch arg {
    case let .Symbol(s): names.append(s)
    default: return nil // Non-symbol objects in argument list are invalid
    }
  }
  // No '&' allowed anywhere except for second-last position
  for (idx, symbol) in enumerate(names) {
    if symbol == ctx.symbolForName("&") && idx != names.count - 2 {
      return nil
    }
  }
  // Check to see if there's a variadic argument
  if names.count >= 2 && ctx.nameForSymbol(names[names.count - 2]) == "&" {
    return (Array(names[0..<names.count-2]), names[names.count-1])
  }
  else {
    return (names, nil)
  }
}

/// Given an item (expected to be a vector or a list), with the first item a vector of argument bindings, return a new
/// SingleFn instance.
private func buildSingleFnFor(item: ConsValue, #ctx: Context) -> SingleFn? {
  let itemAsVector : VectorType? = {
    switch item {
    case let .List(l): return collectSymbols(l).asArray
    case let .Vector(v): return v
    default: return nil
    }
  }()
  if let vector = itemAsVector {
    // The argument 'item' was a valid list or vector
    if vector.count == 0 {
      return nil
    }
    if let params = vector[0].asVector {
      if let paramTuple = extractParameters(params, ctx) {
        // Now we've taken out the parameters (they are symbols in a vector
        let (paramNames, variadic) = paramTuple
        let forms = vector.count > 1 ? Array(vector[1..<vector.count]) : []
        return SingleFn(parameters: paramNames, forms: forms, variadicParameter: variadic)
      }
    }
  }
  return nil
}

/// Given an appropriate generic collection of arguments, run the do special form.
private func do_exprs<T : CollectionType where T.Generator.Element == ConsValue, T.Index == Int>(args: T, ctx: Context) -> EvalResult {
  let fn = "do"
  var finalValue : ConsValue = .Nil
  for (idx, expr) in enumerate(args) {
    let result = expr.evaluate(ctx)
    switch result {
    case let .Success(result):
      finalValue = result
    case .Recur:
      return (idx == args.endIndex - 1) ? result : .Failure(EvalError(.RecurMisuseError, fn,
        message: "recur came before the final expression in a do-form"))
    case .Failure:
      return result
    }
  }
  return .Success(finalValue)
}
