//
//  TestConcat.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/3/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestConcatBuiltin : InterpreterTest {

  /// .concat should return the empty list when invoked with no arguments.
  func testWithNoArgs() {
    expectThat("(.concat)", shouldEvalTo: listWithItems())
  }

  /// .concat should skip empty collections.
  func testWithEmpty() {
    expectThat("(.concat ())", shouldEvalTo: listWithItems())
    expectThat("(.concat [])", shouldEvalTo: listWithItems())
    expectThat("(.concat {})", shouldEvalTo: listWithItems())
    expectThat("(.concat \"\")", shouldEvalTo: listWithItems())
    expectThat("(.concat () [] {} \"\" \"\" {} [] ())", shouldEvalTo: listWithItems())
  }

  /// .concat should skip empty collections.
  func testWithEmpty2() {
    let targetList = listWithItems(.IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3))
    expectThat("(.concat nil '(1 2 3))", shouldEvalTo: targetList)
    expectThat("(.concat '(1 2 3) nil)", shouldEvalTo: targetList)
    expectThat("(.concat nil '(1 2 3) nil nil)", shouldEvalTo: targetList)
  }

  /// .concat should skip empty collections.
  func testWithEmpty3() {
    expectThat("(.concat \"a\" nil \"b\")", shouldEvalTo: listWithItems(.CharacterLiteral("a"), .CharacterLiteral("b")))
    expectThat("(.concat '(1) nil '(2))", shouldEvalTo: listWithItems(.IntegerLiteral(1), .IntegerLiteral(2)))
    expectThat("(.concat [1] nil [2])", shouldEvalTo: listWithItems(.IntegerLiteral(1), .IntegerLiteral(2)))
    expectThat("(.concat {1 2} nil {3 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      vectorWithItems(.IntegerLiteral(3), .IntegerLiteral(4))))
  }

  /// .concat should concatenate strings as lists of characters.
  func testWithStrings() {
    expectThat("(.concat \"hello\")", shouldEvalTo: listWithItems(
      .CharacterLiteral("h"), .CharacterLiteral("e"), .CharacterLiteral("l"), .CharacterLiteral("l"),
      .CharacterLiteral("o")))
    expectThat("(.concat \"foo\" \"bar\")", shouldEvalTo: listWithItems(
      .CharacterLiteral("f"), .CharacterLiteral("o"), .CharacterLiteral("o"),
      .CharacterLiteral("b"), .CharacterLiteral("a"), .CharacterLiteral("r")))
    expectThat("(.concat \"f\" \"o\" \"o\")", shouldEvalTo: listWithItems(
      .CharacterLiteral("f"), .CharacterLiteral("o"), .CharacterLiteral("o")))
  }

  /// .concat should concatenate lists.
  func testWithLists() {
    let targetList = listWithItems(
      .IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3), .IntegerLiteral(4))
    expectThat("(.concat '(1 2 3 4))", shouldEvalTo: targetList)
    expectThat("(.concat '(1 2) '(3 4))", shouldEvalTo: targetList)
    expectThat("(.concat '(1) '(2 3) '(4))", shouldEvalTo: targetList)
  }

  /// .concat should concatenate vectors.
  func testWithVectors() {
    let targetList = listWithItems(
      .IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3), .IntegerLiteral(4))
    expectThat("(.concat [1 2 3 4])", shouldEvalTo: targetList)
    expectThat("(.concat [1 2] [3 4])", shouldEvalTo: targetList)
    expectThat("(.concat [1] [2 3] [4])", shouldEvalTo: targetList)
  }

  /// .concat should concatenate maps.
  func testWithMaps() {
    expectThat("(.concat {1 2 3 4})", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2))))
    expectThat("(.concat {1 2} {3 4} {5 6} {7 8})", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      vectorWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      vectorWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      vectorWithItems(.IntegerLiteral(7), .IntegerLiteral(8))))
    expectThat("(.concat {1 2 3 4} {5 6} {7 8})", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(3), .IntegerLiteral(4)),
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      vectorWithItems(.IntegerLiteral(5), .IntegerLiteral(6)),
      vectorWithItems(.IntegerLiteral(7), .IntegerLiteral(8))))
  }

  /// .concat should concatenate mixed items.
  func testWithMixedItems() {
    let aKeyword = interpreter.context.keywordForName("a")
    let bKeyword = interpreter.context.keywordForName("b")
    let aSymbol = interpreter.context.symbolForName("a")
    let bSymbol = interpreter.context.symbolForName("b")
    expectThat("(.concat '(1 2) [3 4 5] \"foo\" {:a 'a :b 'b})", shouldEvalTo: listWithItems(
      .IntegerLiteral(1), .IntegerLiteral(2),
      .IntegerLiteral(3), .IntegerLiteral(4), .IntegerLiteral(5),
      .CharacterLiteral("f"), .CharacterLiteral("o"), .CharacterLiteral("o"),
      vectorWithItems(.Keyword(bKeyword), .Symbol(bSymbol)),
      vectorWithItems(.Keyword(aKeyword), .Symbol(aSymbol))))
    expectThat("(.concat {1 2 true nil} '(3) [4 5 6 7] \"bar\")", shouldEvalTo: listWithItems(
      vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2)),
      vectorWithItems(.BoolLiteral(true), .NilLiteral),
      .IntegerLiteral(3),
      .IntegerLiteral(4), .IntegerLiteral(5), .IntegerLiteral(6), .IntegerLiteral(7),
      .CharacterLiteral("b"), .CharacterLiteral("a"), .CharacterLiteral("r")))
  }

  /// .concat should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectThat("(.concat true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.concat false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.concat 152)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.concat 3.141592)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.concat :foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.concat 'foo)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.concat \\f)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.concat .concat)", shouldFailAs: .InvalidArgumentError)
  }
}
