//
//  TestInt.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestIntBuiltin : InterpreterTest {

  /// .int should return integer values unchanged.
  func testWithInt() {
    expectThat("(.int 51222)", shouldEvalTo: 51222)
  }

  /// .int should coerce and truncate floating-point values to integers.
  func testWithDouble() {
    expectThat("(.int 1.99912)", shouldEvalTo: 1)
  }

  /// .int should coerce characters to their raw values.
  func testWithChar() {
    expectThat("(.int \\g)", shouldEvalTo: 103)
  }

  /// .int should fail with any non-numeric argument.
  func testWithInvalidArguments() {
    expectThat("(.int nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int #\"[0-9]+\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int ())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .int should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.int)")
    expectArityErrorFrom("(.int 0 1)")
  }
}
