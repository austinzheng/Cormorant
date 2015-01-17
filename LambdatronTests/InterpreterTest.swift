//
//  InterpreterTest.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/16/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

/// An abstract superclass intended for various interpreter tests.
class InterpreterTest : XCTestCase {
  var interpreter = Interpreter()

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
  func expectThat(input: String, shouldFailAs expected: EvalError) {
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
      XCTAssert(expected == actual, "expected: \(expected.description), got: \(actual.description)")
    }
  }

  /// Given an input string, evaluate it and expect an arity error.
  func expectArityErrorFrom(input: String) {
    expectThat(input, shouldFailAs: .ArityError)
  }
}
