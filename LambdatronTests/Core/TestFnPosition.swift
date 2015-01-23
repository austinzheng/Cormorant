//
//  TestFnPosition.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/16/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the use of functions and special forms in function position.
class TestFnPositionFnsSpecialForms : InterpreterTest {

  /// A function literal without arguments should be recognized as a function in function position.
  func testFunctionLiteral() {
    expectThat("((fn [] \"foobar\"))", shouldEvalTo: .StringLiteral("foobar"))
  }

  /// A function literal with arguments should be recognized as a function in function position.
  func testFunctionLiteralWithArgs() {
    expectThat("((fn [a b c] (.+ (.* a b) c)) 15 8 -4)", shouldEvalTo: .IntegerLiteral(116))
  }

  /// A function bound to a symbol should evaluate properly.
  func testFunctionLiteralSymbol() {
    runCode("(def testFunc (fn [a b c] (.+ a (.+ b c))))")
    expectThat("(testFunc 1 15 1000)", shouldEvalTo: .IntegerLiteral(1016))
  }

  /// A built-in in function should evaluate properly.
  func testBuiltInFunction() {
    expectThat("(.+ 15 89)", shouldEvalTo: .IntegerLiteral(104))
  }

  /// A built-in function bound to a symbol should evaluate properly.
  func testBuiltInFunctionSymbol() {
    runCode("(def testPlus .+)")
    expectThat("(testPlus 15 89)", shouldEvalTo: .IntegerLiteral(104))
  }

  /// A special form should evaluate properly.
  func testSpecialForm() {
    expectThat("(if true 9001 1009)", shouldEvalTo: .IntegerLiteral(9001))
  }
}

/// Test the use of vectors in function position.
class TestFnPositionVectors : InterpreterTest {

  /// A vector in function position with a valid index should extract the proper value from the vector.
  func testValidIndex() {
    expectThat("([100 200 300 400.0] 3)", shouldEvalTo: .FloatLiteral(400.0))
  }

  /// A vector in function position with a negative index should produce an error.
  func testNegativeIndex() {
    expectThat("([100 200 300 400.0] -1)", shouldFailAs: .OutOfBoundsError)
  }

  /// A vector in function position with an out-of-bounds positive index should produce an error.
  func testTooLargeIndex() {
    expectThat("([100 200 300 400.0] 100)", shouldFailAs: .OutOfBoundsError)
  }

  /// A vector in function position with more than one argument should produce an error.
  func testWithFallback() {
    expectArityErrorFrom("([100 200 300 400.0] 0 nil)")
  }

  /// A vector in function position with no arguments should produce an error.
  func testWithTooFewArgs() {
    expectArityErrorFrom("([100 200 300 400.0])")
  }

  /// A vector bound to a symbol should evaluate properly.
  func testWithSymbol() {
    runCode("(def testVec [1 4 9 16 25])")
    expectThat("(testVec 2)", shouldEvalTo: .IntegerLiteral(9))
  }

  // TODO: test for side effects.
}

/// Test the use of maps in function position.
class TestFnPositionMaps : InterpreterTest {
  // TODO
}

/// Test the use of symbols in function position.
class TestFnPositionSymbols : InterpreterTest {
  // TODO
}

/// Test the use of keywords in function position.
class TestFnPositionKeywords : InterpreterTest {
  // TODO
}

/// Test the use of invalid types in function position.
class TestFnPositionInvalidTypes : InterpreterTest {

  /// nil should cause an error if used in function position.
  func testNilInFnPosition() {
    expectThat("(nil)", shouldFailAs: .NotEvalableError)
  }

  /// Bools should cause an error if used in function position.
  func testBoolInFnPosition() {
    expectThat("(true)", shouldFailAs: .NotEvalableError)
    expectThat("(false)", shouldFailAs: .NotEvalableError)
  }

  /// Characters should cause an error if used in function position.
  func testCharacterInFnPosition() {
    expectThat("(\\a 0)", shouldFailAs: .NotEvalableError)
  }

  /// Strings should cause an error if used in function position.
  func testStringInFnPosition() {
    expectThat("(\"the quick brown fox\" 0)", shouldFailAs: .NotEvalableError)
  }

  /// Lists should cause an error if used in function position.
  func testListInFnPosition() {
    expectThat("('(100 200 300 400.0) 0)", shouldFailAs: .NotEvalableError)
  }

  /// Integers should cause an error if used in function position.
  func testIntInFnPosition() {
    expectThat("(1009)", shouldFailAs: .NotEvalableError)
  }

  /// Floating-point numbers should cause an error if used in function position.
  func testFloatInFnPosition() {
    expectThat("(100.0009)", shouldFailAs: .NotEvalableError)
  }
}
