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
    expectThat("(.first '(true))", shouldEvalTo: .BoolAtom(true))
    expectThat("(.first '(15 29 \"foo\" :bar nil))", shouldEvalTo: .IntAtom(15))
    expectThat("(.first '((1 2 3) 4 5))", shouldEvalTo:
      listWithItems(.IntAtom(1), .IntAtom(2), .IntAtom(3)))
  }

  /// .first should return the first element of a vector.
  func testWithVectors() {
    expectThat("(.first [false])", shouldEvalTo: .BoolAtom(false))
    expectThat("(.first [29981.1 \"foo\" :bar nil])", shouldEvalTo: .FloatAtom(29981.1))
    expectThat("(.first [[1 2 3] 4 5])", shouldEvalTo:
      vectorWithItems(.IntAtom(1), .IntAtom(2), .IntAtom(3)))
  }

  /// .first should return the first element of a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    expectThat("(.first {:a 1})", shouldEvalTo: vectorWithItems(.Keyword(a), .IntAtom(1)))
    expectThat("(.first {:a 1 :b 2 \\c 3})", shouldEvalTo: vectorWithItems(.Keyword(b), .IntAtom(2)))
  }

  /// .first should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectThat("(.first true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.first false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.first 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.first 3.141592)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.first :foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.first 'foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.first \\f)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.first .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .first should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.first)")
    expectArityErrorFrom("(.first nil nil)")
  }
}
