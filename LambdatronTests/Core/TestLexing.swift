//
//  TestLexing.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/31/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

class TestLexing : InterpreterTest {

  /// Given an input string, evaluate it and expect a particular evaluation failure.
  func expectThat(input: String, shouldFailLexingAs expected: LexError.ErrorType) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(s):
      XCTFail("evaluation unexpectedly succeeded; result: \(s.description)")
    case let .LexFailure(actual):
      let expectedName = expected.rawValue
      let actualName = actual.error.rawValue
      XCTAssert(expected == actual.error, "expected: \(expectedName), got: \(actualName)")
    case .ParseFailure:
      XCTFail("parser error; shouldn't even get here")
    case .ReaderFailure:
      XCTFail("reader error; shouldn't even get here")
    case let .EvalFailure(actual):
      XCTFail("evaluation error; shouldn't even get here")
    }
  }

  /// An unfinished string should result in a lexing error.
  func testUnfinishedString() {
    expectThat("\"", shouldFailLexingAs: .NonTerminatedStringError)
    expectThat("\"the quick brown fox", shouldFailLexingAs: .NonTerminatedStringError)
    expectThat("'(1 2 3 \"hello\" \"goodbye \"foo\")", shouldFailLexingAs: .NonTerminatedStringError)
  }

  /// Bad character literals should result in a lexing error.
  func testBadCharacter() {
    // Zero-character escape sequence
    expectThat("\\", shouldFailLexingAs: .InvalidCharacterError)
    // Bad multi-character escape sequence
    expectThat("\\zzz", shouldFailLexingAs: .InvalidCharacterError)
    expectThat("\\1234", shouldFailLexingAs: .InvalidCharacterError)
    expectThat("\\reversebackquote", shouldFailLexingAs: .InvalidCharacterError)
  }

  /// Bad escape sequences in strings should result in a lexing error.
  func testBadEscapeSequences() {
    // Bad escape sequence: '\b'
    expectThat("\"foo\\bbar\"", shouldFailLexingAs: .InvalidEscapeSequenceError)
    // Bad escape sequence: '\1'
    expectThat("\"hello\\ntest\\1\"", shouldFailLexingAs: .InvalidEscapeSequenceError)
  }
}
