//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = ([ConsValue], Context, EvalEnvironment) -> EvalResult

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

// MARK: General

/// Given a function, zero or more leading arguments, and a sequence of args, apply the function with the arguments.
func pr_apply(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count < 2 {
    return .Failure(.ArityError)
  }
  // First argument must be a function, built-in, or special form
  switch args[0] {
  case .FunctionLiteral, .Special: break
  case let .Symbol(s):
    switch ctx[s] {
    case .BuiltIn: break
    default: return .Failure(.InvalidArgumentError)
    }
  default: return .Failure(.InvalidArgumentError)
  }
  let last = args.last!
  switch last {
  case .ListLiteral, .VectorLiteral:
    break
  default:
    // Last argument must be a collection
    return .Failure(.InvalidArgumentError)
  }
  
  // Straightforward implementation: build a list and then eval it
  let head = Cons(args[0])
  var this = head
  
  for var i=1; i<args.count - 1; i++ {
    // Add all leading args to the list directly
    let next = Cons(args[i])
    this.next = next
    this = next
  }
  switch last {
  case let .ListLiteral(l) where !l.isEmpty:
    this.next = l
  case let .VectorLiteral(v):
    for item in v {
      let next = Cons(item)
      this.next = next
      this = next
    }
  default:
    break
  }
  
  let result = head.evaluate(ctx, env)
  return .Success(result)
}


// MARK: Collections

/// Given zero or more arguments, construct a list whose components are the arguments (or the empty list).
func pr_list(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Given zero or more arguments, construct a vector whose components are the arguments (or the empty vector).
func pr_vector(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  return .Success(.VectorLiteral(args))
}

/// Given a single sequence, return nil (if empty) or a list built out of that sequence.
func pr_seq(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .NilLiteral: return .Success(args[0])
  case let .ListLiteral(l):
    return .Success(l.isEmpty ? .NilLiteral : .ListLiteral(l))
  case let .VectorLiteral(v):
    // Turn the vector into a list
    if v.count == 0 {
      return .Success(.NilLiteral)
    }
    let head = Cons(v[0])
    var this = head
    for var i=1; i<v.count; i++ {
      var next = Cons(v[i])
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(this))
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Given zero or more arguments which are collections or nil, return a list created by concatenating the arguments.
func pr_concat(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Success(.ListLiteral(Cons()))
  }
  // TODO: Support strings (which should concat into characters)
  var headInitialized = false
  var head = Cons()
  var this = head
  for arg in args {
    switch arg {
    case .NilLiteral: continue
    case let .ListLiteral(l):
      if !l.isEmpty {
        var listHead : Cons? = l
        while let actualHead = listHead {
          if !headInitialized {
            this.value = actualHead.value
            headInitialized = true
          }
          else {
            let next = Cons(actualHead.value)
            this.next = next
            this = next
          }
          listHead = actualHead.next
        }
      }
    case let .VectorLiteral(v):
      for item in v {
        if !headInitialized {
          this.value = item
          headInitialized = true
        }
        else {
          let next = Cons(item)
          this.next = next
          this = next
        }
      }
    default:
      return .Failure(.InvalidArgumentError)
    }
  }
  return .Success(.ListLiteral(head))
}


// MARK: Typechecking

/// Return whether or not the argument is a number of some sort.
func pr_isNumber(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .NumberLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a string literal.
func pr_isString(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .StringLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a symbol.
func pr_isSymbol(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .Symbol: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a user-defined function.
func pr_isFunction(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .FunctionLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is something that can be called in function position (e.g. special forms).
func pr_isEvalable(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Return whether or not the argument is the boolean value 'true'.
func pr_isTrue(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is the boolean value 'false'.
func pr_isFalse(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == false))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a list.
func pr_isList(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .ListLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a vector.
func pr_isVector(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .VectorLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}


// MARK: I/O

/// Print zero or more args to screen. Returns nil.
func pr_print(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Evaluate the equality of one or more forms.
func pr_equals(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Evaluate whether arguments are in monotonically decreasing order.
func pr_gt(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Evaluate whether arguments are in monotonically increasing order.
func pr_lt(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Take an arbitrary number of numbers and return their sum.
func pr_plus(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  let maybeNumbers = extractNumbers(args)
  if let numbers = maybeNumbers {
    return .Success(.NumberLiteral(numbers.reduce(0, combine: +)))
  }
  return .Failure(.InvalidArgumentError)
}

/// Take an arbitrary number of numbers and return their difference.
func pr_minus(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Take an arbitrary number of numbers  and return their product.
func pr_multiply(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Failure(EvalError.ArityError)
  }
  let maybeNumbers = extractNumbers(args)
  if let numbers = maybeNumbers {
    return .Success(.NumberLiteral(numbers.reduce(1, combine: *)))
  }
  return .Failure(.InvalidArgumentError)
}

/// Take two numbers and return their quotient.
func pr_divide(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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
