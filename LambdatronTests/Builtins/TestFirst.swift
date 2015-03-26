//
//  TestFirst.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/3/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestFirstBuiltin : InterpreterTest {

  /// .first should return nil if passed in nil.
  func testWithNil() {
    expectThat("(.first nil)", shouldEvalTo: .Nil)
  }

  /// .first should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.first \"\")", shouldEvalTo: .Nil)
    expectThat("(.first ())", shouldEvalTo: .Nil)
    expectThat("(.first [])", shouldEvalTo: .Nil)
    expectThat("(.first {})", shouldEvalTo: .Nil)
  }

  /// .first should return the first character of a string.
  func testWithStrings() {
    expectThat("(.first \"a\")", shouldEvalTo: .CharAtom("a"))
    expectThat("(.first \"foobar\")", shouldEvalTo: .CharAtom("f"))
    expectThat("(.first \"\nthequickbrownfox\")", shouldEvalTo: .CharAtom("\n"))
  }

  /// .first should return the first element of a list.
  func testWithLists() {
    expectThat("(.first '(true))", shouldEvalTo: true)
    expectThat("(.first '(15 29 \"foo\" :bar nil))", shouldEvalTo: 15)
    expectThat("(.first '((1 2 3) 4 5))", shouldEvalTo: listWithItems(1, 2, 3))
  }

  /// .first should return the first element of a vector.
  func testWithVectors() {
    expectThat("(.first [false])", shouldEvalTo: false)
    expectThat("(.first [29981.1 \"foo\" :bar nil])", shouldEvalTo: 29981.1)
    expectThat("(.first [[1 2 3] 4 5])", shouldEvalTo: vectorWithItems(1, 2, 3))
  }

  /// .first should return the first element of a map.
  func testWithMaps() {
    let a = keyword("a")
    let b = keyword("b")
    expectThat("(.first {:a 1})", shouldEvalTo: vectorWithItems(.Keyword(a), 1))
    expectThat("(.first {:b 2 :a 1 \\c 3})", shouldEvalTo: vectorWithItems(.Keyword(b), 2))
  }

  /// .first should return the first element of a lazy seq, forcing evaluation if necessary.
  func testWithLazySeqs() {
    runCode("(def a (.lazy-seq (fn [] (.print \"executed thunk\") '(\"foo\" \"bar\" \"baz\"))))")
    expectEmptyOutputBuffer()
    // At this point, the thunk should fire
    expectThat("(.first a)", shouldEvalTo: .StringAtom("foo"))
    expectOutputBuffer(toBe: "executed thunk")
    clearOutputBuffer()
    // Don't re-evalaute the thunk
    expectThat("(.first a)", shouldEvalTo: .StringAtom("foo"))
    expectEmptyOutputBuffer()
  }

  /// .first should return nil if passed a lazy seq with no elements.
  func testWithEmptyLazySeq() {
    expectThat("(.first (.lazy-seq (fn [])))", shouldEvalTo: .Nil)
  }

  /// .first should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectInvalidArgumentErrorFrom("(.first true)")
    expectInvalidArgumentErrorFrom("(.first false)")
    expectInvalidArgumentErrorFrom("(.first 152)")
    expectInvalidArgumentErrorFrom("(.first 3.141592)")
    expectInvalidArgumentErrorFrom("(.first :foo)")
    expectInvalidArgumentErrorFrom("(.first 'foo)")
    expectInvalidArgumentErrorFrom("(.first \\f)")
    expectInvalidArgumentErrorFrom("(.first .+)")
  }

  /// .first should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.first)")
    expectArityErrorFrom("(.first nil nil)")
  }
}
