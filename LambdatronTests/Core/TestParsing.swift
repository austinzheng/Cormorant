//
//  TestParsing.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/17/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

class TestNilParsing : InterpreterTest {
  func testParsingNil() {
    expectThat("nil", shouldEvalTo: .NilLiteral)
  }
}

class TestBoolParsing : InterpreterTest {
  func testParsingTrue() {
    expectThat("true", shouldEvalTo: .BoolLiteral(true))
  }

  func testParsingFalse() {
    expectThat("false", shouldEvalTo: .BoolLiteral(false))
  }
}

class TestIntegerParsing : InterpreterTest {
  func testParsingZero() {
    expectThat("0", shouldEvalTo: .IntegerLiteral(0))
  }

  func testParsingPositiveNumber() {
    expectThat("501", shouldEvalTo: .IntegerLiteral(501))
  }

  func testParsingNegativeNumber() {
    expectThat("-9182", shouldEvalTo: .IntegerLiteral(-9182))
  }
}

class TestFloatingPointParsing : InterpreterTest {
  func testParsingZero() {
    expectThat("0.0", shouldEvalTo: .FloatLiteral(0.0))
  }

  func testParsingPositiveNumber() {
    expectThat("3.141592", shouldEvalTo: .FloatLiteral(3.141592))
  }

  func testParsingNegativeNumber() {
    expectThat("-29128.6812", shouldEvalTo: .FloatLiteral(-29128.6812))
  }
}

class TestStringParsing : InterpreterTest {
  func testParsingEmptyString() {
    expectThat("\"\"", shouldEvalTo: .StringLiteral(""))
  }

  func testParsingNonemptyString() {
    expectThat("\"the quick brown fox\"", shouldEvalTo: .StringLiteral("the quick brown fox"))
  }
}

class TestCharacterParsing : InterpreterTest {
  func testParsingBasicCharacter() {
    expectThat("\\z", shouldEvalTo: .CharacterLiteral("z"))
  }

  func testParsingBackslash() {
    expectThat("\\\\", shouldEvalTo: .CharacterLiteral("\\"))
  }

  func testParsingTab() {
    expectThat("\\tab", shouldEvalTo: .CharacterLiteral("\t"))
  }

  func testParsingSpace() {
    expectThat("\\space", shouldEvalTo: .CharacterLiteral(" "))
  }

  func testParsingNewline() {
    expectThat("\\newline", shouldEvalTo: .CharacterLiteral("\n"))
  }

  func testParsingReturn() {
    expectThat("\\return", shouldEvalTo: .CharacterLiteral("\r"))
  }
}

class TestListParsing : InterpreterTest {
  // TODO
}

class TestVectorParsing : InterpreterTest {
  // TODO
}

class TestMapParsing : InterpreterTest {
  // TODO
}
