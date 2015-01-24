//
//  TestCons.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/23/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

/// Test Cons's built-in functionality.
class TestConsBasics : XCTestCase {

  /// An empty Cons should work properly in the context of a for-in loop.
  func testEmptyConsIteration() {
    var emptyCons = Cons()
    var untouched = true
    for item in emptyCons {
      untouched = false
    }
    XCTAssert(untouched, "An empty Cons list should not iterate even a single time through a for-in loop.")
  }

  /// A non-empty Cons should work properly in the context of a for-in loop.
  func testConsIteration() {
    let sublist : ConsValue = .ListLiteral(Cons(.BoolLiteral(true), next: Cons(.BoolLiteral(false))))
    let vector : ConsValue = .VectorLiteral([.NilLiteral, .FloatLiteral(1.23456), .CharacterLiteral("\n")])
    var testCons = Cons(.IntegerLiteral(15),
      next: Cons(sublist,
        next: Cons(vector,
          next: Cons(.StringLiteral("foobar")))))
    var counter = 0

    for item in testCons {
      if counter == 0 {
        XCTAssert(item == .IntegerLiteral(15),
          "The first item in the list should have been the integer 15.")
      }
      else if counter == 1 {
        XCTAssert(item == sublist,
          "The second item in the list should have been the sublist.")
      }
      else if counter == 2 {
        XCTAssert(item == vector,
          "The third item in the list should have been the vector.")
      }
      else if counter == 3 {
        XCTAssert(item == .StringLiteral("foobar"),
          "The fourth item in the list should have been the string \"foobar\".")
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
    let sublist : ConsValue = .ListLiteral(Cons(.BoolLiteral(true), next: Cons(.BoolLiteral(false))))
    let vector : ConsValue = .VectorLiteral([.NilLiteral, .FloatLiteral(1.23456), .CharacterLiteral("\n")])
    var testCons = Cons(.IntegerLiteral(15),
      next: Cons(sublist,
        next: Cons(vector,
          next: Cons(.StringLiteral("foobar")))))
    var counter = 0

    for (idx, item) in enumerate(testCons) {
      XCTAssert(idx == counter, "The idx reported by enumerate() should always be in sync with 'counter'.")
      if counter == 0 {
        XCTAssert(item == .IntegerLiteral(15),
          "The first item in the list should have been the integer 15.")
      }
      else if counter == 1 {
        XCTAssert(item == sublist,
          "The second item in the list should have been the sublist.")
      }
      else if counter == 2 {
        XCTAssert(item == vector,
          "The third item in the list should have been the vector.")
      }
      else if counter == 3 {
        XCTAssert(item == .StringLiteral("foobar"),
          "The fourth item in the list should have been the string \"foobar\".")
      }
      else {
        XCTFail("The list should only be visited 4 times.")
      }
      counter++
    }
    XCTAssert(counter == 4, "There should have been four iterations through the testCons list.")
  }
}
