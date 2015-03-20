//
//  TestLists.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/23/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

/// Test Cons's built-in functionality.
class TestListBasics : XCTestCase {

  /// An empty Cons should work properly in the context of a for-in loop.
  func testEmptyConsIteration() {
    var emptyCons : SeqType = EmptyNode
    var untouched = true
    for item in SeqIterator(emptyCons) {
      untouched = false
    }
    XCTAssert(untouched, "An empty Cons list should not iterate even a single time through a for-in loop.")
  }

  /// A non-empty Cons should work properly in the context of a for-in loop.
  func testConsIteration() {
    let sublist = listWithItems(true, false)
    let vector : ConsValue = .Vector([.Nil, 1.23456, .CharAtom("\n")])
    var testCons = listWithItems(15, sublist, vector, .StringAtom("foobar"))
    var counter = 0

    for item in SeqIterator(testCons)! {
      if counter == 0 {
        switch item {
        case let .Success(item):
          XCTAssert(item == 15,
            "The first item in the list should have been the integer 15.")
        case .Error:
          XCTFail("The first item in the list didn't expand properly")
        }
      }
      else if counter == 1 {
        switch item {
        case let .Success(item):
          XCTAssert(item == sublist,
            "The second item in the list should have been the sublist.")
        case .Error:
          XCTFail("The second item in the list didn't expand properly")
        }
      }
      else if counter == 2 {
        switch item {
        case let .Success(item):
          XCTAssert(item == vector,
            "The third item in the list should have been the vector.")
        case .Error:
          XCTFail("The third item in the list didn't expand properly")
        }
      }
      else if counter == 3 {
        switch item {
        case let .Success(item):
          XCTAssert(item == .StringAtom("foobar"),
            "The fourth item in the list should have been the string \"foobar\".")
        case .Error:
          XCTFail("The fourth item in the list didn't expand properly")
        }
      }
      else {
        XCTFail("The list should only be visited 4 times.")
      }
      counter++
    }
    XCTAssert(counter == 4, "There should have been four iterations through the testCons list.")
  }

  /// A non-empty cons should work properly with enumerate.
  func testConsEnumerateIteration() {
    let sublist = listWithItems(true, false)
    let vector : ConsValue = .Vector([.Nil, 1.23456, .CharAtom("\n")])
    var testCons = listWithItems(15, sublist, vector, .StringAtom("foobar"))
    var counter = 0

    for (idx, item) in enumerate(SeqIterator(testCons)!) {
      XCTAssert(idx == counter, "The idx reported by enumerate() should always be in sync with 'counter'.")
      if counter == 0 {
        switch item {
        case let .Success(item):
          XCTAssert(item == 15,
            "The first item in the list should have been the integer 15.")
        case .Error:
          XCTFail("The first item in the list didn't expand properly")
        }
      }
      else if counter == 1 {
        switch item {
        case let .Success(item):
          XCTAssert(item == sublist,
            "The second item in the list should have been the sublist.")
        case .Error:
          XCTFail("The second item in the list didn't expand properly")
        }
      }
      else if counter == 2 {
        switch item {
        case let .Success(item):
          XCTAssert(item == vector,
            "The third item in the list should have been the vector.")
        case .Error:
          XCTFail("The third item in the list didn't expand properly")
        }
      }
      else if counter == 3 {
        switch item {
        case let .Success(item):
          XCTAssert(item == .StringAtom("foobar"),
            "The fourth item in the list should have been the string \"foobar\".")
        case .Error:
          XCTFail("The fourth item in the list didn't expand properly")
        }
      }
      else {
        XCTFail("The list should only be visited 4 times.")
      }
      counter++
    }
    XCTAssert(counter == 4, "There should have been four iterations through the testCons list.")
  }
}
