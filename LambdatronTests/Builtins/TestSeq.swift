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
    expectThat("(.seq nil)", shouldEvalTo: .Nil)
  }

  /// .seq should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.seq \"\")", shouldEvalTo: .Nil)
    expectThat("(.seq ())", shouldEvalTo: .Nil)
    expectThat("(.seq [])", shouldEvalTo: .Nil)
    expectThat("(.seq {})", shouldEvalTo: .Nil)
  }

  /// .seq should return a sequence comprised of the characters of a string.
  func testWithStrings() {
    expectThat("(.seq \"abc\")",
      shouldEvalTo: listWithItems(.CharAtom("a"), .CharAtom("b"), .CharAtom("c")))
    expectThat("(.seq \"\\n\\\\\nq\")",
      shouldEvalTo: listWithItems(.CharAtom("\n"), .CharAtom("\\"), .CharAtom("\n"),
        .CharAtom("q")))
    expectThat("(.seq \"foobar\")",
      shouldEvalTo: listWithItems(.CharAtom("f"), .CharAtom("o"), .CharAtom("o"),
        .CharAtom("b"), .CharAtom("a"), .CharAtom("r")))
  }

  /// .seq should return a sequence comprised of the elements in a list.
  func testWithLists() {
    expectThat("(.seq '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(true, false, .Nil, 1, 2.1, 3))
    expectThat("(.seq '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo:
      listWithItems(listWithItems(1, 2), listWithItems(3, 4), listWithItems(5, 6), listWithItems(7, 8),
        listWithItems()))
  }

  /// .seq should return a sequence from a lazy seq, evaluating if necessary.
  func testWithLazySeqs() {
    expectThat("(.seq (.lazy-seq (fn [] '(1 2 3 4 5 6 7))))", shouldEvalTo: listWithItems(1, 2, 3, 4, 5, 6, 7))
  }

  /// .seq should return a sequence comprised of the elements in a vector.
  func testWithVectors() {
    expectThat("(.seq [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(false, true, .Nil, 1, 2.1, 3))
    expectThat("(.seq [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo:
      listWithItems(vectorWithItems(1, 2), vectorWithItems(3, 4), vectorWithItems(5, 6), vectorWithItems(7, 8),
        vectorWithItems()))
  }

  /// .seq should return a sequence comprised of the key-value pairs in a map.
  func testWithMaps() {
    let a = keyword("a")
    let b = keyword("b")
    let c = keyword("c")
    expectThat("(.seq {:a 1 :b 2 :c 3 \\d 4})",
      shouldEvalToContain: vectorWithItems(.Keyword(a), 1), vectorWithItems(.Keyword(b), 2),
      vectorWithItems(.Keyword(c), 3), vectorWithItems(.CharAtom("d"), 4))
    expectThat("(.seq {\"foo\" \\a nil \"baz\" true \"bar\"})",
      shouldEvalToContain: vectorWithItems(.Nil, .StringAtom("baz")), vectorWithItems(true, .StringAtom("bar")),
      vectorWithItems(.StringAtom("foo"), .CharAtom("a")))
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
