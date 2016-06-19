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

  private func expectInputToReadString(_ input: String, toEvalTo result: Value) {
    return expectThat("(.read-string \"\(input)\")", shouldEvalTo: result)
  }

  /// .read-string should properly read in literal keywords.
  func testLiteralKeywords() {
    expectInputToReadString("nil", toEvalTo: .nilValue)
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
    expectInputToReadString("foo", toEvalTo: .symbol(fooSymbol))
    expectInputToReadString("bar", toEvalTo: .symbol(barSymbol))
    expectInputToReadString("meela/foo", toEvalTo: .symbol(fqFoo))
  }

  /// .read-string should properly read in keywords.
  func testWithKeywords() {
    let fooKeyword = keyword("foo")
    let barKeyword = keyword("bar")
    let fqFoo = keyword("foo", namespace: "meela")
    expectInputToReadString(":foo", toEvalTo: .keyword(fooKeyword))
    expectInputToReadString(":bar", toEvalTo: .keyword(barKeyword))
    expectInputToReadString(":meela/foo", toEvalTo: .keyword(fqFoo))
  }

  /// .read-string should properly read in character literals.
  func testWithCharacters() {
    expectInputToReadString("\\\\a", toEvalTo: .char("a"))
    expectInputToReadString("\\\\newline", toEvalTo: .char("\n"))
  }

  /// .read-string should properly read in strings.
  func testWithStrings() {
    expectInputToReadString("\\\"\\\"", toEvalTo: .string(""))
    expectInputToReadString("\\\"hello world\\\"", toEvalTo: .string("hello world"))
  }

  /// .read-string should properly read in lists.
  func testWithLists() {
    let fooSymbol = symbol("foo")
    expectInputToReadString("()", toEvalTo: list())
    expectInputToReadString("(1 2 3 4)", toEvalTo: list(containing: 1, 2, 3, 4))
    expectInputToReadString("(foo [1 2] \\\"three\\\" 4)",
                            toEvalTo: list(containing: .symbol(fooSymbol), vector(containing: 1, 2), .string("three"), 4))
  }

  /// .read-string should properly read in vectors.
  func testWithVectors() {
    expectInputToReadString("[]", toEvalTo: vector())
    expectInputToReadString("[[[1 2] 3] [4 [5] [6]] 7]", toEvalTo:
      vector(containing: 
        vector(containing: 
          vector(containing: 1, 2),
          3),
        vector(containing: 4,
          vector(containing: .int(5)),
          vector(containing: .int(6))),
        7))
  }

  /// .read-string should properly read in maps.
  func testWithMaps() {
    expectInputToReadString("{}", toEvalTo: map())
    expectInputToReadString("{1 2, 3 4}", toEvalTo: map(containing: (1, 2), (3, 4)))
    let foo = Value.symbol(symbol("foo"))
    let bar = Value.keyword(keyword("bar"))
    expectInputToReadString("{(10 20 foo) {:bar true nil false}}", toEvalTo:
      map(containing: (list(containing: 10, 20, foo), map(containing: (bar, true), (.nilValue, false)))))
  }

  /// .read-string should properly read in built-in functions.
  func testWithBuiltInFunctions() {
    expectInputToReadString(".cons", toEvalTo: .builtInFunction(.Cons))
    expectInputToReadString(".read-string", toEvalTo: .builtInFunction(.ReadString))
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
