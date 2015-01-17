//
//  TestFnPosition.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/16/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the use of function literals in function position.
class TestFnPositionFunctions : InterpreterTest {

}

/// Test the use of built-ins in function position.
class TestFnPositionBuiltIns : InterpreterTest {

}

/// Test the use of special forms in function position.
class TestFnPositionSpecialForms : InterpreterTest {

}

/// Test the use of vectors in function position.
class TestFnPositionVectors : InterpreterTest {
  func testValidIndex() {
    expectThat("([100 200 300 400.0] 3)", shouldEvalTo: .FloatLiteral(400.0))
  }

  func testNegativeIndex() {
    expectThat("([100 200 300 400.0] -1)", shouldFailAs: .OutOfBoundsError)
  }

  func testTooLargeIndex() {
    expectThat("([100 200 300 400.0] 100)", shouldFailAs: .OutOfBoundsError)
  }

  func testWithFallback() {
    expectArityErrorFrom("([100 200 300 400.0] 0 nil)")
  }

  func testWithTooFewArgs() {
    expectArityErrorFrom("([100 200 300 400.0])")
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
  // TODO: other invalid types?

  func testCharacterInFnPosition() {
    expectThat("(\\a 0)", shouldFailAs: .NotEvalableError)
  }

  func testStringInFnPosition() {
    expectThat("(\"the quick brown fox\" 0)", shouldFailAs: .NotEvalableError)
  }

  func testListInFnPosition() {
    expectThat("('(100 200 300 400.0) 0)", shouldFailAs: .NotEvalableError)
  }
}
