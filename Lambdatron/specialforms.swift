//
//  specialforms.swift
//  Lambdatron
//
//  Created by Austin Zheng on 11/10/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

/// An enum describing all the special forms recognized by the interpreter
enum SpecialForm : String {
  // Add special forms below. The string is the name of the special form, and takes precedence over all functions, macros, and user defs
  case Quote = "quote"
  case If = "if"
  case Do = "do"
  case Def = "def"
  case Let = "let"
  
  var function : LambdatronSpecialForm {
    switch self {
    case .Quote: return sf_quote
    case .If: return sf_if
    case .Do: return sf_do
    case .Def: return sf_def
    case .Let: return sf_let
    }
  }
}

/// Return the raw form, without any evaluation
func sf_quote(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.NilLiteral)
  }
  let first = args[0]
  return .Success(first)
}

/// Evaluate a conditional, and evaluate one or one of two expressions
func sf_if(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 && args.count != 3 {
    return .Failure(.ArityError)
  }
  let test = args[0].evaluate(ctx)
  let then = args[1]
  let otherwise : ConsValue? = args.count == 3 ? args[2] : nil
  
  // Decide what to do with test
  let testIsTrue : Bool = {
    switch test {
    case .NilLiteral: return false
    case let .BoolLiteral(x): return x
    default: return true
    }
    }()
  
  if testIsTrue {
    return .Success(then.evaluate(ctx))
  }
  else if let actualOtherwise = otherwise {
    return .Success(actualOtherwise.evaluate(ctx))
  }
  else {
    return .Success(.NilLiteral)
  }
}

/// Evaluate all expressions, returning the value of the final expression
func sf_do(args: [ConsValue], ctx: Context) -> EvalResult {
  var finalValue : ConsValue = .NilLiteral
  for expr in args {
    finalValue = expr.evaluate(ctx)
  }
  return .Success(finalValue)
}

func sf_def(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count < 1 {
    return .Failure(.ArityError)
  }
  let symbol = args[0]
  let initializer : ConsValue? = {
    if args.count > 1 {
      return args[1]
    }
    return nil
  }()
  
  switch symbol {
  case let .Symbol(s):
    // Do stuff
    if let actualInit = initializer {
      // If a value is provided, always use that value
      let result = actualInit.evaluate(ctx)
      ctx.setTopLevelBinding(s, value: .Literal(result))
    }
    else {
      // No value is provided
      // If invalid, create the var as unbound
      if !ctx.nameIsValid(s) {
        ctx.setTopLevelBinding(s, value: .Unbound)
      }
    }
    return .Success(symbol)
  default:
    return .Failure(.InvalidArgumentError)
  }
}

func sf_let(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let bindingsForm = args[0]
  switch bindingsForm {
  case let .VectorLiteral(bindingsVector):
    // The first argument is a vector, which is what we want
    if bindingsVector.count % 2 != 0 {
      return .Failure(.CustomError("let binding vector must have an even number of elements"))
    }
    // Create a bindings dictionary for our new context
    var newBindings : [String : Binding] = [:]
    var ctr = 0
    while ctr < bindingsVector.count {
      let name = bindingsVector[ctr]
      switch name {
      case let .Symbol(s):
        // Evaluate expression
        // Note that each binding pair benefits from the result of the binding from the previous pair
        let expression = bindingsVector[ctr+1]
        let result = expression.evaluate(Context(parent: ctx, bindings: newBindings))
        newBindings[s] = .Literal(result)
      default:
        return .Failure(.InvalidArgumentError)
      }
      ctr += 2
    }
    // Create a new context, which is a child of the old context
    let newContext = Context(parent: ctx, bindings: newBindings)
    
    // Create an implicit 'do' statement with the remainder of the args
    if args.count == 1 {
      // No additional statements is fine
      return .Success(.NilLiteral)
    }
    let restOfArgs = Array(args[1..<args.count])
    let result = sf_do(restOfArgs, newContext)
    return result
  default:
    return .Failure(.InvalidArgumentError)
  }
}
