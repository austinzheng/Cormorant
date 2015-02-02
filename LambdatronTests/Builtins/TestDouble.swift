//
//  TestDouble.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/22/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestDoubleBuiltin : InterpreterTest {

  /// .double should return floating-point number arguments unchanged.
  func testWithDouble() {
    expectThat("(.double 12.12355)", shouldEvalTo: .FloatLiteral(12.12355))
  }

  /// .double should coerce integer arguments to floating-point values.
  func testWithInt() {
    expectThat("(.double 19012)", shouldEvalTo: .FloatLiteral(19012.0))
  }

  /// .double should fail with any non-numeric argument.
  func testWithInvalidArguments() {
    expectThat("(.double nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .double should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.double)")
    expectArityErrorFrom("(.double 0 1)")
  }
}
