//
//  TestTestHelpers.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/4/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Cormorant

class TestTestHelpers : InterpreterTest {

  /// listForItems should return the empty list when invoked with no arguments.
  func testListForItemsNoArgs() {
    let ref = Value.seq(EmptyNode)
    let theList = list()
    XCTAssert(ref == theList, "listWithItems failed to build the empty list properly")
  }

  /// listForItems should return a list containing items when invoked with arguments.
  func testListForItems() {
    let ref = Value.seq(sequence(fromItems: [1, .string("foo"), true]))
    let theList = list(containing: 1, .string("foo"), true)
    XCTAssert(ref == theList, "listWithItems failed to build a non-empty list properly")
  }

  /// expectThat with either the string or Value arguments should work correctly.
  func testExpectThat() {
    // Note: if this unit test fails, something is wrong with expectThat.
    run(input: "(def a '(1 2 3 4 5))")
    expectThat("a", shouldEvalTo: "'(1 2 3 4 5)")
    expectThat("a", shouldEvalTo: list(containing: 1, 2, 3, 4, 5))
    let value = run(input: "a")
    let refList = list(containing: 1, 2, 3, 4, 5)
    XCTAssert(value == refList, "expectThat's results weren't consistent with those of the reference value")
  }
}
