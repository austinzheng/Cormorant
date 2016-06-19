//
//  TestAttempt.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/11/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'attempt' special form.
class TestAttempt : InterpreterTest {

  /// attempt should return the value of the first successful form.
  func testAttemptSuccess() {
    expectThat("(attempt (.+ \\a \\b) (.+) (recur) 12345)", shouldEvalTo: 12345)
  }

  /// attempt should not evaluate any forms after the first successful form.
  func testAttemptEvaluation() {
    expectThat("(attempt 12345 (.print \"bad\") (.print \"also bad\"))", shouldEvalTo: 12345)
    expectOutputBuffer(toBe: "")
  }

  /// attempt should return an error if none of the forms evaluate successfully.
  func testAttemptFailure() {
    expectThat("(attempt (.+ \\a \\b) (.+) (recur) (.fail \"failed!\"))", shouldFailAs: .RuntimeError)
  }

  /// attempt must take at least one form.
  func testArity() {
    expectArityErrorFrom("(attempt)")
  }
}
