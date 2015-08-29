//
//  TestTestHelpers.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/4/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Lambdatron

class TestTestHelpers : InterpreterTest {

  /// listForItems should return the empty list when invoked with no arguments.
  func testListForItemsNoArgs() {
    let ref = Value.Seq(EmptyNode)
    let list = listWithItems()
    XCTAssert(ref == list, "listWithItems failed to build the empty list properly")
  }

  /// listForItems should return a list containing items when invoked with arguments.
  func testListForItems() {
    let ref = Value.Seq(sequenceFromItems([1, .StringAtom("foo"), true]))
    let list = listWithItems(1, .StringAtom("foo"), true)
    XCTAssert(ref == list, "listWithItems failed to build a non-empty list properly")
  }

  /// expectThat with either the string or Value arguments should work correctly.
  func testExpectThat() {
    // Note: if this unit test fails, something is wrong with expectThat.
    runCode("(def a '(1 2 3 4 5))")
    expectThat("a", shouldEvalTo: "'(1 2 3 4 5)")
    expectThat("a", shouldEvalTo: listWithItems(1, 2, 3, 4, 5))
    let value = runCode("a")
    let refList = listWithItems(1, 2, 3, 4, 5)
    XCTAssert(value == refList, "expectThat's results weren't consistent with those of the reference value")
  }
}
