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
private func prebuildFn(arities: [SingleFn], asMacro: Bool) -> PrebuildResult {
  let fn = asMacro ? "defmacro" : "fn"
  if arities.count == 0 {
    // Must have at least one arity
    return .Failure(EvalError(.NoFnAritiesError, fn))
  }
  // Do validation
  var variadic : SingleFn? = nil
  var aritiesMap : [Int : SingleFn] = [:]
  for arity in arities {
    // 1. Only one variable arity definition
    if arity.isVariadic {
      if variadic != nil {
        return .Failure(EvalError(.MultipleVariadicAritiesError, fn))
      }
      variadic = arity
    }
    // 2. Only one definition per fixed arity
    if !arity.isVariadic {
      if aritiesMap[arity.paramCount] != nil {
        return .Failure(EvalError(.MultipleDefinitionsPerArityError, fn))
      }
      aritiesMap[arity.paramCount] = arity
    }
  }
  if let actualVariadic = variadic {
    for arity in arities {
      // 3. If variable arity definition, no fixed-arity definitions can have more params than the variable arity def
      if !arity.isVariadic && arity.paramCount > actualVariadic.paramCount {
        return .Failure(EvalError(.FixedArityExceedsVariableArityError, fn))
      }
    }
  }
  return .Success((aritiesMap, variadic))
}

/// A struct representing a single-arity definition for a function or macro. A given function or macro is comprised of
/// one or more SingleFn structs, each corresponding to a definition for a different arity.
struct SingleFn {
  let parameters : [InternedSymbol]
  let forms : [ConsValue]
  let variadicParameter : InternedSymbol?
  var paramCount : Int {
    return parameters.count
  }
  var isVariadic : Bool {
    return variadicParameter != nil
  }

  func bindToNewContext(arguments: [ConsValue], ctx: Context, asRecur: Bool) -> Context? {
    // Precondition: arguments has an appropriate number of arguments for the function
    // Create the bindings. One binding per parameter
    if (isVariadic && arguments.count < parameters.count) || (!isVariadic && arguments.count != parameters.count) {
      return nil
    }
    var bindings : [InternedSymbol : Binding] = [:]
    var i=0
    for ; i<parameters.count; i++ {
      bindings[parameters[i]] = .Param(arguments[i])
    }
    if let variadicParameter = variadicParameter {
      if asRecur {
        // If we're rebinding parameters, we MUST have a vararg if the function signature specifies a vararg.
        // This matches Clojure's behavior.
        if arguments.count != parameters.count + 1 {
          return nil
        }
        // Bind the last argument directly to the vararg param; because of the above check 'last' will always be valid
        bindings[variadicParameter] = .Literal(arguments.last!)
      }
      else {
        // Add the rest of the arguments (if any) to the vararg vector
        if arguments.count > parameters.count {
          let rest = Array(arguments[i..<arguments.count])
          bindings[variadicParameter] = .Literal(.List(listFromCollection(rest)))
        }
        else {
          bindings[variadicParameter] = .Literal(.Nil)
        }
      }
    }
    let newContext = buildContext(parent: ctx, bindings: bindings)
    return newContext
  }

  func evaluate(arguments: [ConsValue], _ ctx: Context) -> EvalResult {
    // Create the context, then perform a 'do' with the body of the function
    var possibleContext : Context? = bindToNewContext(arguments, ctx: ctx, asRecur: false)
    while true {
      if let newContext = possibleContext {
        let result = sf_do(forms, newContext)
        switch result {
        case let .Recur(newBindings):
          // If result is 'recur', we need to rebind and run the function again from the start.
          possibleContext = bindToNewContext(newBindings, ctx: ctx, asRecur: true)
          continue
        case .Success, .Failure:
          return result
        }
      }
      return .Failure(EvalError(.ArityError, "(user-defined function)"))
    }
  }
}

/// An opaque class describing a user-defined Lambdatron function.
public class Function : Printable {
  let context : Context!
  let variadic : SingleFn?
  let specificFns : [Int : SingleFn]
  
  class func buildFunction(arities: [SingleFn], name: InternedSymbol?, ctx: Context) -> EvalResult {
    let result = prebuildFn(arities, false)
    switch result {
    case let .Success((aritiesMap, variadic)):
      let function = Function(specificFns: aritiesMap, variadic: variadic, name: name, ctx: ctx)
      return .Success(.FunctionLiteral(function))
    case let .Failure(f):
      return .Failure(f)
    }
  }
  
  init(specificFns: [Int : SingleFn], variadic: SingleFn?, name: InternedSymbol?, ctx: Context) {
    self.specificFns = specificFns
    self.variadic = variadic
    // Bind the context, based on whether or not we provided an actual name
    if let actualName = name {
      context = buildContext(parent: ctx, bindings: [actualName : .Literal(.FunctionLiteral(self))])
    }
    else {
      context = ctx
    }
  }
  
  func evaluate(arguments: [ConsValue]) -> EvalResult {
    // Note that this method doesn't take an external context. This is because there are only two possible contexts:
    //  1. the values bound to the formal parameters
    //  2. any values captured when the function was defined (NOT executed)
    // Get the correct function
    if let functionToUse = specificFns[arguments.count] {
      // We have a valid fixed arity definition to use; use it
      return functionToUse.evaluate(arguments, context)
    }
    else if let varargFunction = variadic {
      if arguments.count >= varargFunction.paramCount {
        // We have a valid variable arity definition to use (e.g. at least as many argument values as vararg params)
        return varargFunction.evaluate(arguments, context)
      }
    }
    return .Failure(EvalError(.ArityError, "(user-defined function)"))
  }

  public var description : String {
    return describe(nil)
  }
}

/// An enum representing the result of trying to build a macro.
enum MacroCreationResult {
  case Success(Macro)
  case Failure(EvalError)
}

/// A class representing a macro.
final internal class Macro : Function {
  // It's not clear to me whether Macro should be a subclass of Function or not. If they are, this implies that Macros
  // can be used where Functions are (e.g. in ConsValue.FunctionLiteral), which is absolutely not true. If they aren't,
  // there are now two unrelated classes repeating almost all of their code.
  let name : InternedSymbol

  class func buildMacro(arities: [SingleFn], name: InternedSymbol, ctx: Context) -> MacroCreationResult {
    let result = prebuildFn(arities, true)
    switch result {
    case let .Success((aritiesMap, variadic)):
      let macro = Macro(specificFns: aritiesMap, variadic: variadic, name: name, ctx: ctx)
      return .Success(macro)
    case let .Failure(f):
      return .Failure(f)
    }
  }

  func macroexpand(arguments: [ConsValue]) -> EvalResult {
    return super.evaluate(arguments)
  }

  init(specificFns: [Int : SingleFn], variadic: SingleFn?, name: InternedSymbol, ctx: Context) {
    self.name = name
    // Note that macros can't be bound to anything but Vars, so passing in a name is meaningless.
    super.init(specificFns: specificFns, variadic: variadic, name: nil, ctx: ctx)
  }
}
