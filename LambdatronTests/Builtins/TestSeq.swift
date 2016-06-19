//
//  TestSeq.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/3/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestSeqBuiltin : InterpreterTest {

  /// .seq should return nil if passed in nil.
  func testWithNil() {
    expectThat("(.seq nil)", shouldEvalTo: .nilValue)
  }

  /// .seq should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.seq \"\")", shouldEvalTo: .nilValue)
    expectThat("(.seq ())", shouldEvalTo: .nilValue)
    expectThat("(.seq [])", shouldEvalTo: .nilValue)
    expectThat("(.seq {})", shouldEvalTo: .nilValue)
  }

  /// .seq should return a sequence comprised of the characters of a string.
  func testWithStrings() {
    expectThat("(.seq \"abc\")",
      shouldEvalTo: list(containing: .char("a"), .char("b"), .char("c")))
    expectThat("(.seq \"\\n\\\\\nq\")",
      shouldEvalTo: list(containing: .char("\n"), .char("\\"), .char("\n"),
        .char("q")))
    expectThat("(.seq \"foobar\")",
      shouldEvalTo: list(containing: .char("f"), .char("o"), .char("o"),
        .char("b"), .char("a"), .char("r")))
  }

  /// .seq should return a sequence comprised of the elements in a list.
  func testWithLists() {
    expectThat("(.seq '(true false nil 1 2.1 3))", shouldEvalTo: list(containing: true, false, .nilValue, 1, 2.1, 3))
    expectThat("(.seq '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo:
      list(containing: list(containing: 1, 2), list(containing: 3, 4), list(containing: 5, 6), list(containing: 7, 8),
        list()))
  }

  /// .seq should return a sequence from a lazy seq, evaluating if necessary.
  func testWithLazySeqs() {
    expectThat("(.seq (.lazy-seq (fn [] '(1 2 3 4 5 6 7))))", shouldEvalTo: list(containing: 1, 2, 3, 4, 5, 6, 7))
  }

  /// .seq should return a sequence comprised of the elements in a vector.
  func testWithVectors() {
    expectThat("(.seq [false true nil 1 2.1 3])", shouldEvalTo: list(containing: false, true, .nilValue, 1, 2.1, 3))
    expectThat("(.seq [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo:
      list(containing: vector(containing: 1, 2), vector(containing: 3, 4), vector(containing: 5, 6), vector(containing: 7, 8),
        vector()))
  }

  /// .seq should return a sequence comprised of the key-value pairs in a map.
  func testWithMaps() {
    let a = keyword("a")
    let b = keyword("b")
    let c = keyword("c")
    expectThat("(.seq {:a 1 :b 2 :c 3 \\d 4})",
      shouldEvalToContain: vector(containing: .keyword(a), 1), vector(containing: .keyword(b), 2),
      vector(containing: .keyword(c), 3), vector(containing: .char("d"), 4))
    expectThat("(.seq {\"foo\" \\a nil \"baz\" true \"bar\"})",
      shouldEvalToContain: vector(containing: .nilValue, .string("baz")), vector(containing: true, .string("bar")),
      vector(containing: .string("foo"), .char("a")))
  }

  /// .seq should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectInvalidArgumentErrorFrom("(.seq true)")
    expectInvalidArgumentErrorFrom("(.seq false)")
    expectInvalidArgumentErrorFrom("(.seq 152)")
    expectInvalidArgumentErrorFrom("(.seq 3.141592)")
    expectInvalidArgumentErrorFrom("(.seq :foo)")
    expectInvalidArgumentErrorFrom("(.seq 'foo)")
    expectInvalidArgumentErrorFrom("(.seq \\f)")
    expectInvalidArgumentErrorFrom("(.seq .+)")
  }

  /// .seq should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.seq)")
    expectArityErrorFrom("(.seq nil nil)")
  }
}
