//
//  TestReadString.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/15/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

/// Test the '.read-string' built-in function.
class TestReadStringBuiltin : InterpreterTest {

  private func expectInputToReadString(input: String, toEvalTo result: ConsValue) {
    return expectThat("(.read-string \"\(input)\")", shouldEvalTo: result)
  }

  /// .read-string should properly read in literal keywords.
  func testLiteralKeywords() {
    expectInputToReadString("nil", toEvalTo: .Nil)
    expectInputToReadString("true", toEvalTo: true)
    expectInputToReadString("false", toEvalTo: false)
  }

  /// .read-string should properly read in numbers.
  func testWithNumbers() {
    expectInputToReadString("0", toEvalTo: 0)
    expectInputToReadString("3.141592", toEvalTo: 3.141592)
    expectInputToReadString("-928187859291", toEvalTo: -928187859291)
  }

  /// .read-string should properly read in symbols.
  func testWithSymbols() {
    let fooSymbol = symbol("foo")
    let barSymbol = symbol("bar")
    let fqFoo = symbol("foo", namespace: "meela")
    expectInputToReadString("foo", toEvalTo: .Symbol(fooSymbol))
    expectInputToReadString("bar", toEvalTo: .Symbol(barSymbol))
    expectInputToReadString("meela/foo", toEvalTo: .Symbol(fqFoo))
  }

  /// .read-string should properly read in keywords.
  func testWithKeywords() {
    let fooKeyword = keyword("foo")
    let barKeyword = keyword("bar")
    let fqFoo = keyword("foo", namespace: "meela")
    expectInputToReadString(":foo", toEvalTo: .Keyword(fooKeyword))
    expectInputToReadString(":bar", toEvalTo: .Keyword(barKeyword))
    expectInputToReadString(":meela/foo", toEvalTo: .Keyword(fqFoo))
  }

  /// .read-string should properly read in character literals.
  func testWithCharacters() {
    expectInputToReadString("\\\\a", toEvalTo: .CharAtom("a"))
    expectInputToReadString("\\\\newline", toEvalTo: .CharAtom("\n"))
  }

  /// .read-string should properly read in strings.
  func testWithStrings() {
    expectInputToReadString("\\\"\\\"", toEvalTo: .StringAtom(""))
    expectInputToReadString("\\\"hello world\\\"", toEvalTo: .StringAtom("hello world"))
  }

  /// .read-string should properly read in lists.
  func testWithLists() {
    let fooSymbol = symbol("foo")
    expectInputToReadString("()", toEvalTo: listWithItems())
    expectInputToReadString("(1 2 3 4)", toEvalTo: listWithItems(1, 2, 3, 4))
    expectInputToReadString("(foo [1 2] \\\"three\\\" 4)",
      toEvalTo: listWithItems(.Symbol(fooSymbol), vectorWithItems(1, 2), .StringAtom("three"), 4))
  }

  /// .read-string should properly read in vectors.
  func testWithVectors() {
    expectInputToReadString("[]", toEvalTo: vectorWithItems())
    expectInputToReadString("[[[1 2] 3] [4 [5] [6]] 7]", toEvalTo:
      vectorWithItems(
        vectorWithItems(
          vectorWithItems(1, 2),
          3),
        vectorWithItems(4,
          vectorWithItems(ConsValue.IntAtom(5)),
          vectorWithItems(ConsValue.IntAtom(6))),
        7))
  }

  /// .read-string should properly read in maps.
  func testWithMaps() {
    expectInputToReadString("{}", toEvalTo: mapWithItems())
    expectInputToReadString("{1 2, 3 4}", toEvalTo: mapWithItems((1, 2), (3, 4)))
    let foo : ConsValue = .Symbol(symbol("foo"))
    let bar : ConsValue = .Keyword(keyword("bar"))
    expectInputToReadString("{(10 20 foo) {:bar true nil false}}", toEvalTo:
      mapWithItems((listWithItems(10, 20, foo), mapWithItems((bar, true), (.Nil, false)))))
  }

  /// .read-string should properly read in built-in functions.
  func testWithBuiltInFunctions() {
    expectInputToReadString(".cons", toEvalTo: .BuiltInFunction(.Cons))
    expectInputToReadString(".read-string", toEvalTo: .BuiltInFunction(.ReadString))
  }

  /// .read-string should reject non-string arguments.
  func testNonStringArguments() {
    expectInvalidArgumentErrorFrom("(.read-string nil)")
    expectInvalidArgumentErrorFrom("(.read-string true)")
    expectInvalidArgumentErrorFrom("(.read-string false)")
    expectInvalidArgumentErrorFrom("(.read-string -9281)")
    expectInvalidArgumentErrorFrom("(.read-string 69912.123123)")
    expectInvalidArgumentErrorFrom("(.read-string :y)")
    expectInvalidArgumentErrorFrom("(.read-string 'y)")
    expectInvalidArgumentErrorFrom("(.read-string \\y)")
    expectInvalidArgumentErrorFrom("(.read-string #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.read-string ())")
    expectInvalidArgumentErrorFrom("(.read-string [])")
    expectInvalidArgumentErrorFrom("(.read-string {})")
    expectInvalidArgumentErrorFrom("(.read-string .read-string)")
  }

  /// .read-string should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.read-string)")
    expectArityErrorFrom("(.read-string \"hello\" \"world\")")
  }
}
