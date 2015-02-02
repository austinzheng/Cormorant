//
//  TestVector.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

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
