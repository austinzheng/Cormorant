//
//  TestHashmap.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Exercise the '.hashmap' built-in function.
class TestHashmapBuiltin : InterpreterTest {

  /// .hashmap invoked with no arguments should return the empty hashmap.
  func testEmpty() {
    expectThat("(.hashmap)", shouldEvalTo: map())
  }

  /// .hashmap should return a hash map when invoked with its arguments.
  func testHashmap1() {
    let internedKeywordA = keyword("a")
    let internedKeywordB = keyword("b")
    let internedSymbolA = symbol("a")
    let internedSymbolB = symbol("b")
    expectThat("(.hashmap :a 15)", shouldEvalTo: map(containing: (.keyword(internedKeywordA), 15)))
    expectThat("(.hashmap :a 'a :b 'b)",
      shouldEvalTo: map(containing: (.keyword(internedKeywordA), .symbol(internedSymbolA)),
        (.keyword(internedKeywordB), .symbol(internedSymbolB))))
    expectThat("(.hashmap () [] nil {})",
      shouldEvalTo: map(containing: (list(), vector()), (.nilValue, map())))
  }

  /// .hashmap should return a hash map when invoked with its arguments.
  func testHashmap2() {
    expectThat("(.hashmap 1 2 3 (.hashmap 4 5) 6 7)",
      shouldEvalTo: map(containing: (1, 2), (3, map(containing: (4, 5))), (6, 7)))
  }

  /// .hashmap invoked with an odd number of arguments should return an error.
  func testUnmatchedKeys() {
    expectThat("(.hashmap :a)", shouldFailAs: .ArityError)
    expectThat("(.hashmap :a :b :c)", shouldFailAs: .ArityError)
    expectThat("(.hashmap :a \\b :c \\d :e)", shouldFailAs: .ArityError)
  }
}
