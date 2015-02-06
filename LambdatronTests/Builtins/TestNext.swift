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
    expectThat("(.next nil)", shouldEvalTo: .Nil)
  }

  /// .next should return nil for empty collections.
  func testWithEmptyCollections() {
    expectThat("(.next \"\")", shouldEvalTo: .Nil)
    expectThat("(.next ())", shouldEvalTo: .Nil)
    expectThat("(.next [])", shouldEvalTo: .Nil)
    expectThat("(.next {})", shouldEvalTo: .Nil)
  }

  /// .next should return nil for single-element collections.
  func testWithOneElement() {
    expectThat("(.next \"a\")", shouldEvalTo: .Nil)
    expectThat("(.next '(:a))", shouldEvalTo: .Nil)
    expectThat("(.next [\\a])", shouldEvalTo: .Nil)
    expectThat("(.next {'a 10})", shouldEvalTo: .Nil)
  }

  /// .next should return a sequence comprised of the rest of the characters of a string.
  func testWithStrings() {
    expectThat("(.next \"abc\")",
      shouldEvalTo: listWithItems(.CharAtom("b"), .CharAtom("c")))
    expectThat("(.next \"\\n\\\\\nq\")",
      shouldEvalTo: listWithItems(.CharAtom("\\"), .CharAtom("\n"), .CharAtom("q")))
    expectThat("(.next \"foobar\")",
      shouldEvalTo: listWithItems(.CharAtom("o"), .CharAtom("o"), .CharAtom("b"),
        .CharAtom("a"), .CharAtom("r")))
  }

  /// .next should return a sequence comprised of the rest of the elements in a list.
  func testWithLists() {
    expectThat("(.next '(true false nil 1 2.1 3))", shouldEvalTo: listWithItems(
      .BoolAtom(false), .Nil, .IntAtom(1), .FloatAtom(2.1), .IntAtom(3)))
    expectThat("(.next '((1 2) (3 4) (5 6) (7 8) ()))", shouldEvalTo: listWithItems(
      listWithItems(.IntAtom(3), .IntAtom(4)),
      listWithItems(.IntAtom(5), .IntAtom(6)),
      listWithItems(.IntAtom(7), .IntAtom(8)),
      listWithItems()))
  }

  /// .next should return a sequence comprised of the rest of the elements in a vector.
  func testWithVectors() {
    expectThat("(.next [false true nil 1 2.1 3])", shouldEvalTo: listWithItems(
      .BoolAtom(true), .Nil, .IntAtom(1), .FloatAtom(2.1), .IntAtom(3)))
    expectThat("(.next [[1 2] [3 4] [5 6] [7 8] []])", shouldEvalTo: listWithItems(
      vectorWithItems(.IntAtom(3), .IntAtom(4)),
      vectorWithItems(.IntAtom(5), .IntAtom(6)),
      vectorWithItems(.IntAtom(7), .IntAtom(8)),
      vectorWithItems()))
  }

  /// .next should return a sequence comprised of the rest of the key-value pairs in a map.
  func testWithMaps() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    expectThat("(.next {:a 1 :b 2 :c 3 \\d 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.Keyword(c), .IntAtom(3)),
      vectorWithItems(.Keyword(a), .IntAtom(1)),
      vectorWithItems(.CharAtom("d"), .IntAtom(4))))
    expectThat("(.next {\"foo\" \\a nil \"baz\" true \"bar\"})", shouldEvalTo: listWithItems(
      vectorWithItems(.BoolAtom(true), .StringAtom("bar")),
      vectorWithItems(.StringAtom("foo"), .CharAtom("a"))))
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
