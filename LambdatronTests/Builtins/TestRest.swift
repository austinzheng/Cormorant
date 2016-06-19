//
//  TestRest.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/3/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestRestBuiltin : InterpreterTest {

  /// .rest should return the empty list if passed in nil.
  func testWithNil() {
    expectThat("(.rest nil)", shouldEvalTo: .seq(EmptyNode))
  }

  /// .rest should return the empty list for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.rest \"\")", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest ())", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest (.lazy-seq (fn [])))", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest [])", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest {})", shouldEvalTo: .seq(EmptyNode))
  }

  /// .rest should return the empty list for single-element collections.
  func testWithOneElement() {
    expectThat("(.rest \"a\")", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest (.lazy-seq (fn [] '(10))))", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest '(:a))", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest [\\a])", shouldEvalTo: .seq(EmptyNode))
    expectThat("(.rest {'a 10})", shouldEvalTo: .seq(EmptyNode))
  }

  /// .rest should return a sequence comprised of the rest of the characters of a string.
  func testWithStrings() {
    expectThat("(.rest \"abc\")",
      shouldEvalTo: list(containing: .char("b"), .char("c")))
    expectThat("(.rest \"\\n\\\\\nq\")",
      shouldEvalTo: list(containing: .char("\\"), .char("\n"), .char("q")))
    expectThat("(.rest \"foobar\")",
      shouldEvalTo: list(containing: .char("o"), .char("o"), .char("b"),
        .char("a"), .char("r")))
  }

  /// .rest should return a sequence comprised of the rest of the elements in a list.
  func testWithLists() {
    expectThat("(.rest '(true false nil 1 2.1 3))", shouldEvalTo: list(containing: false, .nilValue, 1, 2.1, 3))
    expectThat("(.rest '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo:
      list(containing: list(containing: 3, 4), list(containing: 5, 6), list(containing: 7, 8), list()))
  }

  /// .rest should return the rest of a lazy seq, forcing evaluation if necessary.
  func testWithLazySeqs() {
    run(input: "(def a (.lazy-seq (fn [] (.print \"executed thunk\") '(\"foo\" \"bar\" \"baz\"))))")
    expectEmptyOutputBuffer()
    // At this point, the thunk should fire
    expectThat("(.rest a)", shouldEvalTo: list(containing: .string("bar"), .string("baz")))
    expectOutputBuffer(toBe: "executed thunk")
    clearOutputBuffer()
    // Don't re-evalaute the thunk
    expectThat("(.rest a)", shouldEvalTo: list(containing: .string("bar"), .string("baz")))
    expectEmptyOutputBuffer()
  }

  /// .rest should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.rest [false true nil 1 2.1 3])", shouldEvalTo: list(containing: true, .nilValue, 1, 2.1, 3))
    expectThat("(.rest [[1 2] [3 4] [5 6] [7 8] []])",
               shouldEvalTo: list(containing: vector(containing: 3, 4),
                                  vector(containing: 5, 6),
                                  vector(containing: 7, 8),
                                  vector()))
  }

  // TODO: (az) make this less fragile
  /// .rest should return a sequence comprised of the rest of the key-value pairs in a map.
//  func testWithMaps() {
//    let a = keyword("a")
//    let b = keyword("b")
////    let c = keyword("c")
//    expectThat("(.rest {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo:
//      listWithItems(vector(containing: .keyword(b), 2), vector(containing: .keyword(a), 1),
//        vector(containing: .char("d"), 4)))
//    expectThat("(.rest {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo:
//      listWithItems(vector(containing: true, .string("bar")),
//        vector(containing: .string("foo"), .char("a"))))
//  }

  /// .rest should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectInvalidArgumentErrorFrom("(.rest true)")
    expectInvalidArgumentErrorFrom("(.rest false)")
    expectInvalidArgumentErrorFrom("(.rest 152)")
    expectInvalidArgumentErrorFrom("(.rest 3.141592)")
    expectInvalidArgumentErrorFrom("(.rest :foo)")
    expectInvalidArgumentErrorFrom("(.rest 'foo)")
    expectInvalidArgumentErrorFrom("(.rest \\f)")
    expectInvalidArgumentErrorFrom("(.rest .+)")
  }

  /// .rest should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.rest)")
    expectArityErrorFrom("(.rest nil nil)")
  }
}
