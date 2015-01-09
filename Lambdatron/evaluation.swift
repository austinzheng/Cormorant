//
//  evaluation.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/25/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// The result of evaluating a function, macro, or special form. Successfully returned values or error messages are
/// encapsulated in each case.
enum EvalResult {
  case Success(ConsValue)
  case Failure(EvalError)
}

/// The result of collecting arguments for function evaluation.
enum CollectResult {
  case Success([ConsValue])
  case Failure(EvalError)
}

func next(input: EvalResult, action: ConsValue -> EvalResult) -> EvalResult {
  switch input {
  case let .Success(s): return action(s)
  case .Failure: return input
  }
}

/// Evaluate a form and return either a success or failure
func evaluate(topLevelForm: ConsValue, ctx: Context) -> EvalResult {
  let result = topLevelForm.evaluate(ctx, .Normal)
  switch result {
  case let .Success(r): return r.isRecurSentinel ? .Failure(.RecurMisuseError) : result
  case .Failure: return result
  }
}

extension Cons {
  
  /// Evaluate this list, treating the first item in the list as something that can be eval'ed.
  func evaluate(ctx: Context, _ env: EvalEnvironment) -> EvalResult {
    if let toExecuteSpecialForm = asSpecialForm() {
      logEval("evaluating as special form: \(self.description)")
      // Execute a special form
      // How it works:
      // 1. Arguments are passed in as-is
      // 2. The special form decides whether or not to evaluate or use the arguments
      // 3. The special form returns a value
      let symbols = Cons.collectSymbols(next)
      let result = toExecuteSpecialForm.function(symbols, ctx, env)
      return result
    }
    else if let toExecuteBuiltIn = asBuiltIn(ctx) {
      logEval("evaluating as built-in function: \(self.description)")
      // Execute a built-in primitive
      // Works the exact same way as executing a normal function (see below)
      switch Cons.collectValues(next, ctx: ctx, env: env) {
      case let .Success(values): return toExecuteBuiltIn(values, ctx)
      case let .Failure(f): return .Failure(f)
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
      case .Failure: return expanded
      }
    }
    else if let toExecuteFunction = asFunction(ctx) {
      logEval("evaluating as function: \(self.description)")
      // Execute a normal function
      // How it works:
      // 1. Arguments are evaluated before the function is ever invoked
      // 2. The function only gets the results of the evaluated arguments, and never sees the literal argument forms
      // 3. The function returns a value
      switch Cons.collectValues(next, ctx: ctx, env: env) {
      case let .Success(values): return toExecuteFunction.evaluate(values, env: env)
      case let .Failure(f): return .Failure(f)
      }
    }
    else if let toEvalVector = asVector(ctx) {
      logEval("evaluating as function with vector in function position: \(self.description)")
      // Evaluate a list with a vector in function position
      // How it work:
      // 1. (*vector* *pos*) is translated into (nth *vector* *pos*)
      // 2. Normal function call
      switch Cons.collectValues(self, ctx: ctx, env: env) {
      case let .Success(args):
        if args.count != 2 {
          // Using vector in fn position disallows the user from specifying a fallback. This is to match Clojure's
          // behavior.
          return .Failure(.ArityError)
        }
        return pr_nth(args, ctx)
      case let .Failure(f): return .Failure(f)
      }
    }
    else if let toEvalMap = asMap(ctx) {
      logEval("evaluating as function with map in function position: \(self.description)")
      // Execute a list with a map in function position
      // How it works:
      // 1. (*map* *args*...) is translated into (get *map* *args*...).
      // 2. Normal function call
      switch Cons.collectValues(self, ctx: ctx, env: env) {
      case let .Success(args): return pr_get(args, ctx)
      case let .Failure(f): return .Failure(f)
      }
    }
    else {
      return .Failure(.NotEvalableError)
    }
  }
}

extension ConsValue {
  
  func evaluate(ctx: Context, _ env: EvalEnvironment) -> EvalResult {
    switch self {
    case FunctionLiteral, BuiltInFunction: return .Success(self)
    case let Symbol(v):
      // Look up the value of v
      let binding = ctx[v]
      switch binding {
      case .Invalid:
        switch env {
        case .Normal: return .Failure(.InvalidSymbolError)
        case .Macro: return .Success(self)
        }
      case .Unbound: return .Failure(.UnboundSymbolError)
      case let .Literal(l): return .Success(l)
      case let .MacroParam(mp):
        return .Success(.MacroArgument(Box(mp)))
      case .BoundMacro: return .Failure(.EvaluatingMacroError)
      }
    case NilLiteral, BoolLiteral, IntegerLiteral, FloatLiteral, StringLiteral, Keyword: return .Success(self)
    case let ListLiteral(l):
      // Evaluate the value of the list 'l'
      return l.evaluate(ctx, env)
    case let VectorLiteral(v):
      // Evaluate the value of the vector literal 'v'
      var buffer : [ConsValue] = []
      for form in v {
        let result = form.evaluate(ctx, env)
        switch result {
        case let .Success(result): buffer.append(result)
        case .Failure: return result
        }
      }
      return .Success(.VectorLiteral(buffer))
    case let MapLiteral(m):
      // Evaluate the value of the map literal 'm'
      var newMap : Map = [:]
      for (key, value) in m {
        let evaluatedKey = key.evaluate(ctx, env)
        switch evaluatedKey {
        case let .Success(k):
          let evaluatedValue = value.evaluate(ctx, env)
          switch evaluatedValue {
          case let .Success(v): newMap[k] = v
          case .Failure: return evaluatedValue
          }
        case .Failure: return evaluatedKey
        }
      }
      return .Success(.MapLiteral(newMap))
    case Special: return .Failure(.EvaluatingSpecialFormError)
    case ReaderMacro: return .Failure(.EvaluatingMacroError)
    case None: return .Failure(.EvaluatingNoneError)
    case RecurSentinel: return .Success(self)
    case let MacroArgument(ma):
      // A macro argument is either being evaluated in the environment of a macro definition (in which case it should be
      // not further evaluated), or in the normal environment (in which case it should be treated as a normal value)
      switch env {
      case .Normal: return ma.value.evaluate(ctx, env)
      case .Macro: return .Success(ma.value)
      }
    }
  }
}
