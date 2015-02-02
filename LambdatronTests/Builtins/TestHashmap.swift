//
//  TestHashmap.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Exercise the '.hashmap' built-in function.
class TestHashmapBuiltin : InterpreterTest {

  /// .hashmap invoked with no arguments should return the empty hashmap.
  func testEmpty() {
    expectThat("(.hashmap)", shouldEvalTo: mapWithItems())
  }

  /// .hashmap should return a hash map when invoked with its arguments.
  func testHashmap1() {
    let internedKeywordA = interpreter.context.keywordForName("a")
    let internedKeywordB = interpreter.context.keywordForName("b")
    let internedSymbolA = interpreter.context.symbolForName("a")
    let internedSymbolB = interpreter.context.symbolForName("b")
    expectThat("(.hashmap :a 15)",
      shouldEvalTo: mapWithItems((.Keyword(internedKeywordA), .IntegerLiteral(15))))
    expectThat("(.hashmap :a 'a :b 'b)",
      shouldEvalTo: mapWithItems((.Keyword(internedKeywordA), .Symbol(internedSymbolA)),
        (.Keyword(internedKeywordB), .Symbol(internedSymbolB))))
    expectThat("(.hashmap '() [] nil {})",
      shouldEvalTo: mapWithItems((listWithItems(), vectorWithItems()), (.NilLiteral, mapWithItems())))
  }

  /// .hashmap should return a hash map when invoked with its arguments.
  func testHashmap2() {
    expectThat("(.hashmap 1 2 3 (.hashmap 4 5) 6 7)",
      shouldEvalTo: mapWithItems((.IntegerLiteral(1), .IntegerLiteral(2)),
        (.IntegerLiteral(3), mapWithItems((.IntegerLiteral(4), .IntegerLiteral(5)))),
        (.IntegerLiteral(6), .IntegerLiteral(7))))
  }

  /// .hashmap invoked with an odd number of arguments should return an error.
  func testUnmatchedKeys() {
    expectThat("(.hashmap :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.hashmap :a :b :c)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.hashmap :a \\b :c \\d :e)", shouldFailAs: .InvalidArgumentError)
  }
}
