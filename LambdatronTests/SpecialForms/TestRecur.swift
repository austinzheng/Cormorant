//
//  TestRecur.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/11/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'recur' special form.
class TestRecur : InterpreterTest {
  // Note: tests for proper execution of functions and loops with 'recur' can be found in TestEvaluating and TestLoops.

  func expectRecurErrorFrom(_ input: String) {
    expectThat(input, shouldFailAs: .RecurMisuseError)
  }

  /// recur should reject being used outside of tail position in a function.
  func testRecurOutsideFnTailPosition() {
    expectRecurErrorFrom("((fn [a b] (recur (.- a 1) b) (if (.= a 0) a b)) 10 11)")
    expectRecurErrorFrom("((fn [a b] (if (.= a 0) \"done\" (do (recur (.- a 1) b) (.print \"hello\")))) 15 2)")
  }

  /// recur should reject being used outside of tail position in a loop.
  func testRecurOutsideLoopTailPosition() {
    expectRecurErrorFrom("(loop [a 10 b 20] (recur (.- a 1) b) 100)")
    expectRecurErrorFrom("(loop [a 10 b 20] (if (.= a 0) \"done\" (do (recur (.- a 1) b) (.print \"hello\"))))")
  }

  /// recur should reject being evaluated outside a function or loop.
  func testRecurOutsideFnOrLoop() {
    expectRecurErrorFrom("(recur)")
    expectRecurErrorFrom("(if true (recur 50) 1)")
    // Note that, since '(recur)' is never actually evaluated, this form should work fine.
    expectThat("(if true 1 (recur))", shouldEvalTo: 1)
  }

  /// recur should reject being used in a binding vector.
  func testRecurInBindingVector() {
    expectRecurErrorFrom("(let [a 10 b (recur 1 2 3)] (.+ a b))")
    expectRecurErrorFrom("(loop [a 10 b (recur 1 2 3)] (.+ a b))")
  }

  /// recur should reject not being invoked with a matching number of arguments relative to the enclosing function.
  func testRecurFnArity() {
    expectArityErrorFrom("((fn [ctr a] (if (.= ctr 0) a (recur (.- ctr 1)))) 10 \"foobar\")")
    expectArityErrorFrom("((fn [ctr a] (if (.= ctr 0) a (recur (.- ctr 1) a a))) 10 \"foobar\")")
  }

  /// recur at the end of a function with a vararg should accept a single value as the vararg (and not nothing or an
  /// arbitrary-list length of values to build into a new vararg).
  func testRecurVarargFnArity() {
    expectArityErrorFrom("((fn [ctr & a] (if (.= ctr 0) a (recur (.- ctr 1)))) 10 \\a \\b \\c)")
    expectArityErrorFrom("((fn [ctr & a] (if (.= ctr 0) a (recur (.- ctr 1) true false))) 10 \\a \\b \\c)")
  }

  /// recur should reject not being invoked with a matching number of arguments relative to the enclosing loop.
  func testRecurLoopArity() {
    expectArityErrorFrom("(loop [a 10 b 20] (if (.= a 0) b (recur (.- a 1))))")
    expectArityErrorFrom("(loop [a 10 b 20] (if (.= a 0) b (recur (.- a 1) b b)))")
  }
}
