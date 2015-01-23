//
//  TestEvaluating.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/19/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the way functions are evaluated.
class TestFunctionEvaluation : InterpreterTest {

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

  /// A function should properly return the value of the last form in its body.
  func testFunctionReturnValue() {
    runCode("(def testFunc (fn [] (.+ 1 2)))")
    expectThat("(testFunc)", shouldEvalTo: .IntegerLiteral(3))
  }

  /// A function should run its body forms in order and return the value of the last one.
  func testFunctionBodyEvaluation() {
    runCode("(def testFunc (fn [] (.print \"first\") (.print \"second\") (.print \"third\") 1.2345))")
    expectThat("(testFunc)", shouldEvalTo: .FloatLiteral(1.2345))
    expectOutputBuffer(toBe: "firstsecondthird")
  }

  /// A function's output should not be further evaluated.
  func testFunctionOutputEvaluation() {
    runCode("(def testFunc (fn [] (.list .+ 500 200)))")
    expectThat("(testFunc)",
      shouldEvalTo: .ListLiteral(Cons(.BuiltInFunction(.Plus),
        next: Cons(.IntegerLiteral(500), next: Cons(.IntegerLiteral(200))))))
  }

  /// A function's arguments should be evaluated by the time the function sees them.
  func testParamEvaluation() {
    // Define a function
    runCode("(def testFunc (fn [a b] (.print a) (.print \", \") (.print b) true))")
    expectThat("(testFunc (.+ 1 2) (.+ 3 4))", shouldEvalTo: .BoolLiteral(true))
    expectOutputBuffer(toBe: "3, 7")
  }

  /// A function's arguments should be evaluated in order, from left to right.
  func testParamEvaluationOrder() {
    // Define a function that takes 4 args and does nothing
    runCode("(def testFunc (fn [a b c d] nil))")
    expectThat("(testFunc (.print \"arg1\") (.print \"arg2\") (.print \"arg3\") (.print \"arg4\"))",
      shouldEvalTo: .NilLiteral)
    expectOutputBuffer(toBe: "arg1arg2arg3arg4")
  }
}

/// Test the way macros are evaluated.
class TestMacroEvaluation : InterpreterTest {

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

  /// A macro should properly return the value of the last form in its body for evaluation.
  func testMacroReturnValue() {
    runCode("(defmacro testMacro [] 3)")
    expectThat("(testMacro)", shouldEvalTo: .IntegerLiteral(3))
  }

  /// A macro should run its body forms in order and return the value of the last one.
  func testMacroBodyEvaluation() {
    runCode("(defmacro testMacro [] (.print \"first\") (.print \"second\") (.print \"third\") 1.2345)")
    expectThat("(testMacro)", shouldEvalTo: .FloatLiteral(1.2345))
    expectOutputBuffer(toBe: "firstsecondthird")
  }

  /// A macro's output form should be automatically evaluated to produce a value.
  func testMacroOutputEvaluation() {
    runCode("(defmacro testMacro [] (.list .+ 500 200))")
    expectThat("(testMacro)", shouldEvalTo: .IntegerLiteral(700))
  }

  /// A macro's output form should be evaluated with regards to both argument and external bindings.
  func testMacroOutputWithArgs() {
    runCode("(def a 11)")
    runCode("(defmacro testMacro [b] (.list .+ a b))")
    expectThat("(testMacro 12)", shouldEvalTo: .IntegerLiteral(23))
  }

  /// A macro's parameters should be passed to the macro without being evaluated or otherwise touched.
  func testMacroParameters() {
    // Define a macro that takes 2 parameters
    runCode("(defmacro testMacro [a b] (.print a) (.print b) nil)")
    expectThat("(testMacro (+ 1 2) [(+ 3 4) 5])", shouldEvalTo: .NilLiteral)
    expectOutputBuffer(toBe: "(+ 1 2)[(+ 3 4) 5]")
  }

  /// A macro should not evaluate its parameters if not explicitly asked to do so.
  func testMacroUntouchedParam() {
    // Note that only either 'then' or 'else' can ever be evaluated.
    runCode("(defmacro testMacro [pred then else] (if pred then else))")
    expectThat("(testMacro true (do (.print \"good\") 123) (.print \"bad\"))", shouldEvalTo: .IntegerLiteral(123))
    expectOutputBuffer(toBe: "good")
  }
}