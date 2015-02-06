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
    expectThat("(.seq '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(
      .BoolAtom(true), .BoolAtom(false), .Nil, .IntAtom(1), .FloatAtom(2.1), .IntAtom(3)))
    expectThat("(.seq '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo: listWithItems(
      listWithItems(.IntAtom(1), .IntAtom(2)),
      listWithItems(.IntAtom(3), .IntAtom(4)),
      listWithItems(.IntAtom(5), .IntAtom(6)),
      listWithItems(.IntAtom(7), .IntAtom(8)),
      listWithItems()))
  }

  /// .seq should return a sequence comprised of the elements in a vector.
  func testWithVectors() {
    expectThat("(.seq [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(
      .BoolAtom(false), .BoolAtom(true), .Nil, .IntAtom(1), .FloatAtom(2.1), .IntAtom(3)))
    expectThat("(.seq [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo: listWithItems(
      vectorWithItems(.IntAtom(1), .IntAtom(2)),
      vectorWithItems(.IntAtom(3), .IntAtom(4)),
      vectorWithItems(.IntAtom(5), .IntAtom(6)),
      vectorWithItems(.IntAtom(7), .IntAtom(8)),
      vectorWithItems()))
  }

  /// .seq should return a sequence comprised of the key-value pairs in a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    expectThat("(.seq {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.Keyword(b), .IntAtom(2)),
      vectorWithItems(.Keyword(c), .IntAtom(3)),
      vectorWithItems(.Keyword(a), .IntAtom(1)),
      vectorWithItems(.CharAtom("d"), .IntAtom(4))))
    expectThat("(.seq {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo: listWithItems(
      vectorWithItems(.Nil, .StringAtom("baz")),
      vectorWithItems(.BoolAtom(true), .StringAtom("bar")),
      vectorWithItems(.StringAtom("foo"), .CharAtom("a"))))
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
