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
  
  var function : LambdatronSpecialForm {
    switch self {
    case .Quote: return sf_quote
    case .If: return sf_if
    case .Do: return sf_do
    }
  }
}

/// Return the raw form, without any evaluation
func sf_quote(args: [ConsValue]) -> EvalResult {
  if args.count == 0 {
    return .Success(.NilLiteral)
  }
  let first = args[0]
  return .Success(first)
}

/// Evaluate a conditional, and evaluate one or one of two expressions
func sf_if(args: [ConsValue]) -> EvalResult {
  if args.count != 2 && args.count != 3 {
    return .Failure(.ArityError)
  }
  let test = args[0].evaluate()
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
    return .Success(then.evaluate())
  }
  else if let actualOtherwise = otherwise {
    return .Success(actualOtherwise.evaluate())
  }
  else {
    return .Success(.NilLiteral)
  }
}

/// Evaluate all expressions, returning the value of the final expression
func sf_do(args: [ConsValue]) -> EvalResult {
  var finalValue : ConsValue = .NilLiteral
  for expr in args {
    finalValue = expr.evaluate()
  }
  return .Success(finalValue)
}
