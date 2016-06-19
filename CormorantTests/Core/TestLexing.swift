//
//  TestLexing.swift
//  Cormorant
//
//  Created by Austin Zheng on 1/31/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

class TestLexing : InterpreterTest {

  /// An unfinished string should result in a lexing error.
  func testUnfinishedString() {
    expectThat("\"", shouldFailAs: .NonTerminatedStringError)
    expectThat("\"the quick brown fox", shouldFailAs: .NonTerminatedStringError)
    expectThat("'(1 2 3 \"hello\" \"goodbye \"foo\")", shouldFailAs: .NonTerminatedStringError)
  }

  /// Bad character literals should result in a lexing error.
  func testBadCharacter() {
    // Zero-character escape sequence
    expectThat("\\", shouldFailAs: .InvalidCharacterError)
    // Bad multi-character escape sequence
    expectThat("\\zzz", shouldFailAs: .InvalidCharacterError)
    expectThat("\\1234", shouldFailAs: .InvalidCharacterError)
    expectThat("\\reversebackquote", shouldFailAs: .InvalidCharacterError)
  }

  /// Invalid Unicode character literals should result in a lexing error.
  func testInvalidUnicode() {
    expectThat("\\uF", shouldFailAs: .InvalidUnicodeError)
    expectThat("\\u0F", shouldFailAs: .InvalidUnicodeError)
    expectThat("\\u00F", shouldFailAs: .InvalidUnicodeError)
    expectThat("\\u00Fg", shouldFailAs: .InvalidUnicodeError)
    expectThat("\\u00FFF", shouldFailAs: .InvalidUnicodeError)
    expectThat("\\u00F1!", shouldFailAs: .InvalidUnicodeError)
  }

  /// Invalid octal character literals should result in a lexing error.
  func testInvalidOctal() {
    expectThat("\\o3", shouldFailAs: .InvalidOctalError)
    expectThat("\\o33", shouldFailAs: .InvalidOctalError)
    expectThat("\\o339", shouldFailAs: .InvalidOctalError)
    expectThat("\\o1234", shouldFailAs: .InvalidOctalError)
    expectThat("\\o121g", shouldFailAs: .InvalidOctalError)
    expectThat("\\o400", shouldFailAs: .InvalidOctalError)
  }

  /// Bad escape sequences in strings should result in a lexing error.
  func testBadEscapeSequences() {
    // Bad escape sequence: '\b'
    expectThat("\"foo\\bbar\"", shouldFailAs: .InvalidStringEscapeSequenceError)
    // Bad escape sequence: '\1'
    expectThat("\"hello\\ntest\\1\"", shouldFailAs: .InvalidStringEscapeSequenceError)
  }

  /// Bad dispatch macros should result in a dispatch macro error.
  func testBadDispatchMacros() {
    expectThat("#[", shouldFailAs: .InvalidDispatchMacroError)
    expectThat("#<", shouldFailAs: .InvalidDispatchMacroError)
    expectThat("##", shouldFailAs: .InvalidDispatchMacroError)
    expectThat("#\\", shouldFailAs: .InvalidDispatchMacroError)
    expectThat("#123", shouldFailAs: .InvalidDispatchMacroError)
    expectThat("#abc", shouldFailAs: .InvalidDispatchMacroError)
  }
}
