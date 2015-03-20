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
    let targetList = listWithItems(1, 2, 3)
    expectThat("(.concat nil '(1 2 3))", shouldEvalTo: targetList)
    expectThat("(.concat '(1 2 3) nil)", shouldEvalTo: targetList)
    expectThat("(.concat nil '(1 2 3) nil nil)", shouldEvalTo: targetList)
  }

  /// .concat should skip empty collections.
  func testWithEmpty3() {
    expectThat("(.concat \"a\" nil \"b\")", shouldEvalTo: listWithItems(.CharAtom("a"), .CharAtom("b")))
    expectThat("(.concat '(1) nil '(2))", shouldEvalTo: listWithItems(1, 2))
    expectThat("(.concat [1] nil [2])", shouldEvalTo: listWithItems(1, 2))
    expectThat("(.concat {1 2} nil {3 4})", shouldEvalTo:
      listWithItems(vectorWithItems(1, 2), vectorWithItems(3, 4)))
  }

  /// .concat should concatenate strings as lists of characters.
  func testWithStrings() {
    expectThat("(.concat \"hello\")", shouldEvalTo: listWithItems(
      .CharAtom("h"), .CharAtom("e"), .CharAtom("l"), .CharAtom("l"),
      .CharAtom("o")))
    expectThat("(.concat \"foo\" \"bar\")", shouldEvalTo: listWithItems(
      .CharAtom("f"), .CharAtom("o"), .CharAtom("o"),
      .CharAtom("b"), .CharAtom("a"), .CharAtom("r")))
    expectThat("(.concat \"f\" \"o\" \"o\")", shouldEvalTo: listWithItems(
      .CharAtom("f"), .CharAtom("o"), .CharAtom("o")))
  }

  /// .concat should concatenate lists.
  func testWithLists() {
    let targetList = listWithItems(1, 2, 3, 4)
    expectThat("(.concat '(1 2 3 4))", shouldEvalTo: targetList)
    expectThat("(.concat '(1 2) '(3 4))", shouldEvalTo: targetList)
    expectThat("(.concat '(1) '(2 3) '(4))", shouldEvalTo: targetList)
  }

  /// .concat should concatenate lazy sequences.
  func testWithLazySeqs() {
    expectThat("(.concat (.lazy-seq (fn [] '(1 2))))", shouldEvalTo: listWithItems(1, 2))
    expectThat("(.concat (.lazy-seq (fn [] '(1 2))) (.lazy-seq (fn [] [5 6 7])))",
      shouldEvalTo: listWithItems(1, 2, 5, 6, 7))
    expectThat("(.concat (.lazy-seq (fn [] [1])) (.lazy-seq (fn [] [2])) (.lazy-seq (fn [] ())) (.lazy-seq (fn [] '(3))))",
      shouldEvalTo: listWithItems(1, 2, 3))
  }

  /// .concat should concatenate vectors.
  func testWithVectors() {
    let targetList = listWithItems(1, 2, 3, 4)
    expectThat("(.concat [1 2 3 4])", shouldEvalTo: targetList)
    expectThat("(.concat [1 2] [3 4])", shouldEvalTo: targetList)
    expectThat("(.concat [1] [2 3] [4])", shouldEvalTo: targetList)
  }

  /// .concat should concatenate maps.
  func testWithMaps() {
    expectThat("(.concat {1 2 3 4})", shouldEvalTo:
      listWithItems(vectorWithItems(3, 4), vectorWithItems(1, 2)))
    expectThat("(.concat {1 2} {3 4} {5 6} {7 8})", shouldEvalTo:
      listWithItems(vectorWithItems(1, 2), vectorWithItems(3, 4), vectorWithItems(5, 6), vectorWithItems(7, 8)))
    expectThat("(.concat {1 2 3 4} {5 6} {7 8})", shouldEvalTo:
      listWithItems(vectorWithItems(3, 4), vectorWithItems(1, 2), vectorWithItems(5, 6), vectorWithItems(7, 8)))
  }

  /// .concat should concatenate mixed items.
  func testWithMixedItems() {
    let aKeyword = interpreter.context.keywordForName("a")
    let bKeyword = interpreter.context.keywordForName("b")
    let aSymbol = interpreter.context.symbolForName("a")
    let bSymbol = interpreter.context.symbolForName("b")
    expectThat("(.concat '(1 2) [3 4 5] \"foo\" {:a 'a :b 'b})", shouldEvalTo:
      listWithItems(1, 2, 3, 4, 5, .CharAtom("f"), .CharAtom("o"), .CharAtom("o"),
        vectorWithItems(.Keyword(bKeyword), .Symbol(bSymbol)),
        vectorWithItems(.Keyword(aKeyword), .Symbol(aSymbol))))
    expectThat("(.concat {1 2 true nil} '(3) [4 5 6 7] \"bar\")", shouldEvalTo:
      listWithItems(vectorWithItems(1, 2), vectorWithItems(true, .Nil), 3, 4, 5, 6, 7, .CharAtom("b"), .CharAtom("a"),
        .CharAtom("r")))
  }

  /// .concat should properly concatenate mixed items involving strings.
  func testItemsAgainstStrings() {
    expectThat("(.concat {10 11} \"foo\" {5 6})", shouldEvalTo:
      listWithItems(vectorWithItems(10, 11), .CharAtom("f"), .CharAtom("o"), .CharAtom("o"), vectorWithItems(5, 6)))
    expectThat("(.concat [true nil] \"foo\" [3 4])", shouldEvalTo:
      listWithItems(true, .Nil, .CharAtom("f"), .CharAtom("o"), .CharAtom("o"), 3, 4))
    expectThat("(.concat '(99 0) \"foo\" '(3 4))", shouldEvalTo:
      listWithItems(99, 0, .CharAtom("f"), .CharAtom("o"), .CharAtom("o"), 3, 4))
    expectThat("(.concat \"ba\" \"baz\" \"foo\")", shouldEvalTo:
      listWithItems(.CharAtom("b"), .CharAtom("a"), .CharAtom("b"), .CharAtom("a"), .CharAtom("z"), .CharAtom("f"),
        .CharAtom("o"), .CharAtom("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) \"foo\" (.lazy-seq (fn [] '(3 4))))",
      shouldEvalTo: listWithItems(11, 12, .CharAtom("f"), .CharAtom("o"), .CharAtom("o"), 3, 4))
  }

  /// .concat should properly concatenate mixed items involving lists.
  func testItemsAgainstLists() {
    expectThat("(.concat {10 11} '(1 2) {5 6})", shouldEvalTo:
      listWithItems(vectorWithItems(10, 11), 1, 2, vectorWithItems(5, 6)))
    expectThat("(.concat [true nil] '(1 2) [3 4])", shouldEvalTo: listWithItems(true, .Nil, 1, 2, 3, 4))
    expectThat("(.concat '(99 0) '(1 2) '(3 4))", shouldEvalTo: listWithItems(99, 0, 1, 2, 3, 4))
    expectThat("(.concat \"ba\" '(1 2) \"foo\")", shouldEvalTo:
      listWithItems(.CharAtom("b"), .CharAtom("a"), 1, 2, .CharAtom("f"), .CharAtom("o"), .CharAtom("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) '(1 2) (.lazy-seq (fn [] '(3 4))))",
      shouldEvalTo: listWithItems(11, 12, 1, 2, 3, 4))
  }

  /// .concat should properly concatenate mixed items involving vectors.
  func testItemsAgainstVectors() {
    expectThat("(.concat {10 11} [1 2] {5 6})", shouldEvalTo:
      listWithItems(vectorWithItems(10, 11), 1, 2, vectorWithItems(5, 6)))
    expectThat("(.concat [true nil] [1 2] [3 4])", shouldEvalTo: listWithItems(true, .Nil, 1, 2, 3, 4))
    expectThat("(.concat \"ba\" [1 2] \"foo\")", shouldEvalTo:
      listWithItems(.CharAtom("b"), .CharAtom("a"), 1, 2, .CharAtom("f"), .CharAtom("o"), .CharAtom("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) [1 2] (.lazy-seq (fn [] '(3 4))))",
      shouldEvalTo: listWithItems(11, 12, 1, 2, 3, 4))
  }

  /// .concat should properly concatenate mixed items involving vectors.
  func testItemsAgainstMaps() {
    expectThat("(.concat {10 11} {1 2} {5 6})", shouldEvalTo:
      listWithItems(vectorWithItems(10, 11), vectorWithItems(1, 2), vectorWithItems(5, 6)))
    expectThat("(.concat [true nil] {1 2} [3 4])", shouldEvalTo:
      listWithItems(true, .Nil, vectorWithItems(1, 2), 3, 4))
    expectThat("(.concat \"b\" {1 2} \"foo\")", shouldEvalTo:
      listWithItems(.CharAtom("b"), vectorWithItems(1, 2), .CharAtom("f"), .CharAtom("o"), .CharAtom("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) {1 2} (.lazy-seq (fn [] '(3 4))))",
      shouldEvalTo: listWithItems(11, 12, vectorWithItems(1, 2), 3, 4))
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
