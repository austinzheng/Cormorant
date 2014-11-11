//
//  builtin.swift
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
func cons(args: [ConsValue]) -> EvalResult {
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
func first(args: [ConsValue]) -> EvalResult {
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
func rest(args: [ConsValue]) -> EvalResult {
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


// MARK: Arithmetic

/// Take an arbitrary number of numbers and return their sum
func plus(args: [ConsValue]) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  let numbers = args.map(extractNumber)
  var acc : Double = 0
  for possibleNumber in numbers {
    if let number = possibleNumber {
      acc += number
    }
    else {
      return .Failure(.InvalidArgumentError)
    }
  }
  return .Success(.NumberLiteral(acc))
}

/// Take an arbitrary number of numbers and return their difference
func minus(args: [ConsValue]) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  var acc : Double = 0
  let numbers = args.map(extractNumber)
  for (idx, possibleNumber) in enumerate(numbers) {
    if let number = possibleNumber {
      if idx == 0 {
        acc = number
      }
      else {
        acc -= number
      }
    }
    else {
      return .Failure(.InvalidArgumentError)
    }
  }
  return .Success(.NumberLiteral(acc))
}

/// Take an arbitrary number of numbers  and return their product
func multiply(args: [ConsValue]) -> EvalResult {
  if args.count == 0 {
    return .Failure(EvalError.ArityError)
  }
  let numbers = args.map(extractNumber)
  var acc : Double = 1
  for possibleNumber in numbers {
    if let number = possibleNumber {
      acc *= number
    }
    else {
      return .Failure(EvalError.InvalidArgumentError)
    }
  }
  return .Success(.NumberLiteral(acc))
}

/// Take two numbers and return their quotient
func divide(args: [ConsValue]) -> EvalResult {
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
