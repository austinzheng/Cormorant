//
//  TestNext.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/3/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestNextBuiltin : InterpreterTest {

  /// .next should return nil if passed in nil.
  func testWithNil() {
    expectThat("(.next nil)", shouldEvalTo: .Nil)
  }

  /// .next should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.next \"\")", shouldEvalTo: .Nil)
    expectThat("(.next ())", shouldEvalTo: .Nil)
    expectThat("(.next (.lazy-seq (fn [])))", shouldEvalTo: .Nil)
    expectThat("(.next [])", shouldEvalTo: .Nil)
    expectThat("(.next {})", shouldEvalTo: .Nil)
  }

  /// .next should return nil for single-element collections.
  func testWithOneElement() {
    expectThat("(.next \"a\")", shouldEvalTo: .Nil)
    expectThat("(.next '(:a))", shouldEvalTo: .Nil)
    expectThat("(.next (.lazy-seq (fn [] '(10))))", shouldEvalTo: .Nil)
    expectThat("(.next [\\a])", shouldEvalTo: .Nil)
    expectThat("(.next {'a 10})", shouldEvalTo: .Nil)
  }

  /// .next should return a sequence comprised of the rest of the characters of a string.
  func testWithStrings() {
    expectThat("(.next \"abc\")",
      shouldEvalTo: listWithItems(.CharAtom("b"), .CharAtom("c")))
    expectThat("(.next \"\\n\\\\\nq\")",
      shouldEvalTo: listWithItems(.CharAtom("\\"), .CharAtom("\n"), .CharAtom("q")))
    expectThat("(.next \"foobar\")",
      shouldEvalTo: listWithItems(.CharAtom("o"), .CharAtom("o"), .CharAtom("b"),
        .CharAtom("a"), .CharAtom("r")))
  }

  /// .next should return a sequence comprised of the rest of the elements in a list.
  func testWithLists() {
    expectThat("(.next '(true false nil 1 2.1 3))",
      shouldEvalTo: listWithItems(false, .Nil, 1, 2.1, 3))
    expectThat("(.next '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo:
      listWithItems(listWithItems(3, 4), listWithItems(5, 6), listWithItems(7, 8), listWithItems()))
  }

  /// .next should return the rest of a lazy seq, forcing evaluation if necessary.
  func testWithLazySeqs() {
    runCode("(def a (.lazy-seq (fn [] (.print \"executed thunk\") '(\"foo\" \"bar\" \"baz\"))))")
    expectEmptyOutputBuffer()
    // At this point, the thunk should fire
    expectThat("(.next a)", shouldEvalTo: listWithItems(.StringAtom("bar"), .StringAtom("baz")))
    expectOutputBuffer(toBe: "executed thunk")
    clearOutputBuffer()
    // Don't re-evalaute the thunk
    expectThat("(.next a)", shouldEvalTo: listWithItems(.StringAtom("bar"), .StringAtom("baz")))
    expectEmptyOutputBuffer()
  }

  /// .next should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.next [false true nil 1 2.1 3])",
      shouldEvalTo: listWithItems(true, .Nil, 1, 2.1, 3))
    expectThat("(.next [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo:
      listWithItems(vectorWithItems(3, 4), vectorWithItems(5, 6), vectorWithItems(7, 8), vectorWithItems()))
  }

  /// .next should return a sequence comprised of the rest of the key-value pairs in a map.
  func testWithMaps() {
    let a = keyword("a")
    let b = keyword("b")
    let c = keyword("c")
    expectThat("(.next {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo:
      listWithItems(vectorWithItems(.Keyword(b), 2), vectorWithItems(.Keyword(a), 1),
        vectorWithItems(.CharAtom("d"), 4)))
    expectThat("(.next {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo:
      listWithItems(vectorWithItems(true, .StringAtom("bar")),
        vectorWithItems(.StringAtom("foo"), .CharAtom("a"))))
  }

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
