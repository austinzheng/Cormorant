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
    expectThat("(.cons nil nil)", shouldEvalTo: list(containing: .nilValue))
    expectThat("(.cons true nil)", shouldEvalTo: list(containing: .bool(true)))
    expectThat("(.cons 1 nil)", shouldEvalTo: list(containing: .int(1)))
    expectThat("(.cons () nil)", shouldEvalTo: list(containing: .seq(EmptyNode)))
    expectThat("(.cons {} nil)", shouldEvalTo: list(containing: .map([:])))
  }

  // .cons should produce a single-item list if the second item is an empty string.
  func testWithEmptyString() {
    expectThat("(.cons nil \"\")", shouldEvalTo: list(containing: .nilValue))
    expectThat("(.cons true \"\")", shouldEvalTo: list(containing: .bool(true)))
    expectThat("(.cons 1 \"\")", shouldEvalTo: list(containing: .int(1)))
    expectThat("(.cons () \"\")", shouldEvalTo: list(containing: .seq(EmptyNode)))
    expectThat("(.cons {} \"\")", shouldEvalTo: list(containing: .map([:])))
  }

  // .cons should produce a list with the first item and the characters of the second string argument.
  func testWithString() {
    expectThat("(.cons nil \"foo\")", shouldEvalTo: list(containing: .nilValue,
      .char("f"),
      .char("o"),
      .char("o")))
    expectThat("(.cons \"foo\" \"bard\")", shouldEvalTo: list(containing: .string("foo"),
      .char("b"),
      .char("a"),
      .char("r"), .char("d")))
  }

  // .cons should produce a single-item list if the second item is an empty list.
  func testWithEmptyList() {
    expectThat("(.cons nil ())", shouldEvalTo: list(containing: .nilValue))
    expectThat("(.cons true ())", shouldEvalTo: list(containing: .bool(true)))
    expectThat("(.cons 1 ())", shouldEvalTo: list(containing: .int(1)))
    expectThat("(.cons () ())", shouldEvalTo: list(containing: .seq(EmptyNode)))
    expectThat("(.cons {} ())", shouldEvalTo: list(containing: .map([:])))
  }

  // .cons should produce a list with the first item and the rest of the list.
  func testWithList() {
    let bar = keyword("bar")
    expectThat("(.cons 1.234 '(\"foo\" [1 2] true :bar))",
               shouldEvalTo: list(containing: 1.234, .string("foo"), vector(containing: 1, 2), true, .keyword(bar)))
    expectThat("(.cons '(1 2 3) '(4 5))",
               shouldEvalTo: list(containing: list(containing: 1, 2, 3), 4, 5))
  }

  /// .cons should produce a list with the first item and the lazy seq.
  func testWithEmptyLazySeq() {
    run(input: "(def a (.lazy-seq (fn [] (.print \"executed thunk\") nil)))")
    run(input: "(def b (.cons 10 a))")
    // Validate 'cons' worked by taking apart the list
    expectThat("(.first b)", shouldEvalTo: 10)
    expectEmptyOutputBuffer()
    expectThat("(.rest b)", shouldEvalTo: list())
    expectOutputBuffer(toBe: "executed thunk")
  }

  /// .cons should produce a list with the first item and an empty lazy seq.
  func testWithLazySeq() {
    run(input: "(def a (.lazy-seq (fn [] (.print \"executed thunk\") [0 1 2 3])))")
    run(input: "(def b (.cons 10 a))")
    // Validate 'cons' worked by taking apart the list
    expectThat("(.first b)", shouldEvalTo: 10)
    expectEmptyOutputBuffer()
    expectThat("(.rest b)", shouldEvalTo: list(containing: 0, 1, 2, 3))
    expectOutputBuffer(toBe: "executed thunk")
  }

  // .cons should produce a single-item list if the second item is an empty vector.
  func testWithEmptyVector() {
    expectThat("(.cons nil [])", shouldEvalTo: list(containing: .nilValue))
    expectThat("(.cons true [])", shouldEvalTo: list(containing: .bool(true)))
    expectThat("(.cons 1 [])", shouldEvalTo: list(containing: .int(1)))
    expectThat("(.cons () [])", shouldEvalTo: list(containing: .seq(EmptyNode)))
    expectThat("(.cons {} [])", shouldEvalTo: list(containing: .map([:])))
  }

  // .cons should produce a list with the first item and all items in the vector.
  func testWithVector() {
    let bar = symbol("bar")
    expectThat("(.cons \\newline [nil '(1 2) 'bar \\z])", shouldEvalTo:
      list(containing: .char("\n"), .nilValue, list(containing: 1, 2), .symbol(bar), .char("z")))
    expectThat("(.cons '[1 2 3] '[4 5])", shouldEvalTo:
      list(containing: vector(containing: 1, 2, 3), 4, 5))
  }

  // .cons should produce a single-item list if the second item is an empty list.
  func testWithEmptyMap() {
    expectThat("(.cons nil {})", shouldEvalTo: list(containing: .nilValue))
    expectThat("(.cons true {})", shouldEvalTo: list(containing: .bool(true)))
    expectThat("(.cons 1 {})", shouldEvalTo: list(containing: .int(1)))
    expectThat("(.cons () {})", shouldEvalTo: list(containing: .seq(EmptyNode)))
    expectThat("(.cons {} {})", shouldEvalTo: list(containing: .map([:])))
  }

  // .cons should produce a list with the first item and all key-value pairs in the map.
  func testWithMap() {
    let foo = symbol("foo")
    let bar = keyword("bar")
    expectThat("(.cons :bar {1 \"one\" 2 \"two\" 'foo \\5 100.1 nil})",
      shouldEvalToContain: .keyword(bar), vector(containing: 2, .string("two")),
      vector(containing: .symbol(foo), .char("5")), vector(containing: 1, .string("one")),
      vector(containing: 100.1, .nilValue))
    expectThat("(.cons {1 \"one\" 2 \"two\"} {3 \"three\" 4 \"four\" 5 \"five\"})",
      shouldEvalToContain: map(containing: (1, .string("one")), (2, .string("two"))),
      vector(containing: 5, .string("five")), vector(containing: 3, .string("three")),
      vector(containing: 4, .string("four")))
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
