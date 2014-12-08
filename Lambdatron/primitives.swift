//
//  primitives.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronBuiltIn = ([ConsValue], Context) -> EvalResult

enum BuiltIn : String, Printable {
  
  // Collection-related
  case List = ".list"
  case Vector = ".vector"
  case Hashmap = ".hash-map"
  case Cons = ".cons"
  case First = ".first"
  case Rest = ".rest"
  case Concat = ".concat"
  case Seq = ".seq"
  case Get = ".get"
  case Assoc = ".assoc"
  case Dissoc = ".dissoc"
  
  // I/O
  case Print = ".print"
  
  // Typechecking
  case IsNumber = ".number?"
  case IsInteger = ".int?"
  case IsFloat = ".float?"
  case IsString = ".string?"
  case IsSymbol = ".symbol?"
  case IsFn = ".fn?"
  case IsEvalable = ".eval?"
  case IsTrue = ".true?"
  case IsFalse = ".false?"
  case IsList = ".list?"
  case IsVector = ".vector?"
  case IsMap = ".map?"
  
  // Comparison
  case Equals = ".="
  case NumericEquals = ".=="
  case GreaterThan = ".>"
  case LessThan = ".<"
  
  // Arithmetic
  case Plus = ".+"
  case Minus = ".-"
  case Multiply = ".*"
  case Divide = "./"
  
  // TEMPORARY BOOTSTRAP
  case BootstrapPlus = ".B+"
  case BootstrapMinus = ".B-"
  case BootstrapMultiply = ".B*"
  case BootstrapDivide = ".B/"
  
  var function : LambdatronBuiltIn {
    switch self {
    case List: return pr_list
    case Vector: return pr_vector
    case Hashmap: return pr_hashmap
    case Cons: return pr_cons
    case First: return pr_first
    case Rest: return pr_rest
    case Concat: return pr_concat
    case Seq: return pr_seq
    case Get: return pr_get
    case Assoc: return pr_assoc
    case Dissoc: return pr_dissoc
    case Print: return pr_print
    case IsNumber: return pr_isNumber
    case IsInteger: return pr_isInteger
    case IsFloat: return pr_isFloat
    case IsString: return pr_isString
    case IsSymbol: return pr_isSymbol
    case IsFn: return pr_isFunction
    case IsEvalable: return pr_isEvalable
    case IsTrue: return pr_isTrue
    case IsFalse: return pr_isFalse
    case IsList: return pr_isList
    case IsVector: return pr_isVector
    case IsMap: return pr_isMap
    case Equals: return pr_equals
    case NumericEquals: return pr_numericEquals
    case GreaterThan: return pr_gt
    case LessThan: return pr_lt
    case Plus: return pr_plus
    case Minus: return pr_minus
    case Multiply: return pr_multiply
    case Divide: return pr_divide
      
    // TEMPORARY
    case BootstrapPlus: return bootstrap_plus
    case BootstrapMinus: return bootstrap_minus
    case BootstrapMultiply: return bootstrap_multiply
    case BootstrapDivide: return bootstrap_divide
    }
  }
  
  var description : String {
    return self.rawValue
  }
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

/// Given zero or more arguments, construct a list whose components are the arguments (or the empty list).
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

/// Given zero or more arguments, construct a vector whose components are the arguments (or the empty vector).
func pr_vector(args: [ConsValue], ctx: Context) -> EvalResult {
  return .Success(.VectorLiteral(args))
}

/// Given zero or more arguments, construct a map whose components are the keys and values (or the empty map).
func pr_hashmap(args: [ConsValue], ctx: Context) -> EvalResult {
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

/// Given a prefix and a list argument, return a new list where the prefix is followed by the list argument.
func pr_cons(args: [ConsValue], ctx: Context) -> EvalResult {
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
    // Create a new list consisting of the first object, followed by the second list (if not empty)
    return .Success(.ListLiteral(l.isEmpty ? Cons(first) : Cons(first, next: l)))
  case let .VectorLiteral(v):
    // Create a new list consisting of the first object, followed by a list comprised of the vector's items
    if v.count == 0 {
      return .Success(.ListLiteral(Cons(first)))
    }
    let head = Cons(first)
    var this = head
    for item in v {
      let next = Cons(item)
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
  case let .MapLiteral(m):
    // Create a new list consisting of the first object, followed by a list comprised of vectors containing the map's
    //  key-value pairs
    if m.count == 0 {
      return .Success(.ListLiteral(Cons(first)))
    }
    let head = Cons(first)
    var this = head
    for (key, value) in m {
      let next = Cons(.VectorLiteral([key, value]))
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Given a sequence, return the first item.
func pr_first(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  let first = args[0]
  switch first {
  case .NilLiteral:
    return .Success(.NilLiteral)
  case let .ListLiteral(l):
    return .Success(l.isEmpty ? .NilLiteral : l.value)
  case let .VectorLiteral(v):
    return .Success(v.count == 0 ? .NilLiteral : v[0])
  case let .MapLiteral(m):
    if m.count == 0 {
      return .Success(.NilLiteral)
    }
    for (key, value) in m {
      return .Success(.VectorLiteral([key, value]))
    }
    internalError("Cannot ever reach this point")
  default: return .Failure(.InvalidArgumentError)
  }
}

/// Given a sequence, return the sequence comprised of all items but the first.
func pr_rest(args: [ConsValue], ctx: Context) -> EvalResult {
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
  case let .VectorLiteral(v):
    if v.count < 2 {
      // Vector has zero or one items
      return .Success(.ListLiteral(Cons()))
    }
    let head = Cons(v[1])
    var this = head
    for var i=2; i<v.count; i++ {
      let next = Cons(v[i])
      this.next = next
      this = next
    }
    return .Success(.ListLiteral(head))
  case let .MapLiteral(m):
    if m.count < 2 {
      // Map has zero or one items
      return .Success(.ListLiteral(Cons()))
    }
    var head : Cons? = nil
    var this = head
    var skippedFirst = false
    for (key, value) in m {
      if !skippedFirst {
        skippedFirst = true
        continue
      }
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

/// Given a single sequence, return nil (if empty) or a list built out of that sequence.
func pr_seq(args: [ConsValue], ctx: Context) -> EvalResult {
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
func pr_concat(args: [ConsValue], ctx: Context) -> EvalResult {
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
func pr_get(args: [ConsValue], ctx: Context) -> EvalResult {
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
func pr_assoc(args: [ConsValue], ctx: Context) -> EvalResult {
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
func pr_dissoc(args: [ConsValue], ctx: Context) -> EvalResult {
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
func pr_isNumber(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .IntegerLiteral, .FloatLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isInteger(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .IntegerLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a floating point number.
func pr_isFloat(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .FloatLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a string literal.
func pr_isString(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .StringLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a symbol.
func pr_isSymbol(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .Symbol: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a user-defined function.
func pr_isFunction(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .FunctionLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is something that can be called in function position (e.g. special forms).
func pr_isEvalable(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  // User-defined functions, built-ins, and special forms are eval'able.
  // TODO: vectors and sets should also be eval'able, as they are in Clojure
  switch args[0] {
  case .FunctionLiteral, .MapLiteral, .Special, .BuiltInFunction: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is the boolean value 'true'.
func pr_isTrue(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is the boolean value 'false'.
func pr_isFalse(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case let .BoolLiteral(b): return .Success(.BoolLiteral(b == false))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a list.
func pr_isList(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .ListLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a vector.
func pr_isVector(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 1 {
    return .Failure(.ArityError)
  }
  switch args[0] {
  case .VectorLiteral: return .Success(.BoolLiteral(true))
  default: return .Success(.BoolLiteral(false))
  }
}

/// Return whether or not the argument is a map.
func pr_isMap(args: [ConsValue], ctx: Context) -> EvalResult {
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


// MARK: Math Helpers

/// An enum wrapping one of several numerical types, or an invalid value sigil.
internal enum NumericalType {
  case Integer(Int)
  case Float(Double)
  case Invalid
}

/// Convert a given ConsValue argument into the equivalent NumericalType token.
internal func extractNumber(n: ConsValue) -> NumericalType {
  switch n {
  case let .IntegerLiteral(v): return .Integer(v)
  case let .FloatLiteral(v): return .Float(v)
  default: return .Invalid
  }
}


// MARK: Comparison

/// Evaluate the equality of one or more forms.
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

/// Evaluate the equality of two numeric forms.
func pr_numericEquals(args: [ConsValue], ctx: Context) -> EvalResult {
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
func pr_gt(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 > v2))
    case let .Float(v2): return .Success(.BoolLiteral(Double(v1) > v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 > Double(v2)))
    case let .Float(v2): return .Success(.BoolLiteral(v1 > v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Evaluate whether arguments are in monotonically increasing order.
func pr_lt(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 < v2))
    case let .Float(v2): return .Success(.BoolLiteral(Double(v1) < v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2): return .Success(.BoolLiteral(v1 < Double(v2)))
    case let .Float(v2): return .Success(.BoolLiteral(v1 < v2))
    case .Invalid: return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}


// MARK: Arithmetic

/// Take two numbers and return their sum.
func pr_plus(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.IntegerLiteral(v1 + v2))
    case let .Float(v2):
      return .Success(.FloatLiteral(Double(v1) + v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatLiteral(v1 + Double(v2)))
    case let .Float(v2):
      return .Success(.FloatLiteral(v1 + v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take two numbers and return their difference.
func pr_minus(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.IntegerLiteral(v1 - v2))
    case let .Float(v2):
      return .Success(.FloatLiteral(Double(v1) - v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatLiteral(v1 - Double(v2)))
    case let .Float(v2):
      return .Success(.FloatLiteral(v1 - v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take two numbers and return their product.
func pr_multiply(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.IntegerLiteral(v1 * v2))
    case let .Float(v2):
      return .Success(.FloatLiteral(Double(v1) * v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      return .Success(.FloatLiteral(v1 * Double(v2)))
    case let .Float(v2):
      return .Success(.FloatLiteral(v1 * v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}

/// Take one or more numbers and return their quotient. If only one number, returns 1/arg[0].
func pr_divide(args: [ConsValue], ctx: Context) -> EvalResult {
  if args.count != 2 {
    return .Failure(.ArityError)
  }
  let num0 = extractNumber(args[0])
  let num1 = extractNumber(args[1])
  
  switch num0 {
  case let .Integer(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(Double(v1) / Double(v2)))
    case let .Float(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(Double(v1) / v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case let .Float(v1):
    switch num1 {
    case let .Integer(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(v1 / Double(v2)))
    case let .Float(v2):
      if v2 == 0 { return .Failure(.DivideByZeroError) }
      return .Success(.FloatLiteral(v1 / v2))
    case .Invalid:
      return .Failure(.InvalidArgumentError)
    }
  case .Invalid:
    return .Failure(.InvalidArgumentError)
  }
}
