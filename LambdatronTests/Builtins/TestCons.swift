//
//  TestCons.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestConsBuiltin : InterpreterTest {

  // .cons should produce a single-item list if the second argument is nil.
  func testWithNilCollection() {
    expectThat("(.cons nil nil)", shouldEvalTo: listWithItems(ConsValue.NilLiteral))
    expectThat("(.cons true nil)", shouldEvalTo: listWithItems(ConsValue.BoolLiteral(true)))
    expectThat("(.cons 1 nil)", shouldEvalTo: listWithItems(ConsValue.IntegerLiteral(1)))
    expectThat("(.cons '() nil)", shouldEvalTo: listWithItems(ConsValue.ListLiteral(Cons())))
    expectThat("(.cons {} nil)", shouldEvalTo: listWithItems(ConsValue.MapLiteral([:])))
  }

  // .cons should produce a single-item list if the second item is an empty string.
  func testWithEmptyString() {
    expectThat("(.cons nil \"\")", shouldEvalTo: listWithItems(ConsValue.NilLiteral))
    expectThat("(.cons true \"\")", shouldEvalTo: listWithItems(ConsValue.BoolLiteral(true)))
    expectThat("(.cons 1 \"\")", shouldEvalTo: listWithItems(ConsValue.IntegerLiteral(1)))
    expectThat("(.cons '() \"\")", shouldEvalTo: listWithItems(ConsValue.ListLiteral(Cons())))
    expectThat("(.cons {} \"\")", shouldEvalTo: listWithItems(ConsValue.MapLiteral([:])))
  }

  // .cons should produce a list with the first item and the characters of the second string argument.
  func testWithString() {
    expectThat("(.cons nil \"foo\")", shouldEvalTo: listWithItems(
      .NilLiteral,
      .CharacterLiteral("f"),
      .CharacterLiteral("o"),
      .CharacterLiteral("o")))
    expectThat("(.cons \"foo\" \"bard\")", shouldEvalTo: listWithItems(
      .StringLiteral("foo"),
      .CharacterLiteral("b"),
      .CharacterLiteral("a"),
      .CharacterLiteral("r"), .CharacterLiteral("d")))
  }

  // .cons should produce a single-item list if the second item is an empty list.
  func testWithEmptyList() {
    expectThat("(.cons nil ())", shouldEvalTo: listWithItems(ConsValue.NilLiteral))
    expectThat("(.cons true ())", shouldEvalTo: listWithItems(ConsValue.BoolLiteral(true)))
    expectThat("(.cons 1 ())", shouldEvalTo: listWithItems(ConsValue.IntegerLiteral(1)))
    expectThat("(.cons '() ())", shouldEvalTo: listWithItems(ConsValue.ListLiteral(Cons())))
    expectThat("(.cons {} ())", shouldEvalTo: listWithItems(ConsValue.MapLiteral([:])))
  }

  // .cons should produce a list with the first item and the rest of the list.
  func testWithList() {
    let bar = interpreter.context.keywordForName("bar")
    expectThat("(.cons 1.234 '(\"foo\" [1 2] true :bar))", shouldEvalTo: listWithItems(
      .FloatLiteral(1.234),
      .StringLiteral("foo"),
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      .BoolLiteral(true),
      .Keyword(bar)))
    expectThat("(.cons '(1 2 3) '(4 5))", shouldEvalTo: listWithItems(
      listWithItems(.IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3)),
      .IntegerLiteral(4),
      .IntegerLiteral(5)))
  }

  // .cons should produce a single-item list if the second item is an empty vector.
  func testWithEmptyVector() {
    expectThat("(.cons nil [])", shouldEvalTo: listWithItems(ConsValue.NilLiteral))
    expectThat("(.cons true [])", shouldEvalTo: listWithItems(ConsValue.BoolLiteral(true)))
    expectThat("(.cons 1 [])", shouldEvalTo: listWithItems(ConsValue.IntegerLiteral(1)))
    expectThat("(.cons '() [])", shouldEvalTo: listWithItems(ConsValue.ListLiteral(Cons())))
    expectThat("(.cons {} [])", shouldEvalTo: listWithItems(ConsValue.MapLiteral([:])))
  }

  // .cons should produce a list with the first item and all items in the vector.
  func testWithVector() {
    let bar = interpreter.context.symbolForName("bar")
    expectThat("(.cons \\newline [nil '(1 2) 'bar \\z])", shouldEvalTo: listWithItems(
      .CharacterLiteral("\n"),
      .NilLiteral,
      listWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      .Symbol(bar),
      .CharacterLiteral("z")))
    expectThat("(.cons '[1 2 3] '[4 5])", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3)),
      .IntegerLiteral(4),
      .IntegerLiteral(5)))
  }

  // .cons should produce a single-item list if the second item is an empty list.
  func testWithEmptyMap() {
    expectThat("(.cons nil {})", shouldEvalTo: listWithItems(ConsValue.NilLiteral))
    expectThat("(.cons true {})", shouldEvalTo: listWithItems(ConsValue.BoolLiteral(true)))
    expectThat("(.cons 1 {})", shouldEvalTo: listWithItems(ConsValue.IntegerLiteral(1)))
    expectThat("(.cons '() {})", shouldEvalTo: listWithItems(ConsValue.ListLiteral(Cons())))
    expectThat("(.cons {} {})", shouldEvalTo: listWithItems(ConsValue.MapLiteral([:])))
  }

  // .cons should produce a list with the first item and all key-value pairs in the map.
  func testWithMap() {
    let foo = interpreter.context.symbolForName("foo")
    let bar = interpreter.context.keywordForName("bar")
    expectThat("(.cons :bar {1 \"one\" 2 \"two\" 'foo \\5 100.1 nil})", shouldEvalTo: listWithItems(
      .Keyword(bar),
      vectorWithItems(.IntegerLiteral(2), .StringLiteral("two")),
      vectorWithItems(.FloatLiteral(100.1), .NilLiteral),
      vectorWithItems(.Symbol(foo), .CharacterLiteral("5")),
    vectorWithItems(.IntegerLiteral(1), .StringLiteral("one"))))
    expectThat("(.cons {1 \"one\" 2 \"two\"} {3 \"three\" 4 \"four\" 5 \"five\"})", shouldEvalTo: listWithItems(
      mapWithItems((.IntegerLiteral(1), .StringLiteral("one")), (.IntegerLiteral(2), .StringLiteral("two"))),
      vectorWithItems(.IntegerLiteral(5), .StringLiteral("five")),
      vectorWithItems(.IntegerLiteral(3), .StringLiteral("three")),
      vectorWithItems(.IntegerLiteral(4), .StringLiteral("four"))))
  }

  // .cons should reject invalid collection types.
  func testWithInvalidTypes() {
    expectThat("(.cons 1 true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.cons 1 false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.cons 1 100)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.cons 1 \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.cons 1 :foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.cons 1 'foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.cons 1 (fn [] nil))", shouldFailAs: .InvalidArgumentError)
  }

  // .cons should take exactly 2 arguments.
  func testArity() {
    expectArityErrorFrom("(.cons)")
    expectArityErrorFrom("(.cons nil)")
    expectArityErrorFrom("(.cons nil nil nil)")
  }
}
