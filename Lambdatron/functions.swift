//
//  functions.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/13/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum describing errors that can happen at runtime when evaluating macros, functions, or special forms
enum EvalError : Printable {
  case ArityError, InvalidArgumentError, DivideByZeroError, RecurMisuseError
  case CustomError(String)
  
  var description : String {
    switch self {
    case ArityError: return "wrong number of arguments to macro, function, or special form"
    case InvalidArgumentError: return "invalid argument provided to macro, function, or special form"
    case DivideByZeroError: return "attempted to divide by zero"
    case .RecurMisuseError: return "didn't use recur in the correct position"
    case let CustomError(c): return c
    }
  }
}

enum EvalResult {
  case Success(ConsValue)
  case Failure(EvalError)
}

struct SingleFn : Printable {
  let parameters : [String]
  let forms : [ConsValue]
  let variadicParameter : String?
  var paramCount : Int {
    return parameters.count
  }
  var isVariadic : Bool {
    return variadicParameter != nil
  }
  
  func bindToNewContext(arguments: [ConsValue], ctx: Context) -> Context? {
    // Precondition: arguments has an appropriate number of arguments for the function
    // Create the bindings. One binding per parameter
    if (isVariadic && arguments.count < parameters.count) || (!isVariadic && arguments.count != parameters.count) {
      return nil
    }
    var bindings : [String : Binding] = [:]
    var i=0
    for ; i<parameters.count; i++ {
      bindings[parameters[i]] = .Literal(arguments[i])
    }
    if let variadicParameter = variadicParameter {
      // Add the rest of the arguments (if any) to the vararg vector
      let rest = arguments.count > parameters.count ? Array(arguments[i..<arguments.count]) : []
      bindings[variadicParameter] = .Literal(.VectorLiteral(rest))
    }
    let newContext = Context(parent: ctx, bindings: bindings)
    return newContext
  }
  
  func evaluate(arguments: [ConsValue], ctx: Context) -> EvalResult {
    // Create the context, then perform a 'do' with the body of the function
    var possibleContext : Context? = bindToNewContext(arguments, ctx: ctx)
    while true {
      if let newContext = possibleContext {
        let result = sf_do(forms, newContext)
        switch result {
        case let .Success(resultValue):
          switch resultValue {
          case let .RecurSentinel(newBindings):
            // If result is 'recur', we need to rebind and run the function again from the start.
            possibleContext = bindToNewContext(newBindings, ctx: ctx)
            continue
          default:
            return result
          }
        case .Failure:
          return result
        }
      }
      return .Failure(.ArityError)
    }
  }
  
  var description : String {
    // Print out the description. For example, "[a b] (print a) (+ a b 1)"
    let paramVector : [String] = {
      if let v = self.variadicParameter {
        return self.parameters + ["&", v]
      }
      return self.parameters
    }()
    let paramRaw = join(" ", paramVector)
    let paramString = "[\(paramRaw)]"
    let formsVector = forms.map({$0.description})
    var finalVector = [paramString] + formsVector
    return join(" ", finalVector)
  }
}

class Function : Printable {
  let context : Context?
  let variadic : SingleFn?
  let specificFns : [Int : SingleFn]
  
  // Construct a new Fn argument corresponding to a single-arity function.
  init(parameters: [String], forms: [ConsValue], variadicParam: String?, name: String?, ctx: Context) {
    let single = SingleFn(parameters: parameters, forms: forms, variadicParameter: variadicParam)
    if variadicParam != nil {
      variadic = single
      specificFns = [:]
    }
    else {
      variadic = nil
      specificFns = [single.paramCount : single]
    }
    
    // Bind the context, based on whether or not we provided an actual name
    if let actualName = name {
      context = Context(parent: ctx, bindings: [actualName : .Literal(.FunctionLiteral(self))])
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
    if let context = context {
      if let functionToUse = specificFns[arguments.count] {
        // We have a valid fixed arity definition to use; use it
        return functionToUse.evaluate(arguments, ctx: context)
      }
      else if let varargFunction = variadic {
        if arguments.count >= varargFunction.paramCount {
          // We have a valid variable arity definition to use (e.g. at least as many argument values as vararg params)
          return varargFunction.evaluate(arguments, ctx: context)
        }
      }
      return .Failure(.ArityError)
    }
    internalError("evaluating fn or macro with nil context")
  }
  
  var description : String {
    var count = variadic == nil ? 0 : 1
    count += specificFns.count
    if count == 1 {
      // Only one arity
      let funcString : String = {
        if let v = self.variadic {
          return v.description
        }
        else {
          for (_, item) in self.specificFns {
            return item.description
          }
        }
        internalError("an array with no objects reported itself as having at least one object")
      }()
      return "(fn \(funcString))"
    }
    else {
      fatal("Describing multi-arity functions not yet implemented")
    }
  }
}
