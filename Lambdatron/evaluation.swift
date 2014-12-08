//
//  evaluation.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/25/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

extension Cons {
  
  /// Evaluate this list, treating the first item in the list as something that can be eval'ed.
  func evaluate(ctx: Context, _ env: EvalEnvironment) -> ConsValue {
    if let toExecuteSpecialForm = asSpecialForm() {
      logEval("evaluating as special form: \(self.description)")
      // Execute a special form
      // How it works:
      // 1. Arguments are passed in as-is
      // 2. The special form decides whether or not to evaluate or use the arguments
      // 3. The special form returns a value
      let symbols = Cons.collectSymbols(next)
      let result = toExecuteSpecialForm.function(symbols, ctx, env)
      switch result {
      case let .Success(v): return v
      case let .Failure(f): fatal("Something went wrong: \(f)")
      }
    }
    else if let toExecuteBuiltIn = asBuiltIn() {
      logEval("evaluating as built-in function: \(self.description)")
      // Execute a built-in primitive
      // Works the exact same way as executing a normal function (see below)
      if let values = Cons.collectValues(next, ctx: ctx, env: env) {
        let result = toExecuteBuiltIn(values, ctx)
        switch result {
        case let .Success(v): return v
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      else {
        fatal("Could not collect values")
      }
    }
    else if let toExpandMacro = asMacro(ctx) {
      logEval("evaluating as macro expansion: \(self.description)")
      // Expand a macro
      // How it works:
      // 1. Arguments are passed in as-is
      // 2. The macro uses the arguments and its body to create a replacement form (piece of code) in its place
      // 3. This replacement form is then evaluated to return a value
      let symbols = Cons.collectSymbols(next)
      let expanded = toExpandMacro.macroexpand(symbols)
      switch expanded {
      case let .Success(v):
        logEval("macroexpansion complete; new form: \(v.description)")
        let macroArgsPurged = v.purgeMacroArgs()
        let result = macroArgsPurged.evaluate(ctx, env)
        return result
      case let .Failure(f): fatal("Something went wrong: \(f)")
      }
    }
    else if let toExecuteFunction = asFunction(ctx) {
      logEval("evaluating as function: \(self.description)")
      // Execute a normal function
      // How it works:
      // 1. Arguments are evaluated before the function is ever invoked
      // 2. The function only gets the results of the evaluated arguments, and never sees the literal argument forms
      // 3. The function returns a value
      if let values = Cons.collectValues(next, ctx: ctx, env: env) {
        let result = toExecuteFunction.evaluate(values, env: env)
        switch result {
        case let .Success(v): return v
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      else {
        fatal("Could not collect values")
      }
    }
    else if let toEvalMap = asMap(ctx) {
      logEval("evaluating as function with map in function position: \(self.description)")
      // Execute a list with a map in function position
      // How it works:
      // 1. (*map* *args*...) is translated into (get *map* *args*...).
      // 2. Normal function call
      if let args = Cons.collectValues(self, ctx: ctx, env: env) {
        let result = pr_get(args, ctx)
        switch result {
        case let .Success(v): return v
        case let .Failure(f): fatal("Something went wrong: \(f)")
        }
      }
      else {
        fatal("Could not collect values")
      }
    }
    else {
      fatal("Cannot call 'evaluate' on this cons list, \(self); first object isn't actually a function. Sorry.")
    }
  }
}

extension ConsValue {
  
  func evaluate(ctx: Context, _ env: EvalEnvironment) -> ConsValue {
    switch self {
    case FunctionLiteral: return self
    case BuiltInFunction: return self
    case let Symbol(v):
      // Look up the value of v
      let binding = ctx[v]
      switch binding {
      case .Invalid:
        switch env {
        case .Normal:
          fatal("Error; symbol '\(v)' doesn't seem to be valid")
        case .Macro:
          return self
        }
      case .Unbound: fatal("Figure out how to handle unbound vars in evaluation")
      case let .Literal(l): return l
      case let .FunctionParam(fp): return fp
      case let .MacroParam(mp):
        return .MacroArgument(Box(mp))
      case .BoundMacro: fatal("TODO - taking the value of a macro should be invalid; we'll return an error")
      }
    case NilLiteral, BoolLiteral, IntegerLiteral, FloatLiteral, StringLiteral: return self
    case let ListLiteral(l):
      // Evaluate the value of the list 'l'
      return l.evaluate(ctx, env)
    case let VectorLiteral(v):
      // Evaluate the value of the vector literal 'v'
      return .VectorLiteral(v.map({$0.evaluate(ctx, env)}))
    case let MapLiteral(m):
      // Evaluate the value of the map literal 'm'
      var newMap : Map = [:]
      for (key, value) in m {
        let evaluatedKey = key.evaluate(ctx, env)
        let evaluatedValue = value.evaluate(ctx, env)
        newMap[evaluatedKey] = evaluatedValue
      }
      return .MapLiteral(newMap)
    case Special: fatal("TODO - taking the value of a special form should be disallowed")
    case ReaderMacro: internalError("reader macro should never be accessible at the eval stage")
    case None: fatal("TODO - taking the value of None should be disallowed, since None is only valid for empty lists")
    case RecurSentinel: return self
    case let MacroArgument(ma):
      // A macro argument is either being evaluated in the environment of a macro definition (in which case it should be
      // not further evaluated), or in the normal environment (in which case it should be treated as a normal value)
      switch env {
      case .Normal: return ma.value.evaluate(ctx, env)
      case .Macro: return ma.value
      }
    }
  }
}
