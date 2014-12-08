//
//  singlefn.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum describing errors that can happen at runtime when evaluating macros, functions, or special forms.
enum EvalError : Printable {
  case ArityError, InvalidArgumentError, DivideByZeroError, RecurMisuseError
  case DefineFunctionError(String)
  case CustomError(String)

  var description : String {
    switch self {
    case ArityError: return "wrong number of arguments to macro, function, or special form"
    case InvalidArgumentError: return "invalid argument provided to macro, function, or special form"
    case DivideByZeroError: return "attempted to divide by zero"
    case RecurMisuseError: return "didn't use recur in the correct position"
    case let DefineFunctionError(e): return e
    case let CustomError(c): return c
    }
  }
}

/// The result of evaluating a function, macro, or special form. Successfully returned values or error messages are
/// encapsulated in each case.
enum EvalResult {
  case Success(ConsValue)
  case Failure(EvalError)
}

enum FnType {
  case Function, Macro
}

struct SingleFn : Printable {
  let fnType : FnType
  let parameters : [String]
  let forms : [ConsValue]
  let variadicParameter : String?
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
    var bindings : [String : Binding] = [:]
    var i=0
    for ; i<parameters.count; i++ {
      bindings[parameters[i]] = {
        switch self.fnType {
        case .Function: return .FunctionParam(arguments[i])
        case .Macro: return .MacroParam(arguments[i])
        }
      }()
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
          bindings[variadicParameter] = .Literal(.ListLiteral(Cons.listFromVector(rest)))
        }
        else {
          bindings[variadicParameter] = .Literal(.NilLiteral)
        }
      }
    }
    let newContext = Context(parent: ctx, bindings: bindings)
    return newContext
  }

  func evaluate(arguments: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
    // Create the context, then perform a 'do' with the body of the function
    var possibleContext : Context? = bindToNewContext(arguments, ctx: ctx, asRecur: false)
    while true {
      if let newContext = possibleContext {
        let result = sf_do(forms, newContext, env)
        switch result {
        case let .Success(resultValue):
          switch resultValue {
          case let .RecurSentinel(newBindings):
            // If result is 'recur', we need to rebind and run the function again from the start.
            possibleContext = bindToNewContext(newBindings, ctx: ctx, asRecur: true)
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
