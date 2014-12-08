//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = ([ConsValue], Context, EvalEnvironment) -> EvalResult

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
  case let .MapLiteral(m):
    for (key, value) in m {
      let next = Cons(.VectorLiteral([key, value]))
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

/// Given zero or more arguments, construct a map whose components are the keys and values (or the empty map).
func pr_hashmap(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count % 2 != 0 {
    // Must have an even number of arguments
    return .Failure(.InvalidArgumentError)
  }
  var buffer : Map = [:]
  for var i=0; i<args.count-1; i += 2 {
    let key = args[i]
    let value = args[i+1]
    buffer[key] = value
  }
  return .Success(.MapLiteral(buffer))
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
    return .Success(.ListLiteral(head))
  case let .MapLiteral(m):
    if m.count == 0 {
      return .Success(.NilLiteral)
    }
    var head : Cons? = nil
    var this = head
    for (key, value) in m {
      let next = Cons(.VectorLiteral([key, value]))
      if let this = this {
        this.next = next
      }
      else {
        head = next
      }
      this = next
    }
    return .Success(.ListLiteral(head!))
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
    case let .MapLiteral(m):
      for (key, value) in m {
        if !headInitialized {
          this.value = .VectorLiteral([key, value])
          headInitialized = true
        }
        else {
          let next = Cons(.VectorLiteral([key, value]))
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

/// Given a collection and a key, get the corresponding value, or return nil or an optional 'not found' value
func pr_get(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count < 2 || args.count > 3 {
    return .Failure(.ArityError)
  }
  let key = args[1]
  let fallback : ConsValue = args.count == 3 ? args[2] : .NilLiteral

  switch args[0] {
  case let .StringLiteral(s):
    fatal("Not yet implemented")
  case let .VectorLiteral(v):
    fatal("Not yet implemented")
  case let .MapLiteral(m):
    return .Success(m[key] ?? fallback)
  default:
    return .Success(fallback)
  }
}

/// Given a supported collection and one or more key-value pairs, associate the new values with the keys.
func pr_assoc(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  func updateMapFromArray(raw: [ConsValue], inout starting: Map) {
    for var i=0; i<raw.count - 1; i += 2 {
      let key = raw[i]
      let value = raw[i+1]
      starting[key] = value
    }
  }
  // This function requires at least one collection/nil and one key/index-value pair
  if args.count < 3 {
    return .Failure(.ArityError)
  }
  // Collect all arguments after the first one
  let rest = Array(args[1..<args.count])
  if rest.count % 2 != 0 {
    // Must have an even number of key/index-value pairs
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .NilLiteral:
    // Put key-value pairs in a new map
    var newMap : Map = [:]
    updateMapFromArray(rest, &newMap)
    return .Success(.MapLiteral(newMap))
  case let .StringLiteral(s):
    // TODO: Implement string and vector support. This will require support for integers.
    fatal("Implement me!")
  case let .VectorLiteral(v):
    fatal("Implement me!")
  case let .MapLiteral(m):
    var newMap = m
    updateMapFromArray(rest, &newMap)
    return .Success(.MapLiteral(newMap))
  default:
    return .Failure(.InvalidArgumentError)
  }
}

/// Given a map and zero or more keys, return a map with the given keys and corresponding values removed.
func pr_dissoc(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count < 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .NilLiteral:
    return .Success(.NilLiteral)
  case let .MapLiteral(m):
    var newMap = m
    for var i=1; i<args.count; i++ {
      newMap.removeValueForKey(args[i])
    }
    return .Success(.MapLiteral(newMap))
  default:
    return .Failure(.InvalidArgumentError)
  }
}


// MARK: Typechecking

/// Return whether or not the argument is a number of some sort.
func pr_isNumber(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .IntegerLiteral, .FloatLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isInteger(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .IntegerLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isFloat(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .FloatLiteral: return .Success(.BoolLiteral(true))
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
  // TODO: vectors and sets should also be eval'able, as they are in Clojure
  switch args[0] {
  case .FunctionLiteral, .MapLiteral, .Special: return .Success(.BoolLiteral(true))
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

/// Return whether or not the argument is a map.
func pr_isMap(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .MapLiteral: return .Success(.BoolLiteral(true))
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


// MARK: Math Helpers

/// An enum wrapping one of several numerical types, or an invalid value sigil.
private enum NumericalType {
  case Integer(Int)
  case Float(Double)
  case Invalid
}

/// An enum describing the numerical mode of an operation.
private enum NumericalMode {
  case Integer, Float
}

/// Convert a given ConsValue argument into the equivalent NumericalType token.
private func extractNumber(n: ConsValue) -> NumericalType {
  switch n {
  case let .IntegerLiteral(v): return .Integer(v)
  case let .FloatLiteral(v): return .Float(v)
  default: return .Invalid
  }
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

/// Evaluate the equality of two numeric forms.
func pr_numericEquals(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let first = extractNumber(args[0])
  let second = extractNumber(args[1])
  switch first {
  case let .Integer(v1):
    switch second {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 == v2))
    case let .Float(v2): return .Success(.BoolLiteral(Double(v1) == v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch second {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 == Double(v2)))
    case let .Float(v2): return .Success(.BoolLiteral(v1 == v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case .Invalid: return .Failure(.InvalidArgumentError)
  }
}

/// Evaluate whether arguments are in monotonically decreasing order.
func pr_gt(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  
  // Set up the initial state
  var (intAccum, floatAccum, mode, didError) = stateForFirstArgument(args[0])
  if didError {
    return .Failure(.InvalidArgumentError)
  }
  
  for var i=1; i<args.count; i++ {
    let arg = args[i]
    switch extractNumber(arg) {
    case let .Integer(v):
      switch mode {
      case .Integer:
        if v >= intAccum {
          return .Success(.BoolLiteral(false))
        }
        intAccum = v
      case .Float:
        if Double(v) >= floatAccum {
          return .Success(.BoolLiteral(false))
        }
        floatAccum = Double(v)
      }
    case let .Float(v):
      switch mode {
      case .Integer:
        mode = .Float
        floatAccum = Double(intAccum)
        if Double(v) >= floatAccum {
          return .Success(.BoolLiteral(false))
        }
      case .Float:
        if v >= floatAccum {
          return .Success(.BoolLiteral(false))
        }
      }
      floatAccum = Double(v)
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  }
  return .Success(.BoolLiteral(true))
}

/// Evaluate whether arguments are in monotonically increasing order.
func pr_lt(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  
  // Set up the initial state
  var (intAccum, floatAccum, mode, didError) = stateForFirstArgument(args[0])
  if didError {
    return .Failure(.InvalidArgumentError)
  }
  
  for var i=1; i<args.count; i++ {
    let arg = args[i]
    switch extractNumber(arg) {
    case let .Integer(v):
      switch mode {
      case .Integer:
        if v <= intAccum {
          return .Success(.BoolLiteral(false))
        }
        intAccum = v
      case .Float:
        if Double(v) <= floatAccum {
          return .Success(.BoolLiteral(false))
        }
        floatAccum = Double(v)
      }
    case let .Float(v):
      switch mode {
      case .Integer:
        mode = .Float
        floatAccum = Double(intAccum)
        if Double(v) <= floatAccum {
          return .Success(.BoolLiteral(false))
        }
      case .Float:
        if v <= floatAccum {
          return .Success(.BoolLiteral(false))
        }
      }
      floatAccum = Double(v)
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  }
  return .Success(.BoolLiteral(true))
}


// MARK: Arithmetic

/// Take an arbitrary number of numbers and return their sum.
func pr_plus(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
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

/// Take one or more numbers and return their difference. If only one number, returns 1-arg[0].
func pr_minus(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  
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
func pr_multiply(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  var mode : NumericalMode = .Integer
  var intAccum : Int = 1
  var floatAccum : Double = 1.0
  
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
func pr_divide(args: [ConsValue], ctx: Context, env: EvalEnvironment) -> EvalResult {
  if args.count == 0 {
    return .Failure(.ArityError)
  }
  
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
