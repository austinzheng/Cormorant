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
  let name : String
  let variadic : SingleFn?
  let specificFns : [Int : SingleFn]
  
  class func buildMacro(arities: [SingleFn], name: String, ctx: Context) -> MacroCreationResult {
    if arities.count == 0 {
      // Must have at least one arity
      return .Failure(.DefineFunctionError("macro must be defined with at least one arity"))
    }
    // Do validation
    var variadic : SingleFn? = nil
    var aritiesMap : [Int : SingleFn] = [:]
    for arity in arities {
      // 1. Only one variable arity definition
      if arity.isVariadic {
        if variadic != nil {
          return .Failure(.DefineFunctionError("macro can only be defined with at most one variadic arity"))
        }
        variadic = arity
      }
      // 2. Only one definition per fixed arity
      if !arity.isVariadic {
        if aritiesMap[arity.paramCount] != nil {
          return .Failure(.DefineFunctionError("macro can only be defined with one definition per fixed arity"))
        }
        aritiesMap[arity.paramCount] = arity
      }
    }
    if let actualVariadic = variadic {
      for arity in arities {
        // 3. If variable arity definition, no fixed-arity definitions can have more params than the variable arity def
        if !arity.isVariadic && arity.paramCount > actualVariadic.paramCount {
          return .Failure(.DefineFunctionError("macro's fixed arities cannot have more params than variable arity"))
        }
      }
    }
    let newMacro = Macro(specificFns: aritiesMap, variadic: variadic, name: name, ctx: ctx)
    return .Success(newMacro)
  }
  
  init(specificFns: [Int : SingleFn], variadic: SingleFn?, name: String, ctx: Context) {
    self.specificFns = specificFns
    self.variadic = variadic
    self.name = name
    self.context = ctx
  }
  
  func macroexpand(arguments: [ConsValue]) -> EvalResult {
    if let functionToUse = specificFns[arguments.count] {
      // We have a valid fixed arity definition to use; use it
      return functionToUse.evaluate(arguments, ctx: context, env: .Macro)
    }
    else if let varargFunction = variadic {
      if arguments.count >= varargFunction.paramCount {
        // We have a valid variable arity definition to use (e.g. at least as many argument values as vararg params)
        return varargFunction.evaluate(arguments, ctx: context, env: .Macro)
      }
    }
    internalError("macro was somehow defined without any arities; this is a bug")
  }
}

extension Cons {
  
  class func purgeMacroArgs(start: Cons) -> ConsValue {
    // Purge each arg
    var this : Cons? = start
    while let actualThis = this {
      actualThis.value = actualThis.value.purgeMacroArgs()
      this = actualThis.next
    }
    return .ListLiteral(start)
  }
}

extension ConsValue {
  
  func purgeMacroArgs() -> ConsValue {
    switch self {
    case let .MacroArgument(m):
      return m.value
    case let .ListLiteral(l):
      return Cons.purgeMacroArgs(l)
    case let .VectorLiteral(v):
      return .VectorLiteral(v.map({$0.purgeMacroArgs()}))
    default:
      return self
    }
  }
}
