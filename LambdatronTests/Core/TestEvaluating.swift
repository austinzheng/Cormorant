//
//  TestEvaluating.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/19/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the way that function arguments are evaluated.
class TestFuncArgEvaluation : InterpreterTest {

  override func setUp() {
    super.setUp()
    clearOutputBuffer()
    interpreter.writeOutput = writeToBuffer
  }

  override func tearDown() {
    // Reset the interpreter
    clearOutputBuffer()
    interpreter.writeOutput = print
  }

  /// A function's arguments should be evaluated in order, from left to right.
  func testEvaluationOrder() {
    // Define a function that takes 4 args and does nothing
    runCode("(def testFunc (fn [a b c d] nil))")
    expectThat("(testFunc (.print \"arg1\") (.print \"arg2\") (.print \"arg3\") (.print \"arg4\"))",
      shouldEvalTo: .NilLiteral)
    expectOutputBuffer(toBe: "arg1arg2arg3arg4")
  }
}