//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = ([ConsValue], Context) -> EvalResult

func extractNumber(n: ConsValue) -> Double? {
  let x : Double? = {
    switch n {
    case let .NumberLiteral(number):
      return number
    default: return nil
    }
    }()
  return x
}

func extractNumbers(n: [ConsValue]) -> [Double]? {
  let raw = n.map(extractNumber)
  if raw.filter({$0 == nil}).count != 0 {
    return nil
  }
  return raw.map({$0!})
}

func extractList(n: ConsValue) -> Cons? {
  let x : Cons? = {
    switch n {
    case let .ListLiteral(list):
      return list
    default: return nil
    }
  }()
  return x
}


// MARK: Collections

func pr_list(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Success(.ListLiteral(Cons()))
  }
  let first = Cons(args[0])
  var current = first
  for var i=1; i<args.count; i++ {
    let this = Cons(args[i])
    current.next = this
    current = this
  }
  return .Success(.ListLiteral(first))
}

func pr_vector(args: [ConsValue], ctx: Context) -> EvalResult {
  return .Success(.VectorLiteral(args))
}


// MARK: Typechecking

func pr_isNumber(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .NumberLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isString(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .StringLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isSymbol(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .Symbol: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isFunction(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .FunctionLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isEvalable(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  // User-defined functions, built-ins, and special forms are eval'able.
  // TODO: vectors, maps, and sets should also be eval'able, as they are in Clojure
  switch args[0] {
  case .FunctionLiteral, .Special: return .Success(.BoolLiteral(true))
  case let .Symbol(s):
    switch ctx[s] {
    case .BuiltIn: return .Success(.BoolLiteral(true))
    default: return .Success(.BoolLiteral(false))
    }
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isTrue(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == true))
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isFalse(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == false))
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isList(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .ListLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

func pr_isVector(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .VectorLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}


// MARK: I/O

/// Print zero or more args to screen. Returns nil
func pr_print(args: [ConsValue], ctx: Context) -> EvalResult {
  func toString(v: ConsValue) -> String {
    switch v {
    case let .StringLiteral(s): return s
    default: return v.description
    }
  }
  let descs = args.map(toString)
  let outStr = descs.count > 0 ? join(" ", descs) : ""
  print(outStr)
  return .Success(.NilLiteral)
}


// MARK: Comparison

/// Evaluate the equality of one or more forms
func pr_equals(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  var this = args[0]
  for var i=1; i<args.count; i++ {
    if this != args[i] {
      return .Success(.BoolLiteral(false))
    }
  }
  return .Success(.BoolLiteral(true))
}

/// Evaluate whether arguments are in monotonically decreasing order
func pr_gt(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let maybeNumbers = extractNumbers(args)
  if let numbers = maybeNumbers {
    var current = numbers[0]
    for var i=1; i<numbers.count; i++ {
      if numbers[i] >= current {
        return .Success(.BoolLiteral(false))
      }
      current = numbers[i]
    }
    return .Success(.BoolLiteral(true))
  }
  return .Failure(.InvalidArgumentError)
}

/// Evaluate whether arguments are in monotonically increasing order
func pr_lt(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let maybeNumbers = extractNumbers(args)
  if let numbers = maybeNumbers {
    var current = numbers[0]
    for var i=1; i<numbers.count; i++ {
      if numbers[i] <= current {
        return .Success(.BoolLiteral(false))
      }
      current = numbers[i]
    }
    return .Success(.BoolLiteral(true))
  }
  return .Failure(.InvalidArgumentError)
}


// MARK: Arithmetic

/// Take an arbitrary number of numbers and return their sum
func pr_plus(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let maybeNumbers = extractNumbers(args)
  if let numbers = maybeNumbers {
    return .Success(.NumberLiteral(numbers.reduce(0, combine: +)))
  }
  return .Failure(.InvalidArgumentError)
}

/// Take an arbitrary number of numbers and return their difference
func pr_minus(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  var acc : Double = 0
  let maybeNumbers = extractNumbers(args)
  if let numbers = maybeNumbers {
    var acc = numbers[0]
    for var i=1; i<numbers.count; i++ {
      acc -= numbers[i]
    }
    return .Success(.NumberLiteral(acc))
  }
  return .Failure(.InvalidArgumentError)
}

/// Take an arbitrary number of numbers  and return their product
func pr_multiply(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count == 0 {
    return .Failure(EvalError.ArityError)
  }
  let maybeNumbers = extractNumbers(args)
  if let numbers = maybeNumbers {
    return .Success(.NumberLiteral(numbers.reduce(1, combine: *)))
  }
  return .Failure(.InvalidArgumentError)
}

/// Take two numbers and return their quotient
func pr_divide(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let (x, y) = (extractNumber(args[0]), extractNumber(args[1]))
  if x == nil || y == nil {
    return .Failure(.InvalidArgumentError)
  }
  if y == 0 {
    return .Failure(.DivideByZeroError)
  }
  return .Success(.NumberLiteral(x! / y!))
}
