//
//  InterpreterTest.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/16/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

/// Convenience function: given a bunch of ConsValues, return a list.
func listWithItems(items: ConsValue...) -> ConsValue {
  if items.count == 0 {
    return .ListLiteral(Cons())
  }
  var head = Cons(items[items.count - 1])
  for var i=items.count - 2; i >= 0; i-- {
    let this = Cons(items[i], next: head)
    head = this
  }
  return .ListLiteral(head)
}

/// Convenience functions: given a bunch of ConsValues, return a vector.
func vectorWithItems(items: ConsValue...) -> ConsValue {
  return .VectorLiteral(items)
}

/// Convenience function: given a bunch of ConsValue key-value pairs, return a map.
func mapWithItems(items: (ConsValue, ConsValue)...) -> ConsValue {
  if items.count == 0 {
    return .MapLiteral([:])
  }
  var buffer : Map = [:]
  for (key, value) in items {
    buffer[key] = value
  }
  return .MapLiteral(buffer)
}

/// An abstract superclass intended for various interpreter tests.
class InterpreterTest : XCTestCase {
  var interpreter = Interpreter()

  override func setUp() {
    super.setUp()
    interpreter.reset()
  }

  // Run some input, expecting no errors.
  func runCode(input: String) -> ConsValue? {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(s):
      return s
    default:
      XCTFail("runCode did not successfully evaluate the input code")
      return nil
    }
  }

  /// Given an input string, evaluate it and compare the output to an expected ConsValue output.
  func expectThat(input: String, shouldEvalTo expected: ConsValue) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(actual):
      XCTAssert(expected == actual, "expected: \(expected), got: \(actual)")
    case .LexFailure:
      XCTFail("lexer error")
    case .ParseFailure:
      XCTFail("parser error")
    case .ReaderFailure:
      XCTFail("reader error")
    case let .EvalFailure(f):
      XCTFail("evaluation error: \(f.description)")
    }
  }

  /// Given an input string, evaluate it and expect a particular evaluation failure.
  func expectThat(input: String, shouldFailAs expected: EvalError.ErrorType) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(s):
      XCTFail("evaluation unexpectedly succeeded; result: \(s.description)")
    case .LexFailure:
      XCTFail("lexer error")
    case .ParseFailure:
      XCTFail("parser error")
    case .ReaderFailure:
      XCTFail("reader error")
    case let .EvalFailure(actual):
      let expectedName = expected.rawValue
      let actualName = actual.error.rawValue
      XCTAssert(expected == actual.error, "expected: \(expectedName), got: \(actualName)")
    }
  }

  /// Given an input string, evaluate it and expect an arity error.
  func expectArityErrorFrom(input: String) {
    expectThat(input, shouldFailAs: .ArityError)
  }

  // Buffer functionality
  /// A buffer capturing output from the interpreter.
  var outputBuffer : String = ""

  /// Clear the output buffer.
  func clearOutputBuffer() {
    outputBuffer = ""
  }

  /// Write to the output buffer. Intended to be passed to the interpreter for use in testing println and side effects.
  func writeToBuffer(item: String) {
    outputBuffer += item
  }

  /// Compare an input string to the contents of the output buffer.
  func expectOutputBuffer(toBe expected: String) {
    XCTAssert(outputBuffer == expected, "expected: \(expected), got: \(outputBuffer)")
  }
}
