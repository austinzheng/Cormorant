//
//  functions.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/13/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

class Function : Printable {
  let context : Context?
  let variadic : SingleFn?
  let specificFns : [Int : SingleFn]
  
  class func buildFunction(arities: [SingleFn], name: String?, ctx: Context) -> EvalResult {
    if arities.count == 0 {
      // Must have at least one arity
      return .Failure(.DefineFunctionError("function must be defined with at least one arity"))
    }
    // Do validation
    var variadic : SingleFn? = nil
    var aritiesMap : [Int : SingleFn] = [:]
    for arity in arities {
      // 1. Only one variable arity definition
      if arity.isVariadic {
        if variadic != nil {
          return .Failure(.DefineFunctionError("function can only be defined with at most one variadic arity"))
        }
        variadic = arity
      }
      // 2. Only one definition per fixed arity
      if !arity.isVariadic {
        if aritiesMap[arity.paramCount] != nil {
          return .Failure(.DefineFunctionError("function can only be defined with one definition per fixed arity"))
        }
        aritiesMap[arity.paramCount] = arity
      }
    }
    if let actualVariadic = variadic {
      for arity in arities {
        // 3. If variable arity definition, no fixed-arity definitions can have more params than the variable arity def
        if !arity.isVariadic && arity.paramCount > actualVariadic.paramCount {
          return .Failure(.DefineFunctionError("function's fixed arities cannot have more params than variable arity"))
        }
      }
    }
    let newFunction = Function(specificFns: aritiesMap, variadic: variadic, name: name, ctx: ctx)
    return .Success(.FunctionLiteral(newFunction))
  }
  
  init(specificFns: [Int : SingleFn], variadic: SingleFn?, name: String?, ctx: Context) {
    self.specificFns = specificFns
    self.variadic = variadic
    // Bind the context, based on whether or not we provided an actual name
    if let actualName = name {
      context = Context.instance(parent: ctx, bindings: [actualName : .Literal(.FunctionLiteral(self))])
    }
    else {
      context = ctx
    }
  }
  
  func evaluate(arguments: [ConsValue], env: EvalEnvironment) -> EvalResult {
    // Note that this method doesn't take an external context. This is because there are only two possible contexts:
    //  1. the values bound to the formal parameters
    //  2. any values captured when the function was defined (NOT executed)
    // Get the correct function
    if let context = context {
      if let functionToUse = specificFns[arguments.count] {
        // We have a valid fixed arity definition to use; use it
        return functionToUse.evaluate(arguments, ctx: context, env: env)
      }
      else if let varargFunction = variadic {
        if arguments.count >= varargFunction.paramCount {
          // We have a valid variable arity definition to use (e.g. at least as many argument values as vararg params)
          return varargFunction.evaluate(arguments, ctx: context, env: env)
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
      var descs : [String] = []
      for (_, fn) in specificFns {
        descs.append("(\(fn.description))")
      }
      if let variadic = variadic {
        descs.append("(\(variadic.description))")
      }
      let joined = join(" ", descs)
      return "(fn \(joined))"
    }
  }
}
