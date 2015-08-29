//
//  TestList.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

/// Exercise the '.list' built-in function.
class TestListBuiltin : InterpreterTest {

  /// .list invoked with no arguments should return the empty list.
  func testEmpty() {
    expectThat("(.list)", shouldEvalTo: listWithItems())
  }

  /// .list invoked with one argument should return a single-argument list.
  func testSingleArg() {
    expectThat("(.list nil)", shouldEvalTo: listWithItems(ConsValue.Nil))
    expectThat("(.list true)", shouldEvalTo: listWithItems(ConsValue.BoolAtom(true)))
    expectThat("(.list false)", shouldEvalTo: listWithItems(ConsValue.BoolAtom(false)))
    expectThat("(.list 1523)", shouldEvalTo: listWithItems(ConsValue.IntAtom(1523)))
    expectThat("(.list \\c)", shouldEvalTo: listWithItems(ConsValue.CharAtom("c")))
    expectThat("(.list \"foobar\")", shouldEvalTo: listWithItems(ConsValue.StringAtom("foobar")))
    expectThat("(.list .+)", shouldEvalTo: listWithItems(ConsValue.BuiltInFunction(.Plus)))
  }

  /// .list invoked with multiple arguments should return a multiple-argument list.
  func testMultipleArgs() {
    expectThat("(.list 1 2 3 4)", shouldEvalTo: listWithItems(1, 2, 3, 4))
    expectThat("(.list nil \"hello\" \\newline 1.523 true)",
      shouldEvalTo: listWithItems(.Nil, .StringAtom("hello"), .CharAtom("\n"), 1.523, true))
    expectThat("(.list () [] {})",
      shouldEvalTo: listWithItems(listWithItems(), vectorWithItems(), mapWithItems()))
  }
}
