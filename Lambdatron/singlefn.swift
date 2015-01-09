//
//  singlefn.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/19/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

enum FnType {
  case Function, Macro
}

struct SingleFn {
  let fnType : FnType
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
      bindings[parameters[i]] = {
        switch self.fnType {
        case .Function: return .Literal(arguments[i])
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
    let newContext = Context.instance(parent: ctx, bindings: bindings)
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
}
