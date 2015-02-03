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
    expectThat("(.seq nil)", shouldEvalTo: .NilLiteral)
  }

  /// .seq should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.seq \"\")", shouldEvalTo: .NilLiteral)
    expectThat("(.seq ())", shouldEvalTo: .NilLiteral)
    expectThat("(.seq [])", shouldEvalTo: .NilLiteral)
    expectThat("(.seq {})", shouldEvalTo: .NilLiteral)
  }

  /// .seq should return a sequence comprised of the characters of a string.
  func testWithStrings() {
    expectThat("(.seq \"abc\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("a"), .CharacterLiteral("b"), .CharacterLiteral("c")))
    expectThat("(.seq \"\\n\\\\\nq\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("\n"), .CharacterLiteral("\\"), .CharacterLiteral("\n"),
        .CharacterLiteral("q")))
    expectThat("(.seq \"foobar\")",
      shouldEvalTo: listWithItems(.CharacterLiteral("f"), .CharacterLiteral("o"), .CharacterLiteral("o"),
        .CharacterLiteral("b"), .CharacterLiteral("a"), .CharacterLiteral("r")))
  }

  /// .seq should return a sequence comprised of the elements in a list.
  func testWithLists() {
    expectThat("(.seq '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(
      .BoolLiteral(true), .BoolLiteral(false), .NilLiteral, .IntegerLiteral(1), .FloatLiteral(2.1), .IntegerLiteral(3)))
    expectThat("(.seq '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo: listWithItems(
      listWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      listWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      listWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      listWithItems(.IntegerLiteral(7), .IntegerLiteral(8)),
      listWithItems()))
  }

  /// .seq should return a sequence comprised of the elements in a vector.
  func testWithVectors() {
    expectThat("(.seq [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(
      .BoolLiteral(false), .BoolLiteral(true), .NilLiteral, .IntegerLiteral(1), .FloatLiteral(2.1), .IntegerLiteral(3)))
    expectThat("(.seq [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      vectorWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      vectorWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      vectorWithItems(.IntegerLiteral(7), .IntegerLiteral(8)),
      vectorWithItems()))
  }

  /// .seq should return a sequence comprised of the key-value pairs in a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    expectThat("(.seq {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.Keyword(b), .IntegerLiteral(2)),
      vectorWithItems(.Keyword(c), .IntegerLiteral(3)),
      vectorWithItems(.Keyword(a), .IntegerLiteral(1)),
      vectorWithItems(.CharacterLiteral("d"), .IntegerLiteral(4))))
    expectThat("(.seq {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo: listWithItems(
      vectorWithItems(.NilLiteral, .StringLiteral("baz")),
      vectorWithItems(.BoolLiteral(true), .StringLiteral("bar")),
      vectorWithItems(.StringLiteral("foo"), .CharacterLiteral("a"))))
  }

  /// .seq should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectThat("(.seq true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.seq false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.seq 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.seq 3.141592)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.seq :foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.seq 'foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.seq \\f)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.seq .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .seq should only take one argument.
  func testArity() {
    expectArityErrorFrom("(.seq)")
    expectArityErrorFrom("(.seq nil nil)")
  }
}
