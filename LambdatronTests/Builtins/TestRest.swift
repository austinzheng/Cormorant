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
    expectThat("(.rest nil)", shouldEvalTo: .Seq(EmptyNode))
  }

  /// .rest should return the empty list for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.rest \"\")", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest ())", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest (.lazy-seq (fn [])))", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest [])", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest {})", shouldEvalTo: .Seq(EmptyNode))
  }

  /// .rest should return the empty list for single-element collections.
  func testWithOneElement() {
    expectThat("(.rest \"a\")", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest (.lazy-seq (fn [] '(10))))", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest '(:a))", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest [\\a])", shouldEvalTo: .Seq(EmptyNode))
    expectThat("(.rest {'a 10})", shouldEvalTo: .Seq(EmptyNode))
  }

  /// .rest should return a sequence comprised of the rest of the characters of a string.
  func testWithStrings() {
    expectThat("(.rest \"abc\")",
      shouldEvalTo: listWithItems(.CharAtom("b"), .CharAtom("c")))
    expectThat("(.rest \"\\n\\\\\nq\")",
      shouldEvalTo: listWithItems(.CharAtom("\\"), .CharAtom("\n"), .CharAtom("q")))
    expectThat("(.rest \"foobar\")",
      shouldEvalTo: listWithItems(.CharAtom("o"), .CharAtom("o"), .CharAtom("b"),
        .CharAtom("a"), .CharAtom("r")))
  }

  /// .rest should return a sequence comprised of the rest of the elements in a list.
  func testWithLists() {
    expectThat("(.rest '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(false, .Nil, 1, 2.1, 3))
    expectThat("(.rest '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo:
      listWithItems(listWithItems(3, 4), listWithItems(5, 6), listWithItems(7, 8), listWithItems()))
  }

  /// .rest should return the rest of a lazy seq, forcing evaluation if necessary.
  func testWithLazySeqs() {
    runCode("(def a (.lazy-seq (fn [] (.print \"executed thunk\") '(\"foo\" \"bar\" \"baz\"))))")
    expectEmptyOutputBuffer()
    // At this point, the thunk should fire
    expectThat("(.rest a)", shouldEvalTo: listWithItems(.StringAtom("bar"), .StringAtom("baz")))
    expectOutputBuffer(toBe: "executed thunk")
    clearOutputBuffer()
    // Don't re-evalaute the thunk
    expectThat("(.rest a)", shouldEvalTo: listWithItems(.StringAtom("bar"), .StringAtom("baz")))
    expectEmptyOutputBuffer()
  }

  /// .rest should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.rest [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(true, .Nil, 1, 2.1, 3))
    expectThat("(.rest [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo:
      listWithItems(vectorWithItems(3, 4), vectorWithItems(5, 6), vectorWithItems(7, 8), vectorWithItems()))
  }

  // TODO: (az) make this less fragile
  /// .rest should return a sequence comprised of the rest of the key-value pairs in a map.
//  func testWithMaps() {
//    let a = keyword("a")
//    let b = keyword("b")
////    let c = keyword("c")
//    expectThat("(.rest {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo:
//      listWithItems(vectorWithItems(.Keyword(b), 2), vectorWithItems(.Keyword(a), 1),
//        vectorWithItems(.CharAtom("d"), 4)))
//    expectThat("(.rest {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo:
//      listWithItems(vectorWithItems(true, .StringAtom("bar")),
//        vectorWithItems(.StringAtom("foo"), .CharAtom("a"))))
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
