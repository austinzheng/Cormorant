//
//  TestConj.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/4/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

class TestConjBuiltin : InterpreterTest {

  /// .conj should work with nil collections.
  func testNil() {
    expectThat("(.conj nil 5)", shouldEvalTo: listWithItems(.IntAtom(5)))
    expectThat("(.conj nil \"foobar\")", shouldEvalTo: listWithItems(.StringAtom("foobar")))
  }

  /// .conj should work with lists.
  func testLists() {
    expectThat("(.conj () 5)", shouldEvalTo: listWithItems(.IntAtom(5)))
    expectThat("(.conj '(1 2 3) \\c)", shouldEvalTo: listWithItems(.CharAtom("c"), 1, 2, 3))
  }

  /// .conj should work with vectors.
  func testVectors() {
    expectThat("(.conj [] 5)", shouldEvalTo: vectorWithItems(.IntAtom(5)))
    expectThat("(.conj [1 2 3] \\c)", shouldEvalTo: vectorWithItems(1, 2, 3, .CharAtom("c")))
  }

  /// .conj should work with maps.
  func testMaps() {
    let aKeyword = keyword("a")
    let bKeyword = keyword("b")
    expectThat("(.conj {} [:a 100])",
      shouldEvalTo: mapWithItems((.Keyword(aKeyword), 100)))
    expectThat("(.conj {:b \"foo\"} [:a 100])",
      shouldEvalTo: mapWithItems((.Keyword(aKeyword), 100), (.Keyword(bKeyword), .StringAtom("foo"))))
  }

  /// .conj should require the first argument to be a collection.
  func testCollectionParam() {
    expectInvalidArgumentErrorFrom("(.conj true 1)")
    expectInvalidArgumentErrorFrom("(.conj false 1)")
    expectInvalidArgumentErrorFrom("(.conj -1 1)")
    expectInvalidArgumentErrorFrom("(.conj 0.0003 1)")
    expectInvalidArgumentErrorFrom("(.conj \\w 1)")
    expectInvalidArgumentErrorFrom("(.conj :w 1)")
    expectInvalidArgumentErrorFrom("(.conj 'w 1)")
    expectInvalidArgumentErrorFrom("(.conj \"foobar\" 1)")
    expectInvalidArgumentErrorFrom("(.conj .conj 1)")
  }

  /// .conj should require the second argument to be a two-item vector, if the first is a map.
  func testKeyValueVector() {
    expectInvalidArgumentErrorFrom("(.conj {} nil)")
    expectInvalidArgumentErrorFrom("(.conj {} true)")
    expectInvalidArgumentErrorFrom("(.conj {} false)")
    expectInvalidArgumentErrorFrom("(.conj {} 918)")
    expectInvalidArgumentErrorFrom("(.conj {} 1.11121)")
    expectInvalidArgumentErrorFrom("(.conj {} \\y)")
    expectInvalidArgumentErrorFrom("(.conj {} :y)")
    expectInvalidArgumentErrorFrom("(.conj {} 'y)")
    expectInvalidArgumentErrorFrom("(.conj {} \"foobar\")")
    expectInvalidArgumentErrorFrom("(.conj {} {:a 1})")
    expectInvalidArgumentErrorFrom("(.conj {} '(:a 2))")
    expectInvalidArgumentErrorFrom("(.conj {} [])")
    expectInvalidArgumentErrorFrom("(.conj {} [1])")
    expectInvalidArgumentErrorFrom("(.conj {} [:a 1 2])")
  }

  /// .conj should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.conj)")
    expectArityErrorFrom("(.conj nil)")
    expectArityErrorFrom("(.conj () 1 2)")
  }
}
