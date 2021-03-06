//
//  TestArithmetic.swift
//  Cormorant
//
//  Created by Austin Zheng on 1/28/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestPlusBuiltin : InterpreterTest {

  /// Addition with integers should work.
  func testInts() {
    expectThat("(.+ 2 3)", shouldEvalTo: 5)
    expectThat("(.+ 17882 -929)", shouldEvalTo: 16953)
  }

  /// Addition with floats should work.
  func testFloats() {
    expectThat("(.+ 0.1 0.2)", shouldEvalTo: .float(0.1 + 0.2))
    expectThat("(.+ 2.19591 999123.5990712)", shouldEvalTo: .float(2.19591 + 999123.5990712))
  }

  /// Addition with mixed types should work.
  func testMixed() {
    expectThat("(.+ 1 2.3)", shouldEvalTo: 3.3)
    expectThat("(.+ 2.3 1)", shouldEvalTo: 3.3)
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

class TestMinusBuiltin : InterpreterTest {

  /// Subtraction with integers should work.
  func testInts() {
    expectThat("(.- 1 89)", shouldEvalTo: -88)
    expectThat("(.- -123 -9812)", shouldEvalTo: 9689)
  }

  /// Subtraction with floats should work.
  func testFloats() {
    expectThat("(.- 0.5921 0.2102)", shouldEvalTo: .float(0.5921 - 0.2102))
    expectThat("(.- 2.19591 999123.5990712)", shouldEvalTo: .float(2.19591 - 999123.5990712))
  }

  /// Subtraction with mixed types should work.
  func testMixed() {
    expectThat("(.- 915 1.112)", shouldEvalTo: 913.888)
    expectThat("(.- 1.112 915)", shouldEvalTo: -913.888)
  }

  /// Integer subtraction should trap overflow.
  func testOverflow() {
    expectThat("(.- 9223372036854775807 -1)", shouldFailAs: .IntegerOverflowError)
    expectThat("(.- -9223372036854775808 1)", shouldFailAs: .IntegerOverflowError)
  }

  /// Built-in subtraction function should only take two arguments.
  func testArity() {
    expectArityErrorFrom("(.- 1)")
    expectArityErrorFrom("(.- 1 1 1)")
  }
}

class TestMultiplyBuiltin : InterpreterTest {

  /// Multiplication with integers should work.
  func testInts() {
    expectThat("(.* 20 31)", shouldEvalTo: 620)
    expectThat("(.* 59 -929)", shouldEvalTo: -54811)
  }

  /// Multiplication with floats should work.
  func testFloats() {
    expectThat("(.* 0.2003 159892.129)", shouldEvalTo: .float(0.2003 * 159892.129))
    expectThat("(.* -9297.00028 1.00001289)", shouldEvalTo: .float(-9297.00028 * 1.00001289))
  }

  /// Multiplication with mixed types should work.
  func testMixed() {
    expectThat("(.* 105 2.897)", shouldEvalTo: 304.185)
    expectThat("(.* 2.897 105)", shouldEvalTo: 304.185)
  }

  /// Integer multiplication should trap overflow.
  func testOverflow() {
    expectThat("(.* 9223372036854775807 2)", shouldFailAs: .IntegerOverflowError)
    expectThat("(.* -9223372036854775808 2)", shouldFailAs: .IntegerOverflowError)
  }

  /// Built-in multiplication function should only take two arguments.
  func testArity() {
    expectArityErrorFrom("(.* 1)")
    expectArityErrorFrom("(.* 1 1 1)")
  }
}

class TestDivideBuiltin : InterpreterTest {

  /// Division with ints should work.
  func testInts() {
    let result1 = Double(59) / Double(18)
    expectThat("(./ 59 18)", shouldEvalTo: .float(result1))
    let result2 = Double(-881) / Double(199692)
    expectThat("(./ -881 199692)", shouldEvalTo: .float(result2))
  }

  /// Division with floats should work.
  func testFloats() {
    let result1 : Double = 61.2 / 18886.1111
    expectThat("(./ 61.2 18886.1111)", shouldEvalTo: .float(result1))
    let result2 : Double = 9218388.0 / -187721.999
    expectThat("(./ 9218388.0 -187721.999)", shouldEvalTo: .float(result2))
  }

  /// Division with mixed types should work.
  func testMixed() {
    let result1 : Double = Double(8817) / 0.293878
    expectThat("(./ 8817 0.293878)", shouldEvalTo: .float(result1))
    let result2 : Double = 0.293878 / Double(8817)
    expectThat("(./ 0.293878 8817)", shouldEvalTo: .float(result2))
  }

  /// Division should return an integer result if evenly divisible, and both operands are integers.
  func testIntEvenDivision() {
    expectThat("(./ 120 6)", shouldEvalTo: 20)
    expectThat("(./ -75 15)", shouldEvalTo: -5)
  }

  /// Division should trap zero divisor, but only for integer division.
  func testDivideByZero() {
    expectThat("(./ 5812 0)", shouldFailAs: .DivideByZeroError)
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

class TestRemBuiltin : InterpreterTest {
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

class TestQuotBuiltin : InterpreterTest {
  // TODO
}
