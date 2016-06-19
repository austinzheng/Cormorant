//
//  TestInt.swift
//  Cormorant
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
    expectInvalidArgumentErrorFrom("(.int nil)")
    expectInvalidArgumentErrorFrom("(.int true)")
    expectInvalidArgumentErrorFrom("(.int false)")
    expectInvalidArgumentErrorFrom("(.int \"\")")
    expectInvalidArgumentErrorFrom("(.int #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.int 'a)")
    expectInvalidArgumentErrorFrom("(.int :a)")
    expectInvalidArgumentErrorFrom("(.int [])")
    expectInvalidArgumentErrorFrom("(.int ())")
    expectInvalidArgumentErrorFrom("(.int {})")
    expectInvalidArgumentErrorFrom("(.int (fn [] 0))")
    expectInvalidArgumentErrorFrom("(.int .+)")
  }

  /// .int should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.int)")
    expectArityErrorFrom("(.int 0 1)")
  }
}
