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
    expectThat("(.first nil)", shouldEvalTo: .NilLiteral)
  }

  /// .first should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.first \"\")", shouldEvalTo: .NilLiteral)
    expectThat("(.first ())", shouldEvalTo: .NilLiteral)
    expectThat("(.first [])", shouldEvalTo: .NilLiteral)
    expectThat("(.first {})", shouldEvalTo: .NilLiteral)
  }

  /// .first should return the first character of a string.
  func testWithStrings() {
    expectThat("(.first \"a\")", shouldEvalTo: .CharacterLiteral("a"))
    expectThat("(.first \"foobar\")", shouldEvalTo: .CharacterLiteral("f"))
    expectThat("(.first \"\nthequickbrownfox\")", shouldEvalTo: .CharacterLiteral("\n"))
  }

  /// .first should return the first element of a list.
  func testWithLists() {
    expectThat("(.first '(true))", shouldEvalTo: .BoolLiteral(true))
    expectThat("(.first '(15 29 \"foo\" :bar nil))", shouldEvalTo: .IntegerLiteral(15))
    expectThat("(.first '((1 2 3) 4 5))", shouldEvalTo:
      listWithItems(.IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3)))
  }

  /// .first should return the first element of a vector.
  func testWithVectors() {
    expectThat("(.first [false])", shouldEvalTo: .BoolLiteral(false))
    expectThat("(.first [29981.1 \"foo\" :bar nil])", shouldEvalTo: .FloatLiteral(29981.1))
    expectThat("(.first [[1 2 3] 4 5])", shouldEvalTo:
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3)))
  }

  /// .first should return the first element of a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    expectThat("(.first {:a 1})", shouldEvalTo: vectorWithItems(.Keyword(a), .IntegerLiteral(1)))
    expectThat("(.first {:a 1 :b 2 \\c 3})", shouldEvalTo: vectorWithItems(.Keyword(b), .IntegerLiteral(2)))
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
