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
    expectThat("(.concat)", shouldEvalTo: list())
  }

  /// .concat should skip empty collections.
  func testWithEmpty() {
    expectThat("(.concat ())", shouldEvalTo: list())
    expectThat("(.concat [])", shouldEvalTo: list())
    expectThat("(.concat {})", shouldEvalTo: list())
    expectThat("(.concat \"\")", shouldEvalTo: list())
    expectThat("(.concat () [] {} \"\" \"\" {} [] ())", shouldEvalTo: list())
  }

  /// .concat should skip empty collections.
  func testWithEmpty2() {
    let targetList = list(containing: 1, 2, 3)
    expectThat("(.concat nil '(1 2 3))", shouldEvalTo: targetList)
    expectThat("(.concat '(1 2 3) nil)", shouldEvalTo: targetList)
    expectThat("(.concat nil '(1 2 3) nil nil)", shouldEvalTo: targetList)
  }

  /// .concat should skip empty collections.
  func testWithEmpty3() {
    expectThat("(.concat \"a\" nil \"b\")",
               shouldEvalTo: list(containing: .char("a"), .char("b")))
    expectThat("(.concat '(1) nil '(2))",
               shouldEvalTo: list(containing: 1, 2))
    expectThat("(.concat [1] nil [2])",
               shouldEvalTo: list(containing: 1, 2))
    expectThat("(.concat {1 2} nil {3 4})",
               shouldEvalTo: list(containing: vector(containing: 1, 2), vector(containing: 3, 4)))
  }

  /// .concat should concatenate strings as lists of characters.
  func testWithStrings() {
    expectThat("(.concat \"hello\")",
               shouldEvalTo: list(containing: .char("h"), .char("e"), .char("l"), .char("l"), .char("o")))
    expectThat("(.concat \"foo\" \"bar\")",
               shouldEvalTo: list(containing: .char("f"), .char("o"), .char("o"), .char("b"), .char("a"), .char("r")))
    expectThat("(.concat \"f\" \"o\" \"o\")",
               shouldEvalTo: list(containing: .char("f"), .char("o"), .char("o")))
  }

  /// .concat should concatenate lists.
  func testWithLists() {
    let targetList = list(containing: 1, 2, 3, 4)
    expectThat("(.concat '(1 2 3 4))", shouldEvalTo: targetList)
    expectThat("(.concat '(1 2) '(3 4))", shouldEvalTo: targetList)
    expectThat("(.concat '(1) '(2 3) '(4))", shouldEvalTo: targetList)
  }

  /// .concat should concatenate lazy sequences.
  func testWithLazySeqs() {
    expectThat("(.concat (.lazy-seq (fn [] '(1 2))))", shouldEvalTo: list(containing: 1, 2))
    expectThat("(.concat (.lazy-seq (fn [] '(1 2))) (.lazy-seq (fn [] [5 6 7])))",
               shouldEvalTo: list(containing: 1, 2, 5, 6, 7))
    expectThat("(.concat (.lazy-seq (fn [] [1])) (.lazy-seq (fn [] [2])) (.lazy-seq (fn [] ())) (.lazy-seq (fn [] '(3))))",
               shouldEvalTo: list(containing: 1, 2, 3))
  }

  /// .concat should concatenate vectors.
  func testWithVectors() {
    let targetList = list(containing: 1, 2, 3, 4)
    expectThat("(.concat [1 2 3 4])", shouldEvalTo: targetList)
    expectThat("(.concat [1 2] [3 4])", shouldEvalTo: targetList)
    expectThat("(.concat [1] [2 3] [4])", shouldEvalTo: targetList)
  }

  /// .concat should concatenate maps.
  func testWithMaps() {
    expectThat("(.concat {1 2 3 4})",
               shouldEvalTo: list(containing: vector(containing: 3, 4), vector(containing: 1, 2)))
    expectThat("(.concat {1 2} {3 4} {5 6} {7 8})",
               shouldEvalTo: list(containing: vector(containing: 1, 2), vector(containing: 3, 4), vector(containing: 5, 6), vector(containing: 7, 8)))
    expectThat("(.concat {1 2 3 4} {5 6} {7 8})",
               shouldEvalTo: list(containing: vector(containing: 3, 4), vector(containing: 1, 2), vector(containing: 5, 6), vector(containing: 7, 8)))
  }

  /// .concat should concatenate mixed items.
  func testWithMixedItems() {
    let aKeyword = keyword("a")
    let bKeyword = keyword("b")
    let aSymbol = symbol("a")
    let bSymbol = symbol("b")
    expectThat("(.concat '(1 2) [3 4 5] \"foo\" {:a 'a :b 'b})",
               shouldEvalToContain: 1, 2, 3, 4, 5,
               .char("f"),
               .char("o"),
               .char("o"),
               vector(containing: .keyword(aKeyword), .symbol(aSymbol)),
               vector(containing: .keyword(bKeyword), .symbol(bSymbol)))
    expectThat("(.concat {1 2 true nil} '(3) [4 5 6 7] \"bar\")",
               shouldEvalToContain: vector(containing: 1, 2),
               vector(containing: true, .nilValue),
               3, 4, 5, 6, 7,
               .char("b"),
               .char("a"),
               .char("r"))
  }

  /// .concat should properly concatenate mixed items involving strings.
  func testItemsAgainstStrings() {
    expectThat("(.concat {10 11} \"foo\" {5 6})",
               shouldEvalTo: list(containing: vector(containing: 10, 11), .char("f"), .char("o"), .char("o"), vector(containing: 5, 6)))
    expectThat("(.concat [true nil] \"foo\" [3 4])",
               shouldEvalTo: list(containing: true, .nilValue, .char("f"), .char("o"), .char("o"), 3, 4))
    expectThat("(.concat '(99 0) \"foo\" '(3 4))",
               shouldEvalTo: list(containing: 99, 0, .char("f"), .char("o"), .char("o"), 3, 4))
    expectThat("(.concat \"ba\" \"baz\" \"foo\")",
               shouldEvalTo: list(containing: .char("b"), .char("a"), .char("b"), .char("a"), .char("z"), .char("f"), .char("o"), .char("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) \"foo\" (.lazy-seq (fn [] '(3 4))))",
               shouldEvalTo: list(containing: 11, 12, .char("f"), .char("o"), .char("o"), 3, 4))
  }

  /// .concat should properly concatenate mixed items involving lists.
  func testItemsAgainstLists() {
    expectThat("(.concat {10 11} '(1 2) {5 6})",
               shouldEvalTo: list(containing: vector(containing: 10, 11), 1, 2, vector(containing: 5, 6)))
    expectThat("(.concat [true nil] '(1 2) [3 4])",
               shouldEvalTo: list(containing: true, .nilValue, 1, 2, 3, 4))
    expectThat("(.concat '(99 0) '(1 2) '(3 4))",
               shouldEvalTo: list(containing: 99, 0, 1, 2, 3, 4))
    expectThat("(.concat \"ba\" '(1 2) \"foo\")",
               shouldEvalTo: list(containing: .char("b"), .char("a"), 1, 2, .char("f"), .char("o"), .char("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) '(1 2) (.lazy-seq (fn [] '(3 4))))",
               shouldEvalTo: list(containing: 11, 12, 1, 2, 3, 4))
  }

  /// .concat should properly concatenate mixed items involving vectors.
  func testItemsAgainstVectors() {
    expectThat("(.concat {10 11} [1 2] {5 6})",
               shouldEvalTo: list(containing: vector(containing: 10, 11), 1, 2, vector(containing: 5, 6)))
    expectThat("(.concat [true nil] [1 2] [3 4])",
               shouldEvalTo: list(containing: true, .nilValue, 1, 2, 3, 4))
    expectThat("(.concat \"ba\" [1 2] \"foo\")",
               shouldEvalTo: list(containing: .char("b"), .char("a"), 1, 2, .char("f"), .char("o"), .char("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) [1 2] (.lazy-seq (fn [] '(3 4))))",
               shouldEvalTo: list(containing: 11, 12, 1, 2, 3, 4))
  }

  /// .concat should properly concatenate mixed items involving vectors.
  func testItemsAgainstMaps() {
    expectThat("(.concat {10 11} {1 2} {5 6})",
               shouldEvalTo: list(containing: vector(containing: 10, 11), vector(containing: 1, 2), vector(containing: 5, 6)))
    expectThat("(.concat [true nil] {1 2} [3 4])",
               shouldEvalTo: list(containing: true, .nilValue, vector(containing: 1, 2), 3, 4))
    expectThat("(.concat \"b\" {1 2} \"foo\")",
               shouldEvalTo: list(containing: .char("b"), vector(containing: 1, 2), .char("f"), .char("o"), .char("o")))
    expectThat("(.concat (.lazy-seq (fn [] [11 12])) {1 2} (.lazy-seq (fn [] '(3 4))))",
               shouldEvalTo: list(containing: 11, 12, vector(containing: 1, 2), 3, 4))
  }

  /// .concat should reject non-collection arguments.
  func testWithInvalidTypes() {
    expectInvalidArgumentErrorFrom("(.concat true)")
    expectInvalidArgumentErrorFrom("(.concat false)")
    expectInvalidArgumentErrorFrom("(.concat 152)")
    expectInvalidArgumentErrorFrom("(.concat 3.141592)")
    expectInvalidArgumentErrorFrom("(.concat :foo)")
    expectInvalidArgumentErrorFrom("(.concat 'foo)")
    expectInvalidArgumentErrorFrom("(.concat \\f)")
    expectInvalidArgumentErrorFrom("(.concat .concat)")
  }
}
