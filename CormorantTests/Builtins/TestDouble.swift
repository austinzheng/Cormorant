//
//  TestDouble.swift
//  Cormorant
//
//  Created by Austin Zheng on 1/22/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestDoubleBuiltin : InterpreterTest {

  /// .double should return floating-point number arguments unchanged.
  func testWithDouble() {
    expectThat("(.double 12.12355)", shouldEvalTo: 12.12355)
  }

  /// .double should coerce integer arguments to floating-point values.
  func testWithInt() {
    expectThat("(.double 19012)", shouldEvalTo: 19012.0)
  }

  /// .double should fail with any non-numeric argument.
  func testWithInvalidArguments() {
    expectInvalidArgumentErrorFrom("(.double nil)")
    expectInvalidArgumentErrorFrom("(.double true)")
    expectInvalidArgumentErrorFrom("(.double false)")
    expectInvalidArgumentErrorFrom("(.double \"\")")
    expectInvalidArgumentErrorFrom("(.double #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.double \\a)")
    expectInvalidArgumentErrorFrom("(.double 'a)")
    expectInvalidArgumentErrorFrom("(.double :a)")
    expectInvalidArgumentErrorFrom("(.double [])")
    expectInvalidArgumentErrorFrom("(.double ())")
    expectInvalidArgumentErrorFrom("(.double {})")
    expectInvalidArgumentErrorFrom("(.double (fn [] 0))")
    expectInvalidArgumentErrorFrom("(.double .+)")
  }

  /// .double should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.double)")
    expectArityErrorFrom("(.double 0 1)")
  }
}
