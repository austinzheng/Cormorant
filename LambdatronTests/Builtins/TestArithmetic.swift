//
//  TestArithmetic.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/28/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestPlus : InterpreterTest {

  /// Addition with integers should work.
  func testInts() {
    expectThat("(.+ 2 3)", shouldEvalTo: .IntegerLiteral(5))
    expectThat("(.+ 17882 -929)", shouldEvalTo: .IntegerLiteral(16953))
  }

  /// Addition with floats should work.
  func testFloats() {
    expectThat("(.+ 0.1 0.2)", shouldEvalTo: .FloatLiteral(0.1 + 0.2))
    expectThat("(.+ 2.19591 999123.5990712)", shouldEvalTo: .FloatLiteral(2.19591 + 999123.5990712))
  }

  /// Addition with mixed types should work.
  func testMixed() {
    expectThat("(.+ 1 2.3)", shouldEvalTo: .FloatLiteral(3.3))
    expectThat("(.+ 2.3 1)", shouldEvalTo: .FloatLiteral(3.3))
  }

  /// Integer addition should trap overflow.
  func testOverflow() {
    expectThat("(.+ 9223372036854775807 1)", shouldFailAs: .IntegerOverflowError)
    expectThat("(.+ -9223372036854775808 -1)", shouldFailAs: .IntegerOverflowError)
  }

  /// Built-in addition function should only take two arguments.
  func testArity() {
    expectArityErrorFrom("(.+ 1)")
    expectArityErrorFrom("(.+ 1 1 1)")
  }
}

class TestMinus : InterpreterTest {
  // TODO

  /// Built-in subtraction function should only take two arguments.
  func testArity() {
    expectArityErrorFrom("(.- 1)")
    expectArityErrorFrom("(.- 1 1 1)")
  }
}

class TestMultiply : InterpreterTest {
  // TODO

  /// Built-in multiplication function should only take two arguments.
  func testArity() {
    expectArityErrorFrom("(.* 1)")
    expectArityErrorFrom("(.* 1 1 1)")
  }
}

class TestDivide : InterpreterTest {

  /// Division with ints should work.
  func testInts() {
    let result1 = Double(59) / Double(18)
    expectThat("(./ 59 18)", shouldEvalTo: .FloatLiteral(result1))
    let result2 = Double(-881) / Double(199692)
    expectThat("(./ -881 199692)", shouldEvalTo: .FloatLiteral(result2))
  }

  /// Division with floats should work.
  func testFloats() {
    let result1 : Double = 61.2 / 18886.1111
    expectThat("(./ 61.2 18886.1111)", shouldEvalTo: .FloatLiteral(result1))
    let result2 : Double = 9218388.0 / -187721.999
    expectThat("(./ 9218388.0 -187721.999)", shouldEvalTo: .FloatLiteral(result2))
  }

  /// Division with mixed types should work.
  func testMixed() {
    let result1 : Double = Double(8817) / 0.293878
    expectThat("(./ 8817 0.293878)", shouldEvalTo: .FloatLiteral(result1))
    let result2 : Double = 0.293878 / Double(8817)
    expectThat("(./ 0.293878 8817)", shouldEvalTo: .FloatLiteral(result2))
  }

  /// Division should return an integer result if evenly divisible, and both operands are integers.
  func testIntEvenDivision() {
    expectThat("(./ 120 6)", shouldEvalTo: .IntegerLiteral(20))
    expectThat("(./ -75 15)", shouldEvalTo: .IntegerLiteral(-5))
  }

  /// Division should trap zero divisor.
  func testDivideByZero() {
    expectThat("(./ 5812 0)", shouldFailAs: .DivideByZeroError)
    expectThat("(./ 5812 0.0)", shouldFailAs: .DivideByZeroError)
    expectThat("(./ 5812.7188 0)", shouldFailAs: .DivideByZeroError)
    expectThat("(./ 5812.7188 0.0)", shouldFailAs: .DivideByZeroError)
  }

  /// Division should trap overflow.
  func testOverflow() {
    expectThat("(./ -9223372036854775808 -1)", shouldFailAs: .IntegerOverflowError)
  }

  /// Built-in division function should only take two arguments.
  func testArity() {
    expectArityErrorFrom("(./ 1)")
    expectArityErrorFrom("(./ 1 1 1)")
  }
}

class TestRem : InterpreterTest {
  // TODO

  /// Remainder should trap overflow.
  func testOverflow() {
    expectThat("(.rem -9223372036854775808 -1)", shouldFailAs: .IntegerOverflowError)
  }

  /// Built-in remainder function should only take two arguments.
  func testArity() {
    expectArityErrorFrom("(.rem 1)")
    expectArityErrorFrom("(.rem 1 1 1)")
  }
}

class TestQuot : InterpreterTest {
  // TODO
}
