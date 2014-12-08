//
//  temp_bootstrap.swift
//  Lambdatron
//
//  Created by Austin Zheng on 12/11/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation
import Swift

// NOTE: This file contains definitions for math functions where it's currently not possible to implement directly in
// lbt code efficiently, and potentially other bootstrap code. It will eventually be deleted.

func bootstrap_preprocess(args: [ConsValue]) -> [ConsValue] {
  return args[0..<args.count - 1] + Cons.collectSymbols(args[args.count - 1].asList()!)
}

/// Build initial state for first argument for a mathematical operation. This method returns a tuple containing an
/// integer accumulator, a double accumulator, a mode, and an optional error flag. If the error flag is true, the prior
/// items should be ignored.
private func stateForFirstArgument(first: ConsValue) -> (Int, Double, NumericalMode, Bool) {
  switch extractNumber(first) {
  case let .Integer(v):
    return (v, 0.0, .Integer, false)
  case let .Float(v):
    return (0, v, .Float, false)
  case .Invalid:
    return (0, 0, .Float, true)
  }
}

/// An enum describing the numerical mode of an operation.
private enum NumericalMode {
  case Integer, Float
}

/// Take an arbitrary number of numbers and return their sum.
func bootstrap_plus(args: [ConsValue], ctx: Context) -> EvalResult {
  let args = bootstrap_preprocess(args)
  var mode : NumericalMode = .Integer
  var intAccum : Int = 0
  var floatAccum : Double = 0.0
  
  for arg in args {
    switch extractNumber(arg) {
    case let .Integer(v):
      switch mode {
      case .Integer:
        intAccum += v
      case .Float:
        floatAccum += Double(v)
      }
    case let .Float(v):
      switch mode {
      case .Integer:
        mode = .Float
        floatAccum = Double(intAccum) + v
      case .Float:
        floatAccum += v
      }
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  }
  switch mode {
  case .Integer:
    return .Success(.IntegerLiteral(intAccum))
  case .Float:
    return .Success(.FloatLiteral(floatAccum))
  }
}

/// Take one or more numbers and return their difference. If only one number, returns 0-arg[0].
func bootstrap_minus(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let args = bootstrap_preprocess(args)
  
  // Set up the initial state
  var (intAccum, floatAccum, mode, didError) = stateForFirstArgument(args[0])
  if didError {
    return .Failure(.InvalidArgumentError)
  }
  
  if args.count == 1 {
    // Return 0 - arg[0]
    switch mode {
    case .Integer:
      return .Success(.IntegerLiteral(intAccum * -1))
    case .Float:
      return .Success(.FloatLiteral(floatAccum * -1))
    }
  }
  
  for var i=1; i<args.count; i++ {
    let arg = args[i]
    switch extractNumber(arg) {
    case let .Integer(v):
      switch mode {
      case .Integer:
        intAccum -= v
      case .Float:
        floatAccum -= Double(v)
      }
    case let .Float(v):
      switch mode {
      case .Integer:
        mode = .Float
        floatAccum = Double(intAccum) - v
      case .Float:
        floatAccum -= v
      }
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  }
  switch mode {
  case .Integer:
    return .Success(.IntegerLiteral(intAccum))
  case .Float:
    return .Success(.FloatLiteral(floatAccum))
  }
}

/// Take an arbitrary number of numbers  and return their product.
func bootstrap_multiply(args: [ConsValue], ctx: Context) -> EvalResult {
  var mode : NumericalMode = .Integer
  var intAccum : Int = 1
  var floatAccum : Double = 1.0
  let args = bootstrap_preprocess(args)
  
  for arg in args {
    switch extractNumber(arg) {
    case let .Integer(v):
      switch mode {
      case .Integer:
        intAccum *= v
      case .Float:
        floatAccum *= Double(v)
      }
    case let .Float(v):
      switch mode {
      case .Integer:
        mode = .Float
        floatAccum = Double(intAccum) * v
      case .Float:
        floatAccum *= v
      }
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  }
  switch mode {
  case .Integer:
    return .Success(.IntegerLiteral(intAccum))
  case .Float:
    return .Success(.FloatLiteral(floatAccum))
  }
}

/// Take one or more numbers and return their quotient. If only one number, returns 1/arg[0].
func bootstrap_divide(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let args = bootstrap_preprocess(args)
  
  // Set up the initial state
  var firstArg = extractNumber(args[0])
  var mode : NumericalMode = .Float
  var floatAccum : Double = 0.0
  switch firstArg {
  case let .Integer(v):
    floatAccum = Double(v)
  case let .Float(v):
    floatAccum = v
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
  
  if args.count == 1 {
    // Return 1/arg[0]
    return .Success(.FloatLiteral(1.0/floatAccum))
  }
  
  for var i=1; i<args.count; i++ {
    let arg = args[i]
    switch extractNumber(arg) {
    case let .Integer(v):
      if v == 0 { return .Failure(.DivideByZeroError) }
      floatAccum /= Double(v)
    case let .Float(v):
      if v == 0 { return .Failure(.DivideByZeroError) }
      floatAccum /= v
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  }
  return .Success(.FloatLiteral(floatAccum))
}
