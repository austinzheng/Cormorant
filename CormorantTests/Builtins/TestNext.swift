//
//  TestNext.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/3/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestNextBuiltin : InterpreterTest {

  /// .next should return nil if passed in nil.
  func testWithNil() {
    expectThat("(.next nil)", shouldEvalTo: .nilValue)
  }

  /// .next should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.next \"\")", shouldEvalTo: .nilValue)
    expectThat("(.next ())", shouldEvalTo: .nilValue)
    expectThat("(.next (.lazy-seq (fn [])))", shouldEvalTo: .nilValue)
    expectThat("(.next [])", shouldEvalTo: .nilValue)
    expectThat("(.next {})", shouldEvalTo: .nilValue)
  }

  /// .next should return nil for single-element collections.
  func testWithOneElement() {
    expectThat("(.next \"a\")", shouldEvalTo: .nilValue)
    expectThat("(.next '(:a))", shouldEvalTo: .nilValue)
    expectThat("(.next (.lazy-seq (fn [] '(10))))", shouldEvalTo: .nilValue)
    expectThat("(.next [\\a])", shouldEvalTo: .nilValue)
    expectThat("(.next {'a 10})", shouldEvalTo: .nilValue)
  }

  /// .next should return a sequence comprised of the rest of the characters of a string.
  func testWithStrings() {
    expectThat("(.next \"abc\")",
      shouldEvalTo: list(containing: .char("b"), .char("c")))
    expectThat("(.next \"\\n\\\\\nq\")",
      shouldEvalTo: list(containing: .char("\\"), .char("\n"), .char("q")))
    expectThat("(.next \"foobar\")",
      shouldEvalTo: list(containing: .char("o"), .char("o"), .char("b"),
        .char("a"), .char("r")))
  }

  /// .next should return a sequence comprised of the rest of the elements in a list.
  func testWithLists() {
    expectThat("(.next '(true false nil 1 2.1 3))",
      shouldEvalTo: list(containing: false, .nilValue, 1, 2.1, 3))
    expectThat("(.next '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo:
      list(containing: list(containing: 3, 4), list(containing: 5, 6), list(containing: 7, 8), list()))
  }

  /// .next should return the rest of a lazy seq, forcing evaluation if necessary.
  func testWithLazySeqs() {
    run(input: "(def a (.lazy-seq (fn [] (.print \"executed thunk\") '(\"foo\" \"bar\" \"baz\"))))")
    expectEmptyOutputBuffer()
    // At this point, the thunk should fire
    expectThat("(.next a)", shouldEvalTo: list(containing: .string("bar"), .string("baz")))
    expectOutputBuffer(toBe: "executed thunk")
    clearOutputBuffer()
    // Don't re-evalaute the thunk
    expectThat("(.next a)", shouldEvalTo: list(containing: .string("bar"), .string("baz")))
    expectEmptyOutputBuffer()
  }

  /// .next should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.next [false true nil 1 2.1 3])",
      shouldEvalTo: list(containing: true, .nilValue, 1, 2.1, 3))
    expectThat("(.next [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo:
      list(containing: vector(containing: 3, 4), vector(containing: 5, 6), vector(containing: 7, 8), vector()))
  }

  // TODO: (az) make this less fragile
  /// .next should return a sequence comprised of the rest of the key-value pairs in a map.
//  func testWithMaps() {
//    let a = keyword("a")
//    let b = keyword("b")
////    let c = keyword("c")
//    expectThat("(.next {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo:
//      listWithItems(vector(containing: .keyword(b), 2), vector(containing: .keyword(a), 1),
//        vector(containing: .char("d"), 4)))
//    expectThat("(.next {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo:
//      listWithItems(vector(containing: true, .string("bar")),
//        vector(containing: .string("foo"), .char("a"))))
//  }

  /// .next should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectInvalidArgumentErrorFrom("(.next true)")
    expectInvalidArgumentErrorFrom("(.next false)")
    expectInvalidArgumentErrorFrom("(.next 152)")
    expectInvalidArgumentErrorFrom("(.next 3.141592)")
    expectInvalidArgumentErrorFrom("(.next :foo)")
    expectInvalidArgumentErrorFrom("(.next 'foo)")
    expectInvalidArgumentErrorFrom("(.next \\f)")
    expectInvalidArgumentErrorFrom("(.next .+)")
  }

  /// .next should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.next)")
    expectArityErrorFrom("(.next nil nil)")
  }
}
