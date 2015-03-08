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
    expectThat("(.cons nil nil)", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true nil)", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 nil)", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons '() nil)", shouldEvalTo: listWithItems(ConsValue.List(Empty())))
    expectThat("(.cons {} nil)", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a single-item list if the second item is an empty string.
  func testWithEmptyString() {
    expectThat("(.cons nil \"\")", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true \"\")", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 \"\")", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons '() \"\")", shouldEvalTo: listWithItems(ConsValue.List(Empty())))
    expectThat("(.cons {} \"\")", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a list with the first item and the characters of the second string argument.
  func testWithString() {
    expectThat("(.cons nil \"foo\")", shouldEvalTo: listWithItems(
      .Nil,
      .CharAtom("f"),
      .CharAtom("o"),
      .CharAtom("o")))
    expectThat("(.cons \"foo\" \"bard\")", shouldEvalTo: listWithItems(
      .StringAtom("foo"),
      .CharAtom("b"),
      .CharAtom("a"),
      .CharAtom("r"), .CharAtom("d")))
  }

  // .cons should produce a single-item list if the second item is an empty list.
  func testWithEmptyList() {
    expectThat("(.cons nil ())", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true ())", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 ())", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons '() ())", shouldEvalTo: listWithItems(ConsValue.List(Empty())))
    expectThat("(.cons {} ())", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a list with the first item and the rest of the list.
  func testWithList() {
    let bar = interpreter.context.keywordForName("bar")
    expectThat("(.cons 1.234 '(\"foo\" [1 2] true :bar))", shouldEvalTo:
      listWithItems(1.234, .StringAtom("foo"), vectorWithItems(1, 2), true, .Keyword(bar)))
    expectThat("(.cons '(1 2 3) '(4 5))", shouldEvalTo: listWithItems(listWithItems(1, 2, 3), 4, 5))
  }

  // .cons should produce a single-item list if the second item is an empty vector.
  func testWithEmptyVector() {
    expectThat("(.cons nil [])", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true [])", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 [])", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons '() [])", shouldEvalTo: listWithItems(ConsValue.List(Empty())))
    expectThat("(.cons {} [])", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a list with the first item and all items in the vector.
  func testWithVector() {
    let bar = interpreter.context.symbolForName("bar")
    expectThat("(.cons \\newline [nil '(1 2) 'bar \\z])", shouldEvalTo:
      listWithItems(.CharAtom("\n"), .Nil, listWithItems(1, 2), .Symbol(bar), .CharAtom("z")))
    expectThat("(.cons '[1 2 3] '[4 5])", shouldEvalTo:
      listWithItems(vectorWithItems(1, 2, 3), 4, 5))
  }

  // .cons should produce a single-item list if the second item is an empty list.
  func testWithEmptyMap() {
    expectThat("(.cons nil {})", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true {})", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 {})", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons '() {})", shouldEvalTo: listWithItems(ConsValue.List(Empty())))
    expectThat("(.cons {} {})", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a list with the first item and all key-value pairs in the map.
  func testWithMap() {
    let foo = interpreter.context.symbolForName("foo")
    let bar = interpreter.context.keywordForName("bar")
    expectThat("(.cons :bar {1 \"one\" 2 \"two\" 'foo \\5 100.1 nil})", shouldEvalTo:
      listWithItems(.Keyword(bar), vectorWithItems(2, .StringAtom("two")), vectorWithItems(100.1, .Nil),
        vectorWithItems(.Symbol(foo), .CharAtom("5")), vectorWithItems(1, .StringAtom("one"))))
    expectThat("(.cons {1 \"one\" 2 \"two\"} {3 \"three\" 4 \"four\" 5 \"five\"})", shouldEvalTo:
      listWithItems(mapWithItems((1, .StringAtom("one")), (2, .StringAtom("two"))),
        vectorWithItems(5, .StringAtom("five")), vectorWithItems(3, .StringAtom("three")),
        vectorWithItems(4, .StringAtom("four"))))
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
