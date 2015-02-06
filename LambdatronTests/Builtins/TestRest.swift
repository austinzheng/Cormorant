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
    expectThat("(.rest nil)", shouldEvalTo: .List(Empty()))
  }

  /// .rest should return the empty list for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.rest \"\")", shouldEvalTo: .List(Empty()))
    expectThat("(.rest ())", shouldEvalTo: .List(Empty()))
    expectThat("(.rest [])", shouldEvalTo: .List(Empty()))
    expectThat("(.rest {})", shouldEvalTo: .List(Empty()))
  }

  /// .rest should return the empty list for single-element collections.
  func testWithOneElement() {
    expectThat("(.rest \"a\")", shouldEvalTo: .List(Empty()))
    expectThat("(.rest '(:a))", shouldEvalTo: .List(Empty()))
    expectThat("(.rest [\\a])", shouldEvalTo: .List(Empty()))
    expectThat("(.rest {'a 10})", shouldEvalTo: .List(Empty()))
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
    expectThat("(.rest '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(
      .BoolAtom(false), .Nil, .IntAtom(1), .FloatAtom(2.1), .IntAtom(3)))
    expectThat("(.rest '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo: listWithItems(
      listWithItems(.IntAtom(3), .IntAtom(4)),
      listWithItems(.IntAtom(5), .IntAtom(6)),
      listWithItems(.IntAtom(7), .IntAtom(8)),
      listWithItems()))
  }

  /// .rest should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.rest [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(
      .BoolAtom(true), .Nil, .IntAtom(1), .FloatAtom(2.1), .IntAtom(3)))
    expectThat("(.rest [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo: listWithItems(
      vectorWithItems(.IntAtom(3), .IntAtom(4)),
      vectorWithItems(.IntAtom(5), .IntAtom(6)),
      vectorWithItems(.IntAtom(7), .IntAtom(8)),
      vectorWithItems()))
  }

  /// .rest should return a sequence comprised of the rest of the key-value pairs in a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    expectThat("(.rest {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.Keyword(c), .IntAtom(3)),
      vectorWithItems(.Keyword(a), .IntAtom(1)),
      vectorWithItems(.CharAtom("d"), .IntAtom(4))))
    expectThat("(.rest {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo: listWithItems(
      vectorWithItems(.BoolAtom(true), .StringAtom("bar")),
      vectorWithItems(.StringAtom("foo"), .CharAtom("a"))))
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
