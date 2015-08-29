//
//  TestVector.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

/// Exercise the '.vector' built-in function.
class TestVectorBuiltin : InterpreterTest {

  /// .list invoked with no arguments should return the empty list.
  func testEmpty() {
    expectThat("(.vector)", shouldEvalTo: vectorWithItems())
  }

  /// .list invoked with one argument should return a single-argument list.
  func testSingleArg() {
    expectThat("(.vector nil)", shouldEvalTo: vectorWithItems(.Nil))
    expectThat("(.vector true)", shouldEvalTo: vectorWithItems(.BoolAtom(true)))
    expectThat("(.vector false)", shouldEvalTo: vectorWithItems(.BoolAtom(false)))
    expectThat("(.vector 1523)", shouldEvalTo: vectorWithItems(.IntAtom(1523)))
    expectThat("(.vector \\c)", shouldEvalTo: vectorWithItems(.CharAtom("c")))
    expectThat("(.vector \"foobar\")", shouldEvalTo: vectorWithItems(.StringAtom("foobar")))
    expectThat("(.vector .+)", shouldEvalTo: vectorWithItems(.BuiltInFunction(.Plus)))
  }

  /// .list invoked with multiple arguments should return a multiple-argument list.
  func testMultipleArgs() {
    expectThat("(.vector 1 2 3 4)",
      shouldEvalTo: vectorWithItems(1, 2, 3, 4))
    expectThat("(.vector nil \"hello\" \\newline 1.523 true)",
      shouldEvalTo: vectorWithItems(.Nil, .StringAtom("hello"), .CharAtom("\n"), 1.523, true))
    expectThat("(.vector () [] {})",
      shouldEvalTo: vectorWithItems(listWithItems(), vectorWithItems(), mapWithItems()))
  }
}
