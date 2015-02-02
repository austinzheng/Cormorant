//
//  TestCollections.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Exercise the '.list' built-in function.
class TestListBuiltin : InterpreterTest {

  /// .list invoked with no arguments should return the empty list.
  func testEmpty() {
    expectThat("(.list)", shouldEvalTo: listWithItems())
  }

  /// .list invoked with one argument should return a single-argument list.
  func testSingleArg() {
    expectThat("(.list nil)", shouldEvalTo: listWithItems(ConsValue.NilLiteral))
    expectThat("(.list true)", shouldEvalTo: listWithItems(ConsValue.BoolLiteral(true)))
    expectThat("(.list false)", shouldEvalTo: listWithItems(ConsValue.BoolLiteral(false)))
    expectThat("(.list 1523)", shouldEvalTo: listWithItems(ConsValue.IntegerLiteral(1523)))
    expectThat("(.list \\c)", shouldEvalTo: listWithItems(ConsValue.CharacterLiteral("c")))
    expectThat("(.list \"foobar\")", shouldEvalTo: listWithItems(ConsValue.StringLiteral("foobar")))
    expectThat("(.list .+)", shouldEvalTo: listWithItems(ConsValue.BuiltInFunction(.Plus)))
  }

  /// .list invoked with multiple arguments should return a multiple-argument list.
  func testMultipleArgs() {
    expectThat("(.list 1 2 3 4)",
      shouldEvalTo: listWithItems(.IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3), .IntegerLiteral(4)))
    expectThat("(.list nil \"hello\" \\newline 1.523 true)",
      shouldEvalTo: listWithItems(.NilLiteral, .StringLiteral("hello"), .CharacterLiteral("\n"), .FloatLiteral(1.523),
        .BoolLiteral(true)))
    expectThat("(.list '() [] {})",
      shouldEvalTo: listWithItems(listWithItems(), vectorWithItems(), mapWithItems()))
  }
}

/// Exercise the '.vector' built-in function.
class TestVectorBuiltin : InterpreterTest {

  /// .list invoked with no arguments should return the empty list.
  func testEmpty() {
    expectThat("(.vector)", shouldEvalTo: vectorWithItems())
  }

  /// .list invoked with one argument should return a single-argument list.
  func testSingleArg() {
    expectThat("(.vector nil)", shouldEvalTo: vectorWithItems(ConsValue.NilLiteral))
    expectThat("(.vector true)", shouldEvalTo: vectorWithItems(ConsValue.BoolLiteral(true)))
    expectThat("(.vector false)", shouldEvalTo: vectorWithItems(ConsValue.BoolLiteral(false)))
    expectThat("(.vector 1523)", shouldEvalTo: vectorWithItems(ConsValue.IntegerLiteral(1523)))
    expectThat("(.vector \\c)", shouldEvalTo: vectorWithItems(ConsValue.CharacterLiteral("c")))
    expectThat("(.vector \"foobar\")", shouldEvalTo: vectorWithItems(ConsValue.StringLiteral("foobar")))
    expectThat("(.vector .+)", shouldEvalTo: vectorWithItems(ConsValue.BuiltInFunction(.Plus)))
  }

  /// .list invoked with multiple arguments should return a multiple-argument list.
  func testMultipleArgs() {
    expectThat("(.vector 1 2 3 4)",
      shouldEvalTo: vectorWithItems(.IntegerLiteral(1), .IntegerLiteral(2), .IntegerLiteral(3), .IntegerLiteral(4)))
    expectThat("(.vector nil \"hello\" \\newline 1.523 true)",
      shouldEvalTo: vectorWithItems(.NilLiteral, .StringLiteral("hello"), .CharacterLiteral("\n"), .FloatLiteral(1.523),
        .BoolLiteral(true)))
    expectThat("(.vector '() [] {})",
      shouldEvalTo: vectorWithItems(listWithItems(), vectorWithItems(), mapWithItems()))
  }
}

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
