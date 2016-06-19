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
    expectThat("(.list)", shouldEvalTo: list())
  }

  /// .list invoked with one argument should return a single-argument list.
  func testSingleArg() {
    expectThat("(.list nil)", shouldEvalTo: list(containing: .nilValue))
    expectThat("(.list true)", shouldEvalTo: list(containing: .bool(true)))
    expectThat("(.list false)", shouldEvalTo: list(containing: .bool(false)))
    expectThat("(.list 1523)", shouldEvalTo: list(containing: .int(1523)))
    expectThat("(.list \\c)", shouldEvalTo: list(containing: .char("c")))
    expectThat("(.list \"foobar\")", shouldEvalTo: list(containing: .string("foobar")))
    expectThat("(.list .+)", shouldEvalTo: list(containing: .builtInFunction(.Plus)))
  }

  /// .list invoked with multiple arguments should return a multiple-argument list.
  func testMultipleArgs() {
    expectThat("(.list 1 2 3 4)", shouldEvalTo: list(containing: 1, 2, 3, 4))
    expectThat("(.list nil \"hello\" \\newline 1.523 true)",
               shouldEvalTo: list(containing: .nilValue, .string("hello"), .char("\n"), 1.523, true))
    expectThat("(.list () [] {})",
               shouldEvalTo: list(containing: list(), vector(), map()))
  }
}
