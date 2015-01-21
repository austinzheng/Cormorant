//
//  TestDo.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/20/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'do' special form.
class TestDo : InterpreterTest {

  override func setUp() {
    clearOutputBuffer()
    interpreter.writeOutput = writeToBuffer
  }

  override func tearDown() {
    // Reset the interpreter
    clearOutputBuffer()
    interpreter.writeOutput = print
  }

  /// do with no forms should just return nil
  func testEmptyDo() {
    expectThat("(do)", shouldEvalTo: .NilLiteral)
  }

  /// do with a single form should just return the result of that form.
  func testDoWithSingleForm() {
    expectThat("(do (.+ 1 2))", shouldEvalTo: .IntegerLiteral(3))
  }

  /// do with multiple forms should execute all forms in order, and return the result of the last form.
  func testDoWithMultipleForms() {
    expectThat("(do (.print \"form1\") (.print \"form2\") (.print \"form3\") (.print \"form4\") \"result\")",
      shouldEvalTo: .StringLiteral("result"))
    expectOutputBuffer(toBe: "form1form2form3form4")
  }

  /// do with multiple forms should execute all forms in order, but discard return values of all but the last form.
  func testDoWithMultipleForms2() {
    expectThat("(do 1 2 3 (.+ 4 5) 6 7 nil true)", shouldEvalTo: .BoolLiteral(true))
  }
}
