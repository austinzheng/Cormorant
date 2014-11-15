//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = ([ConsValue], Context) -> EvalResult

/// An enum describing errors that can happen at runtime when evaluating macros, functions, or special forms
enum EvalError : Printable {
  case ArityError, InvalidArgumentError, DivideByZeroError
  case CustomError(String)
  
  var description : String {
    switch self {
    case ArityError: return "wrong number of arguments to macro, function, or special form"
    case InvalidArgumentError: return "invalid argument provided to macro, function, or special form"
    case DivideByZeroError: return "attempted to divide by zero"
    case let CustomError(c): return c
    }
  }
}

enum EvalResult {
  case Success(ConsValue)
  case Failure(EvalError)
}

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
