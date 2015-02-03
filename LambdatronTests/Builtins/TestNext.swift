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
    expectThat("(.next nil)", shouldEvalTo: .NilLiteral)
  }

  /// .next should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.next \"\")", shouldEvalTo: .NilLiteral)
    expectThat("(.next ())", shouldEvalTo: .NilLiteral)
    expectThat("(.next [])", shouldEvalTo: .NilLiteral)
    expectThat("(.next {})", shouldEvalTo: .NilLiteral)
  }

  /// .next should return nil for single-element collections.
  func testWithOneElement() {
    expectThat("(.next \"a\")", shouldEvalTo: .NilLiteral)
    expectThat("(.next '(:a))", shouldEvalTo: .NilLiteral)
    expectThat("(.next [\\a])", shouldEvalTo: .NilLiteral)
    expectThat("(.next {'a 10})", shouldEvalTo: .NilLiteral)
  }

  /// .next should return a sequence comprised of the rest of the characters of a string.
  func testWithStrings() {
    expectThat("(.next \"abc\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("b"), .CharacterLiteral("c")))
    expectThat("(.next \"\\n\\\\\nq\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("\\"), .CharacterLiteral("\n"), .CharacterLiteral("q")))
    expectThat("(.next \"foobar\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("o"), .CharacterLiteral("o"), .CharacterLiteral("b"),
        .CharacterLiteral("a"), .CharacterLiteral("r")))
  }

  /// .next should return a sequence comprised of the rest of the elements in a list.
  func testWithLists() {
    expectThat("(.next '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(
      .BoolLiteral(false), .NilLiteral, .IntegerLiteral(1), .FloatLiteral(2.1), .IntegerLiteral(3)))
    expectThat("(.next '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo: listWithItems(
      listWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      listWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      listWithItems(.IntegerLiteral(7), .IntegerLiteral(8)),
      listWithItems()))
  }

  /// .next should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.next [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(
      .BoolLiteral(true), .NilLiteral, .IntegerLiteral(1), .FloatLiteral(2.1), .IntegerLiteral(3)))
    expectThat("(.next [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      vectorWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      vectorWithItems(.IntegerLiteral(7), .IntegerLiteral(8)),
      vectorWithItems()))
  }

  /// .next should return a sequence comprised of the rest of the key-value pairs in a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    expectThat("(.next {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.Keyword(c), .IntegerLiteral(3)),
      vectorWithItems(.Keyword(a), .IntegerLiteral(1)),
      vectorWithItems(.CharacterLiteral("d"), .IntegerLiteral(4))))
    expectThat("(.next {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo: listWithItems(
      vectorWithItems(.BoolLiteral(true), .StringLiteral("bar")),
      vectorWithItems(.StringLiteral("foo"), .CharacterLiteral("a"))))
  }

  /// .next should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectThat("(.next true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.next false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.next 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.next 3.141592)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.next :foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.next 'foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.next \\f)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.next .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .next should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.next)")
    expectArityErrorFrom("(.next nil nil)")
  }
}
