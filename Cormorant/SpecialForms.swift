//
//  SpecialForms.swift
//  Cormorant
//
//  Created by Austin Zheng on 11/10/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias SpecialFormImpl = (Params, Context) -> EvalResult

// TODO: Replace these with static vars on the type.
// Constants for Value-wrapped special forms.
internal let QUOTE = Value.special(.Quote)
internal let IF = Value.special(.If)
internal let DO = Value.special(.Do)
internal let DEF = Value.special(.Def)
internal let LET = Value.special(.Let)
internal let VAR = Value.special(.Var)
internal let FN = Value.special(.Fn)
internal let DEFMACRO = Value.special(.Defmacro)
internal let LOOP = Value.special(.Loop)
internal let RECUR = Value.special(.Recur)
internal let APPLY = Value.special(.Apply)

/// A type describing all the special forms recognized by the interpreter.
public enum SpecialForm : String, CustomStringConvertible {
  // Add special forms below. The string is the name of the special form, and takes precedence over all functions, macros, and user defs
  case Quote = "quote"
  case If = "if"
  case Do = "do"
  case Def = "def"
  case Let = "let"
  case Var = "var"
  case Fn = "fn"
  case Defmacro = "defmacro"
  case Loop = "loop"
  case Recur = "recur"
  case Apply = "apply"
  case Attempt = "attempt"
  
  var function : SpecialFormImpl {
    switch self {
    case Quote: return sf_quote
    case If: return sf_if
    case Do: return sf_do
    case Def: return sf_def
    case Let: return sf_let
    case Var: return sf_var
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
func sf_quote(_ args: Params, _ ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.nilValue)
  }
  let first = args[0]
  return .Success(first)
}

/// Evaluate a conditional, and evaluate one or one of two expressions based on its boolean value.
func sf_if(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "if"
  if args.count != 2 && args.count != 3 {
    return .Failure(EvalError.arityError(expected: "2 or 3", actual: args.count, fn))
  }

  let result = ctx.evaluate(value: args[0]).then { testForm in
    let then = args[1]
    let otherwise : Value? = args.count == 3 ? args[2] : nil

    // Decide what to do with test
    let predicateIsTrue : Bool
    switch testForm {
    case .nilValue: predicateIsTrue = false
    case let .bool(x): predicateIsTrue = x
    default: predicateIsTrue = true
    }

    if predicateIsTrue {
      return ctx.evaluate(value: then)
    }
    else if let otherwise = otherwise {
      return ctx.evaluate(value: otherwise)
    }
    else {
      return .Success(.nilValue)
    }
  }
  return result
}

/// Evaluate all expressions, returning the value of the final expression.
func sf_do(_ args: Params, _ ctx: Context) -> EvalResult {
  return do_exprs(args, ctx)
}

/// Evaluate all expressions, returning the value of the final expression. (This version takes an array instead of a
/// Params object as its first argument.)
func sf_do(_ args: [Value], _ ctx: Context) -> EvalResult {
  return do_exprs(args, ctx)
}

/// Bind or re-bind a global identifier, interning it in the current namespace and optionally assigning it a value. The
/// Var corresponding to the bound identifier is returned.
func sf_def(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "def"
  if args.count == 0 || args.count > 2 {
    return .Failure(EvalError.arityError(expected: "1 or 2", actual: args.count, fn))
  }
  let symbol = args[0]
  let initializer : Value? = args.count > 1 ? args[1] : nil

  switch symbol {
  case let .symbol(sym):
    if let ns = sym.ns where ns != ctx.interpreter.currentNsName {
      // Qualified symbols must be qualified with the current namespace
      return .Failure(EvalError(.QualifiedSymbolMisuseError))
    }
    let name = sym.unqualified
    if let initializer = initializer {
      // If a value is provided, always use that value
      let result = ctx.evaluate(value: initializer)
      switch result {
      case let .Success(result):
        let result = ctx.root.setVar(named: name, toValue: result)
        switch result {
        case let .Just(aVar): return .Success(.`var`(aVar))
        case let .Error(err): return .Failure(err)
        }
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
      let result = ctx.root.setUnboundVar(named: sym.unqualified, shouldUnbind: false)
      switch result {
      case let .Just(aVar): return .Success(.`var`(aVar))
      case let .Error(err): return .Failure(err)
      }
    }
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be a symbol"))
  }
}

/// Create a new lexical scope in which zero or more symbols are bound to the results of corresponding forms; all forms
/// after the binding vector are evaluated in an implicit 'do' form within the context of the new scope.
func sf_let(args: Params, _ ctx: Context) -> EvalResult {
  let fn = "let"
  if args.count == 0 {
    return .Failure(EvalError.arityError(expected: "> 0", actual: args.count, fn))
  }
  let bindingsForm = args[0]
  switch bindingsForm {
  case let .vector(bindingsVector):
    // The first argument is a vector, which is what we want
    if bindingsVector.count % 2 != 0 {
      return .Failure(EvalError(.BindingMismatchError, fn))
    }
    // Create a new context whose parent is the current context. This new context will be updated in-place for each
    //  expression in the binding vector that is evaluated.
    let newContext = LexicalScopeContext(parent: ctx)

    for (bindingSymbol, expression) in PairSequence(bindingsVector) {
      switch bindingSymbol {
      case let .symbol(sym):
        if !sym.isUnqualified {
          return .Failure(EvalError(.QualifiedSymbolMisuseError))
        }

        // Evaluate expression
        // Note that each binding pair benefits from the result of the binding from the previous pair
        let result = newContext.evaluate(value: expression)
        switch result {
        case let .Success(result): newContext.push(binding: result, forSymbol: sym.unqualified)
        default: return result
        }
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "even-indexed arguments in a binding vector must be symbols"))
      }
    }
    
    // Create an implicit 'do' statement with the remainder of the args
    if args.count == 1 {
      // No additional statements is fine
      return .Success(.nilValue)
    }
    let rest = args.rest()
    let result = sf_do(rest, newContext)
    return result
  default:
    return .Failure(EvalError.invalidArgumentError(fn, message: "first argument must be an binding vector"))
  }
}

/// Given a symbol that resolves to a Var, return the reified Var itself (not its value).
func sf_var(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "var"
  if args.count != 1 {
    return .Failure(EvalError.arityError(expected: "1", actual: args.count, fn))
  }
  // Special form takes one argument: a literal symbol
  guard case let .symbol(varSymbol) = args[0] else {
    return .Failure(EvalError.invalidArgumentError(fn, message: "argument must be a symbol"))
  }
  if let varResult : VarType = ctx.root.resolveVar(for: varSymbol) {
    return .Success(.`var`(varResult))
  }
  // Symbol did not resolve to a Var
  return .Failure(EvalError(.InvalidSymbolError))
}

/// Define a user-defined function, consisting of an parameter vector followed by zero or more forms comprising the
/// body, or one or more lists comprised of parameter vectors and body forms. When the function is called, argument
/// values are bound to the parameter symbols, and the body forms are evaluated in an implicit 'do' form. A name can
/// optionally be provided before the argument vector or first arity list, allowing the function to be referenced from
/// within itself.
func sf_fn(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "fn"
  if args.count == 0 {
    return .Failure(EvalError.arityError(expected: "> 0", actual: args.count, fn))
  }
  let name : UnqualifiedSymbol?
  if case let .symbol(nameSymbol) = args[0] {
    // If the optional symbol used as an internal reference to the anonymous function exists, it must be unqualified
    if !nameSymbol.isUnqualified {
      return .Failure(EvalError(.QualifiedSymbolMisuseError))
    }
    name = nameSymbol.unqualified
  }
  else {
    name = nil
  }

  let rest = (name == nil) ? args : args.rest()
  if rest.count == 0 {
    return .Failure(EvalError.arityError(expected: "at least 2 (if first arg is a name)", actual: args.count, fn))
  }
  if case .vector = rest[0] {
    // Single arity
    let singleArity = singleFn(from: .vector(rest.asArray), ctx: ctx)
    if let actualSingleArity = singleArity {
      return Function.buildFunction(arities: [actualSingleArity], name: name, ctx: ctx, asMacro: false)
    }
  }
  else {
    var arityBuffer : [SingleFn] = []
    for potential in rest {
      if let nextFn = singleFn(from: potential, ctx: ctx) {
        arityBuffer.append(nextFn)
      }
      else {
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "arguments must be lists describing a single arity for a function"))
      }
    }
    return Function.buildFunction(arities: arityBuffer, name: name, ctx: ctx, asMacro: false)
  }
  return .Failure(EvalError.invalidArgumentError(fn,
    message: "first argument must be a name, a binding vector, or a single arity function definition"))
}

/// Define a macro. A macro is defined in a similar manner to a function, except that macros must be bound to a global
/// binding and cannot be treated as values. The Var corresponding to the bound macro is returned.
func sf_defmacro(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "defmacro"
  if args.count < 2 {
    return .Failure(EvalError.arityError(expected: "2 or more", actual: args.count, fn))
  }
  if case let .symbol(sym) = args[0] {
    if let ns = sym.ns where ns != ctx.interpreter.currentNsName {
      // Qualified symbols must be qualified with the current namespace
      return .Failure(EvalError(.QualifiedSymbolMisuseError))
    }
    let name = sym.unqualified
    let rest = args.rest()
    if case .vector = rest[0] {
      // Single arity
      let singleArity = singleFn(from: .vector(rest.asArray), ctx: ctx)
      if let actualSingleArity = singleArity {
        let macroResult = Macro.buildFunction(arities: [actualSingleArity], name: name, ctx: ctx, asMacro: true)
        switch macroResult {
        case let .Success(macro):
          return ctx.root.setVar(named: name, toValue: macro).then { .Success(.`var`($0)) }
        case .Recur, .Failure:
          return macroResult
        }
      }
    }
    else {
      var arityBuffer : [SingleFn] = []
      for potential in rest {
        if let nextFn = singleFn(from: potential, ctx: ctx) {
          arityBuffer.append(nextFn)
        }
        else {
          return .Failure(EvalError.invalidArgumentError(fn,
            message: "arguments must be lists describing a single arity for a macro"))
        }
      }
      let macroResult = Macro.buildFunction(arities: arityBuffer, name: name, ctx: ctx, asMacro: true)
      switch macroResult {
      case let .Success(macro):
        let result = ctx.root.setVar(named: name, toValue: macro)
        switch result {
        case let .Just(aVar): return .Success(.`var`(aVar))
        case let .Error(err): return .Failure(err)
        }
      case .Recur, .Failure: return macroResult
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
func sf_loop(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "loop"
  if args.count == 0 {
    return .Failure(EvalError.arityError(expected: "> 0", actual: args.count, fn))
  }
  if case let .vector(bindingsVector) = args[0] {
    // The first argument must be a vector of bindings and values
    // Evaluate each binding's initializer and bind it to the corresponding symbol
    if bindingsVector.count % 2 != 0 {
      return .Failure(EvalError(.BindingMismatchError, fn))
    }
    // thisContext is the new context within which the loop executes. If there are any bindings they are added into this
    //  context.
    let thisContext = LexicalScopeContext(parent: ctx)
    var symbols : [UnqualifiedSymbol] = []

    for (name, expression) in PairSequence(bindingsVector) {
      switch name {
      case let .symbol(sym):
        if !sym.isUnqualified {
          return .Failure(EvalError(.QualifiedSymbolMisuseError))
        }
        let result = thisContext.evaluate(value: expression)
        switch result {
        case let .Success(result):
          thisContext.push(binding: result, forSymbol: sym.unqualified)
        case .Recur:
          return .Failure(EvalError(.RecurMisuseError, fn,
            message: "recur came before the final expression in a loop"))
        case .Failure:
          return result
        }
        symbols.append(sym)
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "even-indexed arguments in a binding vector must be symbols"))
      }
    }
    let forms = args.rest()

    // Now, run the loop body
    while true {
      let result = sf_do(forms, thisContext)
      switch result {
      case let .Recur(newBindingValues):
        // If result is 'recur', we need to rebind and run the loop again from the start.
        if newBindingValues.count != symbols.count {
          return .Failure(EvalError.arityError(expected: "\(symbols.count)", actual: newBindingValues.count, fn))
        }
        for (idx, newValue) in newBindingValues.enumerated() {
          thisContext.update(binding: newValue, forSymbol: symbols[idx])
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
func sf_recur(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "recur"
  // recur can *only* be used inside the context of a 'loop' or a fn declaration
  // Evaluate all arguments, and then create a sentinel value
  var buffer = Params()
  for arg in args {
    let result = ctx.evaluate(value: arg)
    switch result {
    case let .Success(result): buffer.append(result)
    case .Recur: return .Failure(EvalError(.RecurMisuseError, fn))
    case .Failure: return result
    }
  }
  return .Recur(buffer)
}

/// Given a function, zero or more leading arguments, and a sequence of args, apply the function with the arguments.
func sf_apply(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "apply"
  if args.count < 2 {
    return .Failure(EvalError.arityError(expected: "2 or more", actual: args.count, fn))
  }
  let result = ctx.evaluate(value: args[0]).then { applyee in
    // Collect all remaining args
    var argumentsToApply = Params()
    
    // Add all leading args (after being evaluated) to the list directly
    for i in 1..<(args.count - 1) {
      let res = ctx.evaluate(value: args[i])
      switch res {
      case let .Success(res): argumentsToApply.append(res)
      case .Recur: return .Failure(EvalError(.RecurMisuseError, fn))
      case .Failure: return res
      }
    }

    // Evaluate the last argument, which should be some sort of collection.
    // Note that, since there can never be zero arguments, last will always be non-nil.
    let last = ctx.evaluate(value: args.last!)
    switch last {
    case let .Success(last):
      // If the result is a collection, add all items in the collection to the arguments buffer
      switch last {
      case .nilValue: break
      case let .seq(seq):
        for item in SeqIterator(seq) {
          // Add each item to the params object
          switch item {
          case let .Just(item): argumentsToApply.append(item)
          case let .Error(err): return .Failure(err)
          }
        }
      case let .vector(v):
        for item in v {
          argumentsToApply.append(item)
        }
      case let .map(m):
        for vector in MapSequence(m) {
          argumentsToApply.append(vector)
        }
      default:
        return .Failure(EvalError.invalidArgumentError(fn,
          message: "last argument must be a collection or nil"))
      }
    case .Recur: return .Failure(EvalError(.RecurMisuseError, fn))
    case .Failure: return last
    }
    
    // Apply the function to the arguments in the buffer
    return ctx.apply(arguments: argumentsToApply, toFunction: applyee, fn)
  }
  return result
}

/// Given at least one form, evaluate forms until one of them doesn't return an error, or return the error from the last
/// form to be executed.
func sf_attempt(_ args: Params, _ ctx: Context) -> EvalResult {
  let fn = "attempt"
  if args.count == 0 {
    return .Failure(EvalError.arityError(expected: "> 0", actual: args.count, fn))
  }
  var error : EvalError? = nil
  for form in args {
    let attempt = ctx.evaluate(value: form)
    switch attempt {
    case .Success: return attempt
    case .Recur: error = EvalError(.RecurMisuseError, fn)
    case let .Failure(e): error = e
    }
  }
  return .Failure(error!)
}


// MARK: Helper functions

/// Given a list of args (all of which should be symbols), extract the strings corresponding with their argument names,
/// as well as any variadic parameter that exists.
private func extractParameters(_ args: [Value], _ ctx: Context) -> ([UnqualifiedSymbol], UnqualifiedSymbol?)? {
  // Returns a list of symbol names representing the parameter names, as well as the variadic parameter name (if any)
  // TODO: This function should return errors on failure, instead of nil
  var names : [UnqualifiedSymbol] = []
  for arg in args {
    switch arg {
    case let .symbol(sym):
      if !sym.isUnqualified {
        return nil  // really should return a QualifiedSymbolMisuseError instead
      }
      names.append(sym.unqualified)
    default: return nil // Non-symbol objects in argument list are invalid
    }
  }
  // No '&' allowed anywhere except for second-last position
  for (idx, symbol) in names.enumerated() {
    if symbol.qualified == ctx.ivs.internedString(for: ._And) && idx != names.count - 2 {
      return nil
    }
  }
  // Check to see if there's a variadic argument (e.g. & followed by a vararg symbol)
  if names.count >= 2 {
    let secondLast = names[names.count - 2]
    if secondLast.qualified == ctx.ivs.internedString(for: ._And) {
      return (Array(names[0..<names.count-2]), names[names.count-1])
    }
  }
  return (names, nil)
}

/// Given an item (expected to be a vector or a list), with the first item a vector of argument bindings, return a new
/// SingleFn instance.
private func singleFn(from item: Value, ctx: Context) -> SingleFn? {
  let itemAsVector : VectorType?
  switch item {
  case let .seq(seq):
    switch collectSymbols(seq) {
    case let .Just(params): itemAsVector = params.asArray
      // XXX: This should properly propagate the error.
    case .Error: itemAsVector = nil
    }
  case let .vector(v): itemAsVector = v
  default: itemAsVector = nil
  }

  if let vector = itemAsVector {
    // The argument 'item' was a valid list or vector
    if vector.count == 0 {
      return nil
    }
    if case let .vector(params) = vector[0], let paramTuple = extractParameters(params, ctx) {
      // Now we've taken out the parameters (they are symbols in a vector
      let (paramNames, variadic) = paramTuple
      let forms = vector.count > 1 ? Array(vector[1..<vector.count]) : []
      return SingleFn(parameters: paramNames, forms: forms, variadicParameter: variadic)
    }
  }
  return nil
}

/// Given an appropriate generic collection of arguments, run the do special form.
private func do_exprs<T : Collection where T.Iterator.Element == Value, T.Index == Int>(_ args: T, _ ctx: Context) -> EvalResult {
  let fn = "do"
  var finalValue = Value.nilValue
  for (idx, expr) in args.enumerated() {
    let result = ctx.evaluate(value: expr)
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
