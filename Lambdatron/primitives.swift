//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronFunction = [ConsValue] -> EvalResult
typealias LambdatronSpecialForm = [ConsValue] -> EvalResult
typealias LambdatronMacro = [ConsValue] -> ConsValue

/// An enum describing errors that can happen at runtime when evaluating macros, functions, or special forms
enum EvalError : Printable {
  case ArityError, InvalidArgumentError, DivideByZeroError
  case CustomError(String)
  
  var description : String {
    get {
      switch self {
      case ArityError: return "wrong number of arguments to macro, function, or special form"
      case InvalidArgumentError: return "invalid argument provided to macro, function, or special form"
      case DivideByZeroError: return "attempted to divide by zero"
      case let CustomError(c): return c
      }
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

// MARK: List-related functions

/// Given an item and a sequence, return a new list
func pr_cons(args: [ConsValue]) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let first = args[0]
  let second = args[1]
  switch second {
  case .NilLiteral:
    // Create a new list consisting of just the first object
    return .Success(.ListLiteral(Cons(first)))
  case let .ListLiteral(l):
    // Create a new list consisting of the first object, followed by the second list
    let newCons = Cons(first, next: l)
    return .Success(.ListLiteral(newCons))
  case let .VectorLiteral(v): fatal("Not yet implemented")
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Given a sequence, return the first item
func pr_first(args: [ConsValue]) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let first = args[0]
  switch first {
  case .NilLiteral:
    return .Success(.NilLiteral)
  case let .ListLiteral(l):
    switch l.value {
    case .None: return .Success(.NilLiteral)
    default: return .Success(l.value)
    }
  case let .VectorLiteral(v): fatal("Not yet implemented")
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Given a sequence, return the sequence comprised of all items but the first
func pr_rest(args: [ConsValue]) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let first = args[0]
  switch first {
  case .NilLiteral: return .Success(.ListLiteral(Cons()))
  case let .ListLiteral(l):
    if let actualNext = l.next {
      // List has more than one item
      return .Success(.ListLiteral(actualNext))
    }
    else {
      // List has zero or one items, return the empty list
      return .Success(.ListLiteral(Cons()))
    }
  default: return .Failure(.InvalidArgumentError)
  }
}


// MARK: Comparison

/// Evaluate the equality of one or more forms
func pr_equals(args: [ConsValue]) -> EvalResult {
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
func pr_gt(args: [ConsValue]) -> EvalResult {
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
func pr_lt(args: [ConsValue]) -> EvalResult {
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
func pr_plus(args: [ConsValue]) -> EvalResult {
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
func pr_minus(args: [ConsValue]) -> EvalResult {
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
func pr_multiply(args: [ConsValue]) -> EvalResult {
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
func pr_divide(args: [ConsValue]) -> EvalResult {
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
