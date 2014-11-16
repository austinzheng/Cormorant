//
//  macros.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/14/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

class Macro {
  let name : String
  let variadic : SingleFn?
  let specificFns : [Int : SingleFn]
  
  // Construct a new Macro with a single arity.
  init(parameters: [String], forms: [ConsValue], variadicParam: String?, name: String) {
    self.name = name
    let single = SingleFn(parameters: parameters, forms: forms, variadicParameter: variadicParam)
    if variadicParam != nil {
      variadic = single
      specificFns = [:]
    }
    else {
      variadic = nil
      specificFns = [single.paramCount : single]
    }
  }
  
  func macroexpand(arguments: [ConsValue], ctx: Context) -> EvalResult {
    if let functionToUse = specificFns[arguments.count] {
      // We have a valid fixed arity definition to use; use it
      return functionToUse.evaluate(arguments, ctx: ctx)
    }
    else if let varargFunction = variadic {
      if arguments.count >= varargFunction.paramCount {
        // We have a valid variable arity definition to use (e.g. at least as many argument values as vararg params)
        return varargFunction.evaluate(arguments, ctx: ctx)
      }
    }
    internalError("macro was somehow defined without any arities; this is a bug")
  }
}
