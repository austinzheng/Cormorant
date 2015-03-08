//
//  TestConj.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/4/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestConjBuiltin : InterpreterTest {

  /// .conj should work with nil collections.
  func testNil() {
    expectThat("(.conj nil 5)", shouldEvalTo: listWithItems(ConsValue.IntAtom(5)))
    expectThat("(.conj nil \"foobar\")", shouldEvalTo: listWithItems(ConsValue.StringAtom("foobar")))
  }

  /// .conj should work with lists.
  func testLists() {
    expectThat("(.conj () 5)", shouldEvalTo: listWithItems(ConsValue.IntAtom(5)))
    expectThat("(.conj '(1 2 3) \\c)", shouldEvalTo: listWithItems(.CharAtom("c"), 1, 2, 3))
  }

  /// .conj should work with vectors.
  func testVectors() {
    expectThat("(.conj [] 5)", shouldEvalTo: vectorWithItems(ConsValue.IntAtom(5)))
    expectThat("(.conj [1 2 3] \\c)", shouldEvalTo: vectorWithItems(1, 2, 3, .CharAtom("c")))
  }

  /// .conj should work with maps.
  func testMaps() {
    let aKeyword = interpreter.context.keywordForName("a")
    let bKeyword = interpreter.context.keywordForName("b")
    expectThat("(.conj {} [:a 100])",
      shouldEvalTo: mapWithItems((ConsValue.Keyword(aKeyword), 100)))
    expectThat("(.conj {:b \"foo\"} [:a 100])",
      shouldEvalTo: mapWithItems((.Keyword(aKeyword), 100), (.Keyword(bKeyword), .StringAtom("foo"))))
  }

  /// .conj should require the first argument to be a collection.
  func testCollectionParam() {
    expectThat("(.conj true 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj false 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj -1 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj 0.0003 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj \\w 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj :w 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj 'w 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj \"foobar\" 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj .conj 1)", shouldFailAs: .InvalidArgumentError)
  }

  /// .conj should require the second argument to be a two-item vector, if the first is a map.
  func testKeyValueVector() {
    expectThat("(.conj {} nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} 918)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} 1.11121)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} \\y)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} :y)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} 'y)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} \"foobar\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} {:a 1})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} '(:a 2))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} [1])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.conj {} [:a 1 2])", shouldFailAs: .InvalidArgumentError)
  }

  /// .conj should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.conj)")
    expectArityErrorFrom("(.conj nil)")
    expectArityErrorFrom("(.conj () 1 2)")
  }
}
