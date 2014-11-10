//
//  builtin.swift
//  Lambdatron
//
//  Created by Austin Zheng on 10/21/14.
//  Copyright (c) 2014 Austin Zheng. All rights reserved.
//

import Foundation

typealias LambdatronFunction = [ConsValue] -> ConsValue

func extractNumber(n: ConsValue) -> Double {
  let x : Double = {
    switch n {
    case let .Variable(a):
      // Get the current context, and try to resolve the variale into a literal
      let context = TEMPORARY_globalContext
      switch(context[a]) {
      case .Invalid:
        fatal("Undefined variable named '\(a)'")
      case let .Literal(literalValue):
        return extractNumber(.Literal(literalValue))
      case .Function(_):
        fatal("Variable named '\(a)' is a function, not a numerical operand")
      }
    case let .Literal(literalValue):
      switch literalValue {
      case .NilLiteral:
        fatal("Function expecting numerical operand, got a nil operand instead")
      case .BoolLiteral(_):
        fatal("Function expecting numerical operand, got a boolean operand instead")
      case let .NumberLiteral(n):
        return n
      case .StringLiteral(_):
        fatal("Function expecting numerical operand, got a string operand instead")
      case let .List(c):
        // Evaluate and then try again
        return extractNumber(ConsValue.Literal(c.evaluate()))
      case .Vector(_):
        fatal("Function expecting numerical operand, got a vector instead")
      }
    case .None:
      fatal("Internal error")
    }
    }()
  return x
}


//// MATHEMATICS

// Take an arbitrary number of numbers and return their sum
func plus(args: [ConsValue]) -> ConsValue {
  if args.count == 0 {
    fatal("+ requires at least one argument")
  }
  let numbers = args.map(extractNumber)
  let result = numbers.reduce(0, combine: +)
  return ConsValue.Literal(LiteralValue.NumberLiteral(result))
}

// Take an arbitrary number of numbers and return their difference
func minus(args: [ConsValue]) -> ConsValue {
  if args.count == 0 {
    fatal("- requires at least one argument")
  }
  let numbers = args.map(extractNumber)
  var acc : Double = numbers.first!
  for var i = 1; i<numbers.count; i++ {
    acc -= numbers[i]
  }
  return ConsValue.Literal(LiteralValue.NumberLiteral(acc))
}

// Take an arbitrary number of numbers  and return their product
func multiply(args: [ConsValue]) -> ConsValue {
  if args.count == 0 {
    fatal("* requires at least one argument")
  }
  let numbers = args.map(extractNumber)
  let result = numbers.reduce(1, combine: *)
  return ConsValue.Literal(LiteralValue.NumberLiteral(result))
}

// Take two numbers and return their quotient
func divide(args: [ConsValue]) -> ConsValue {
  if args.count != 2 {
    fatal("/ requires two arguments")
  }
  let (x, y) = (extractNumber(args[0]), extractNumber(args[1]))
  if y == 0 {
    fatal("Divisor cannot be 0; divide by zero error")
  }
  return ConsValue.Literal(LiteralValue.NumberLiteral(x / y))
}

//// UTILITY

// TODO
