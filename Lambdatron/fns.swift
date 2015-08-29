//
//  fns.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/13/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum representing the result of prebuilding a function or macro.
private enum PrebuildResult {
  case Success(([Int : SingleFn], SingleFn?))
  case Failure(EvalError)
}

/// Given an array of SingleFn objects representing different arities, return a PrebuildResult that is either an error
/// or a map of arities to SingleFn objects.
private func prebuildFn(arities: [SingleFn]) -> PrebuildResult {
  if arities.count == 0 {
    // Must have at least one arity
    return .Failure(EvalError(.NoFnAritiesError, "(none)"))
  }
  // Do validation
  var variadic : SingleFn? = nil
  var aritiesMap : [Int : SingleFn] = [:]
  for arity in arities {
    // 1. Only one variable arity definition
    if arity.isVariadic {
      if variadic != nil {
        return .Failure(EvalError(.MultipleVariadicAritiesError, "(none)"))
      }
      variadic = arity
    }
    // 2. Only one definition per fixed arity
    if !arity.isVariadic {
      if aritiesMap[arity.paramCount] != nil {
        return .Failure(EvalError(.MultipleDefinitionsPerArityError, "(none)"))
      }
      aritiesMap[arity.paramCount] = arity
    }
  }
  if let actualVariadic = variadic {
    for arity in arities {
      // 3. If variable arity definition, no fixed-arity definitions can have more params than the variable arity def
      if !arity.isVariadic && arity.paramCount > actualVariadic.paramCount {
        return .Failure(EvalError(.FixedArityExceedsVariableArityError, "(none)"))
      }
    }
  }
  return .Success((aritiesMap, variadic))
}

/// A struct representing a single-arity definition for a function or macro. A given function or macro is comprised of
/// one or more SingleFn structs, each corresponding to a definition for a different arity.
struct SingleFn {
  let parameters : [UnqualifiedSymbol]
  let forms : [ConsValue]
  let variadicParameter : UnqualifiedSymbol?
  var paramCount : Int {
    return parameters.count
  }
  var isVariadic : Bool {
    return variadicParameter != nil
  }

  /// Given a child context and a new set of arguments, rebind the arguments in-place. This method is only intended to
  /// be used when a function is run again because of the 'recur' special form.
  private func rebindArguments(arguments: Params, toContext ctx: LexicalScopeContext) -> Bool {
    // Precondition: arguments has an appropriate number of arguments for the function
    // Create the bindings. One binding per parameter
    if (isVariadic && arguments.count < parameters.count) || (!isVariadic && arguments.count != parameters.count) {
      return false
    }
    for (idx, parameter) in parameters.enumerate() {
      let argument : ConsValue = arguments[idx]
      ctx.updateBinding(argument, forSymbol: parameter)
    }
    if let variadicParameter = variadicParameter {
      // If we're rebinding parameters, we MUST have a vararg if the function signature specifies a vararg.
      // This matches Clojure's behavior.
      if arguments.count != parameters.count + 1 {
        return false
      }
      // Bind the last argument directly to the vararg param; because of the above check 'last' will always be valid
      ctx.updateBinding(arguments.last!, forSymbol: variadicParameter)
    }
    return true
  }

  private func bindToNewContext(arguments: Params, ctx: Context) -> LexicalScopeContext? {
    // Precondition: arguments has an appropriate number of arguments for the function
    // Create the bindings. One binding per parameter
    if (isVariadic && arguments.count < parameters.count) || (!isVariadic && arguments.count != parameters.count) {
      return nil
    }
    let newContext = LexicalScopeContext(parent: ctx)
    var i=0
    for ; i<parameters.count; i++ {
      newContext.pushBinding(arguments[i], forSymbol: parameters[i])
    }
    if let variadicParameter = variadicParameter {
      // Add the rest of the arguments (if any) to the vararg vector
      if arguments.count > parameters.count {
        var varargBuffer : [ConsValue] = []
        for var j=i; j<arguments.count; j++ {
          varargBuffer.append(arguments[j])
        }
        newContext.pushBinding(.Seq(sequence(varargBuffer)), forSymbol: variadicParameter)
      }
      else {
        newContext.pushBinding(.Nil, forSymbol: variadicParameter)
      }
    }
    return newContext
  }

  func evaluate(arguments: Params, _ ctx: Context) -> EvalResult {
    // Create the context, then perform a 'do' with the body of the function
    let activeContext = bindToNewContext(arguments, ctx: ctx)
    if let activeContext = activeContext {
      while true {
        let result = sf_do(forms, activeContext)
        switch result {
        case let .Recur(newBindings):
          // If result is 'recur', we need to rebind and run the function again from the start.
          let success = rebindArguments(newBindings, toContext: activeContext)
          if !success {
            return .Failure(EvalError(.ArityError, "(user-defined function)"))
          }
        case .Success, .Failure:
          return result
        }
      }
    }
    return .Failure(EvalError(.ArityError, "(user-defined function)"))
  }
}

public typealias Macro = Function

/// An opaque class describing a user-defined Lambdatron function or macro.
public final class Function {
  private(set) var context : Context!
  let variadic : SingleFn?
  let specificFns : [Int : SingleFn]
  let name : UnqualifiedSymbol?

  var hashValue : Int { return ObjectIdentifier(self).hashValue }
  
  class func buildFunction(arities: [SingleFn], name: UnqualifiedSymbol?, ctx: Context, asMacro: Bool) -> EvalResult {
    let result = prebuildFn(arities)
    switch result {
    case let .Success((aritiesMap, variadic)):
      let function = Function(specificFns: aritiesMap, variadic: variadic, name: name, ctx: ctx)
      return .Success(asMacro ? .MacroLiteral(function) : .FunctionLiteral(function))
    case let .Failure(f):
      return .Failure(f)
    }
  }
  
  init(specificFns: [Int : SingleFn], variadic: SingleFn?, name: UnqualifiedSymbol?, ctx: Context) {
    self.specificFns = specificFns
    self.variadic = variadic
    // Bind the context, based on whether or not we provided an actual name
    if let actualName = name {
      self.name = name
      let newContext = LexicalScopeContext(parent: ctx)
      newContext.pushBinding(.FunctionLiteral(self), forSymbol: actualName)
      context = newContext
    }
    else {
      self.name = nil
      context = ctx
    }
  }
  
  func evaluate(arguments: Params) -> EvalResult {
    // Note that this method doesn't take an external context. This is because there are only two possible contexts:
    //  1. the values bound to the formal parameters
    //  2. any values captured when the function was defined (NOT executed)
    // Get the correct function
    if let functionToUse = specificFns[arguments.count] {
      // We have a valid fixed arity definition to use; use it
      return functionToUse.evaluate(arguments, context)
    }
    else if let varargFunction = variadic where arguments.count >= varargFunction.paramCount {
      // We have a valid variable arity definition to use (e.g. at least as many argument values as vararg params)
      return varargFunction.evaluate(arguments, context)
    }
    return .Failure(EvalError(.ArityError, "(user-defined function)"))
  }
}
