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
    expectThat("(.rest nil)", shouldEvalTo: .ListLiteral(Cons()))
  }

  /// .rest should return the empty list for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.rest \"\")", shouldEvalTo: .ListLiteral(Cons()))
    expectThat("(.rest ())", shouldEvalTo: .ListLiteral(Cons()))
    expectThat("(.rest [])", shouldEvalTo: .ListLiteral(Cons()))
    expectThat("(.rest {})", shouldEvalTo: .ListLiteral(Cons()))
  }

  /// .rest should return the empty list for single-element collections.
  func testWithOneElement() {
    expectThat("(.rest \"a\")", shouldEvalTo: .ListLiteral(Cons()))
    expectThat("(.rest '(:a))", shouldEvalTo: .ListLiteral(Cons()))
    expectThat("(.rest [\\a])", shouldEvalTo: .ListLiteral(Cons()))
    expectThat("(.rest {'a 10})", shouldEvalTo: .ListLiteral(Cons()))
  }

  /// .rest should return a sequence comprised of the rest of the characters of a string.
  func testWithStrings() {
    expectThat("(.rest \"abc\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("b"), .CharacterLiteral("c")))
    expectThat("(.rest \"\\n\\\\\nq\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("\\"), .CharacterLiteral("\n"), .CharacterLiteral("q")))
    expectThat("(.rest \"foobar\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("o"), .CharacterLiteral("o"), .CharacterLiteral("b"),
        .CharacterLiteral("a"), .CharacterLiteral("r")))
  }

  /// .rest should return a sequence comprised of the rest of the elements in a list.
  func testWithLists() {
    expectThat("(.rest '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(
      .BoolLiteral(false), .NilLiteral, .IntegerLiteral(1), .FloatLiteral(2.1), .IntegerLiteral(3)))
    expectThat("(.rest '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo: listWithItems(
      listWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      listWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      listWithItems(.IntegerLiteral(7), .IntegerLiteral(8)),
      listWithItems()))
  }

  /// .rest should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.rest [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(
      .BoolLiteral(true), .NilLiteral, .IntegerLiteral(1), .FloatLiteral(2.1), .IntegerLiteral(3)))
    expectThat("(.rest [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      vectorWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      vectorWithItems(.IntegerLiteral(7), .IntegerLiteral(8)),
      vectorWithItems()))
  }

  /// .rest should return a sequence comprised of the rest of the key-value pairs in a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    expectThat("(.rest {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.Keyword(c), .IntegerLiteral(3)),
      vectorWithItems(.Keyword(a), .IntegerLiteral(1)),
      vectorWithItems(.CharacterLiteral("d"), .IntegerLiteral(4))))
    expectThat("(.rest {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo: listWithItems(
      vectorWithItems(.BoolLiteral(true), .StringLiteral("bar")),
      vectorWithItems(.StringLiteral("foo"), .CharacterLiteral("a"))))
  }

  /// .rest should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectThat("(.rest true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.rest false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.rest 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.rest 3.141592)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.rest :foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.rest 'foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.rest \\f)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.rest .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .rest should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.rest)")
    expectArityErrorFrom("(.rest nil nil)")
  }
}
