//
//  TestPrimitiveManip.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/22/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestSymbolBuiltin : InterpreterTest {
  // TODO
}

class TestKeywordBuiltin : InterpreterTest {
  // TODO
}

class TestIntBuiltin : InterpreterTest {

  /// int should return integer values unchanged.
  func testWithInt() {
    expectThat("(.int 51222)", shouldEvalTo: .IntegerLiteral(51222))
  }

  /// int should coerce and truncate floating-point values to integers.
  func testWithDouble() {
    expectThat("(.int 1.99912)", shouldEvalTo: .IntegerLiteral(1))
  }

  /// int should coerce characters to their raw values.
  func testWithChar() {
    expectThat("(.int \\g)", shouldEvalTo: .IntegerLiteral(103))
  }

  /// int should fail with any non-numeric argument.
  func testWithInvalidArguments() {
    expectThat("(.int nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// int should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.int)")
    expectArityErrorFrom("(.int 0 1)")
  }
}

class TestDoubleBuiltin : InterpreterTest {

  /// double should return floating-point number arguments unchanged.
  func testWithDouble() {
    expectThat("(.double 12.12355)", shouldEvalTo: .FloatLiteral(12.12355))
  }

  /// double should coerce integer arguments to floating-point values.
  func testWithInt() {
    expectThat("(.double 19012)", shouldEvalTo: .FloatLiteral(19012.0))
  }

  /// double should fail with any non-numeric argument.
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

  /// double should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.double)")
    expectArityErrorFrom("(.double 0 1)")
  }
}
