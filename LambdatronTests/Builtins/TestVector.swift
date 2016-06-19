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
    expectThat("(.vector)", shouldEvalTo: vector())
  }

  /// .list invoked with one argument should return a single-argument list.
  func testSingleArg() {
    expectThat("(.vector nil)", shouldEvalTo: vector(containing: .nilValue))
    expectThat("(.vector true)", shouldEvalTo: vector(containing: .bool(true)))
    expectThat("(.vector false)", shouldEvalTo: vector(containing: .bool(false)))
    expectThat("(.vector 1523)", shouldEvalTo: vector(containing: .int(1523)))
    expectThat("(.vector \\c)", shouldEvalTo: vector(containing: .char("c")))
    expectThat("(.vector \"foobar\")", shouldEvalTo: vector(containing: .string("foobar")))
    expectThat("(.vector .+)", shouldEvalTo: vector(containing: .builtInFunction(.Plus)))
  }

  /// .list invoked with multiple arguments should return a multiple-argument list.
  func testMultipleArgs() {
    expectThat("(.vector 1 2 3 4)",
      shouldEvalTo: vector(containing: 1, 2, 3, 4))
    expectThat("(.vector nil \"hello\" \\newline 1.523 true)",
      shouldEvalTo: vector(containing: .nilValue, .string("hello"), .char("\n"), 1.523, true))
    expectThat("(.vector () [] {})",
      shouldEvalTo: vector(containing: list(), vector(), map()))
  }
}
