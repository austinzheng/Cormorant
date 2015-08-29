//
//  TestCons.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

class TestConsBuiltin : InterpreterTest {

  // .cons should produce a single-item list if the second argument is nil.
  func testWithNilCollection() {
    expectThat("(.cons nil nil)", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true nil)", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 nil)", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons () nil)", shouldEvalTo: listWithItems(ConsValue.Seq(EmptyNode)))
    expectThat("(.cons {} nil)", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a single-item list if the second item is an empty string.
  func testWithEmptyString() {
    expectThat("(.cons nil \"\")", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true \"\")", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 \"\")", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons () \"\")", shouldEvalTo: listWithItems(ConsValue.Seq(EmptyNode)))
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
    expectThat("(.cons () ())", shouldEvalTo: listWithItems(ConsValue.Seq(EmptyNode)))
    expectThat("(.cons {} ())", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a list with the first item and the rest of the list.
  func testWithList() {
    let bar = keyword("bar")
    expectThat("(.cons 1.234 '(\"foo\" [1 2] true :bar))", shouldEvalTo:
      listWithItems(1.234, .StringAtom("foo"), vectorWithItems(1, 2), true, .Keyword(bar)))
    expectThat("(.cons '(1 2 3) '(4 5))", shouldEvalTo: listWithItems(listWithItems(1, 2, 3), 4, 5))
  }

  /// .cons should produce a list with the first item and the lazy seq.
  func testWithEmptyLazySeq() {
    runCode("(def a (.lazy-seq (fn [] (.print \"executed thunk\") nil)))")
    runCode("(def b (.cons 10 a))")
    // Validate 'cons' worked by taking apart the list
    expectThat("(.first b)", shouldEvalTo: 10)
    expectEmptyOutputBuffer()
    expectThat("(.rest b)", shouldEvalTo: listWithItems())
    expectOutputBuffer(toBe: "executed thunk")
  }

  /// .cons should produce a list with the first item and an empty lazy seq.
  func testWithLazySeq() {
    runCode("(def a (.lazy-seq (fn [] (.print \"executed thunk\") [0 1 2 3])))")
    runCode("(def b (.cons 10 a))")
    // Validate 'cons' worked by taking apart the list
    expectThat("(.first b)", shouldEvalTo: 10)
    expectEmptyOutputBuffer()
    expectThat("(.rest b)", shouldEvalTo: listWithItems(0, 1, 2, 3))
    expectOutputBuffer(toBe: "executed thunk")
  }

  // .cons should produce a single-item list if the second item is an empty vector.
  func testWithEmptyVector() {
    expectThat("(.cons nil [])", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.cons true [])", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.cons 1 [])", shouldEvalTo: listWithItems(ConsValue.IntAtom(1)))
    expectThat("(.cons () [])", shouldEvalTo: listWithItems(ConsValue.Seq(EmptyNode)))
    expectThat("(.cons {} [])", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a list with the first item and all items in the vector.
  func testWithVector() {
    let bar = symbol("bar")
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
    expectThat("(.cons () {})", shouldEvalTo: listWithItems(ConsValue.Seq(EmptyNode)))
    expectThat("(.cons {} {})", shouldEvalTo: listWithItems(ConsValue.Map([:])))
  }

  // .cons should produce a list with the first item and all key-value pairs in the map.
  func testWithMap() {
    let foo = symbol("foo")
    let bar = keyword("bar")
    expectThat("(.cons :bar {1 \"one\" 2 \"two\" 'foo \\5 100.1 nil})",
      shouldEvalToContain: .Keyword(bar), vectorWithItems(2, .StringAtom("two")),
      vectorWithItems(.Symbol(foo), .CharAtom("5")), vectorWithItems(1, .StringAtom("one")),
      vectorWithItems(100.1, .Nil))
    expectThat("(.cons {1 \"one\" 2 \"two\"} {3 \"three\" 4 \"four\" 5 \"five\"})",
      shouldEvalToContain: mapWithItems((1, .StringAtom("one")), (2, .StringAtom("two"))),
      vectorWithItems(5, .StringAtom("five")), vectorWithItems(3, .StringAtom("three")),
      vectorWithItems(4, .StringAtom("four")))
  }

  // .cons should reject invalid collection types.
  func testWithInvalidTypes() {
    expectInvalidArgumentErrorFrom("(.cons 1 true)")
    expectInvalidArgumentErrorFrom("(.cons 1 false)")
    expectInvalidArgumentErrorFrom("(.cons 1 100)")
    expectInvalidArgumentErrorFrom("(.cons 1 \\a)")
    expectInvalidArgumentErrorFrom("(.cons 1 :foo)")
    expectInvalidArgumentErrorFrom("(.cons 1 'foo)")
    expectInvalidArgumentErrorFrom("(.cons 1 (fn [] nil))")
  }

  // .cons should take exactly 2 arguments.
  func testArity() {
    expectArityErrorFrom("(.cons)")
    expectArityErrorFrom("(.cons nil)")
    expectArityErrorFrom("(.cons nil nil nil)")
  }
}
