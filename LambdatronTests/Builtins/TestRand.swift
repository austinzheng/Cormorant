//
//  TestRand.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/21/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

class TestRand : InterpreterTest {

  /// .rand should return a random floating-point number between 0 (inclusive) and 1 (exclusive).
  func testRand() {
    for _ in 0..<10 {
      let value = interpreter.evaluate("(.rand)")
      switch value {
      case let .Success(s):
        switch s {
        case let .FloatAtom(f):
          XCTAssert(f >= 0.0 && f < 1.0, ".rand must return a value between 0 (inclusive) and 1 (exclusive)")
        default: XCTFail(".rand must return a floating-point value")
        }
      default: XCTFail("evaluation was unsuccessful")
      }
    }
  }

  func testRandArity() {
    expectArityErrorFrom("(.rand 5)")
  }
}
