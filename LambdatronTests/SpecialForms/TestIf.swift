//
//  TestIf.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/19/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'if' special form.
class TestIf : InterpreterTest {

  /// If the predicate is true, the second form should be evaluated.
  func testTrueCase() {
    expectThat("(if (.> 10 1) (do (.print \"good\") 10))", shouldEvalTo: .IntAtom(10))
    expectOutputBuffer(toBe: "good")
  }

  /// If the predicate is true, the second form should be evaluated and the third form should not be evaluated.
  func testTrueCaseWithElse() {
    expectThat("(if (.> 10 1) (do (.print \"good\") 10) (do (.print \"bad\") 20))",
      shouldEvalTo: .IntAtom(10))
    expectOutputBuffer(toBe: "good")
  }

  /// If the predicate is false and there is no third form, nil should be returned.
  func testFalseCase() {
    // With no 'else', evaluate to nil
    expectThat("(if (.> 1 10) (do (.print \"bad\") 10))", shouldEvalTo: .Nil)
    expectOutputBuffer(toBe: "")
  }

  /// If the predicate is false, the third form should be evaluated and the second form should not be evaluated.
  func testFalseCaseWithElse() {
    expectThat("(if (.> 1 10) (do (.print \"bad\") 10) (do (.print \"good\") 20))", shouldEvalTo: .IntAtom(20))
    expectOutputBuffer(toBe: "good")
  }

  /// A predicate evaluating to 'nil' should be treated as false.
  func testNilIsFalse() {
    expectThat("(if nil \\a \\c)", shouldEvalTo: .CharAtom("c"))
  }

  /// 'if' should not take fewer than two arguments.
  func testOneArity() {
    expectArityErrorFrom("(if true)")
  }

  /// 'if' should not take more than three arguments.
  func testFourArity() {
    expectArityErrorFrom("(if true 1 2 3)")
  }
}
