//
//  macros.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/14/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

enum MacroCreationResult {
  case Success(Macro)
  case Failure(EvalError)
}

class Macro {
  let context : Context
  let name : InternedSymbol
  let variadic : SingleFn?
  let specificFns : [Int : SingleFn]
  
  class func buildMacro(arities: [SingleFn], name: InternedSymbol, ctx: Context) -> MacroCreationResult {
    if arities.count == 0 {
      // Must have at least one arity
      return .Failure(.NoFnAritiesError)
    }
    // Do validation
    var variadic : SingleFn? = nil
    var aritiesMap : [Int : SingleFn] = [:]
    for arity in arities {
      // 1. Only one variable arity definition
      if arity.isVariadic {
        if variadic != nil {
          return .Failure(.MultipleVariadicAritiesError)
        }
        variadic = arity
      }
      // 2. Only one definition per fixed arity
      if !arity.isVariadic {
        if aritiesMap[arity.paramCount] != nil {
          return .Failure(.MultipleFnDefinitionsPerArityError)
        }
        aritiesMap[arity.paramCount] = arity
      }
    }
    if let actualVariadic = variadic {
      for arity in arities {
        // 3. If variable arity definition, no fixed-arity definitions can have more params than the variable arity def
        if !arity.isVariadic && arity.paramCount > actualVariadic.paramCount {
          return .Failure(.FixedArityExceedsVariableArityError)
        }
      }
    }
    let newMacro = Macro(specificFns: aritiesMap, variadic: variadic, name: name, ctx: ctx)
    return .Success(newMacro)
  }
  
  init(specificFns: [Int : SingleFn], variadic: SingleFn?, name: InternedSymbol, ctx: Context) {
    self.specificFns = specificFns
    self.variadic = variadic
    self.name = name
    self.context = ctx
  }
  
  func macroexpand(arguments: [ConsValue]) -> EvalResult {
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
    return .Failure(.ArityError)
  }
}
