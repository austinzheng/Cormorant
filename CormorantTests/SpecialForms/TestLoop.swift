//
//  TestLoop.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/11/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'loop' special form
class TestLoop : InterpreterTest {

  /// loop should allow the user to define a loop with no explicit body.
  func testEmptyLoop() {
    expectThat("(loop [])", shouldEvalTo: .nilValue)
  }

  /// loop should allow the user to define a loop with one or more body statements, the last of which is returned.
  func testSingleIterationLoop() {
    expectThat("(loop [] (.print \"a\") (.print \"b\") 152)", shouldEvalTo: 152)
    expectOutputBuffer(toBe: "ab")
  }

  /// loop should bind the values in its binding vector to the local lexical context.
  func testLoopLocalBinding() {
    expectThat("(loop [a 10 b (.+ a 1) c (.+ b 1)] (.print a) (.print b) (.print c) (.+ (.+ a b) c))", shouldEvalTo: 33)
    expectOutputBuffer(toBe: "101112")
  }

  /// loop should properly execute multiple times in conjunction with the 'recur' form, properly rebinding the arguments
  /// each time it iterates.
  func testLoopRecur() {
    expectThat("(loop [ctr 10 sum 0] (.print \"ctr:\" ctr \"sum:\" sum \"\") (if (.= 0 ctr) sum (recur (.- ctr 1) (.+ sum ctr))))",
      shouldEvalTo: 55)
    expectOutputBuffer(toBe: "ctr: 10 sum: 0 ctr: 9 sum: 10 ctr: 8 sum: 19 ctr: 7 sum: 27 ctr: 6 sum: 34 ctr: 5 sum: 40 ctr: 4 sum: 45 ctr: 3 sum: 49 ctr: 2 sum: 52 ctr: 1 sum: 54 ctr: 0 sum: 55 ")
  }

  /// loop should fail if not given a binding vector.
  func testLoopWithoutBinding() {
    expectThat("(loop)", shouldFailAs: .ArityError)
    expectInvalidArgumentErrorFrom("(loop 150)")
    expectInvalidArgumentErrorFrom("(loop '(a 10 b 11))")
  }

  /// loop should fail if there are an odd number of forms in the binding vector.
  func testLoopWithUnmatchedBinding() {
    expectThat("(loop [a])", shouldFailAs: .BindingMismatchError)
    expectThat("(loop [a 10 b])", shouldFailAs: .BindingMismatchError)
    expectThat("(loop [a 10 b 11 c])", shouldFailAs: .BindingMismatchError)
  }

  /// loop should fail if an even-indexed form in the binding vector is not a symbol.
  func testLoopWithNonSymbolBinding() {
    expectInvalidArgumentErrorFrom("(loop [1 2])")
    expectInvalidArgumentErrorFrom("(loop [a 2 \\b 2 c 3])")
    expectInvalidArgumentErrorFrom("(loop [a 2 :b 2 c 3])")
    expectInvalidArgumentErrorFrom("(loop [a 2 \"b\" 2 c 3])")
  }

  /// loop should reject qualified symbols in the binding vector.
  func testWithQualifiedSymbols() {
    expectThat("(loop [foo/a 10] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
    expectThat("(loop [a 10 foo/b 20] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
    expectThat("(loop [ns1/a 10 ns2/b 20] nil)", shouldFailAs: .QualifiedSymbolMisuseError)
  }
}
