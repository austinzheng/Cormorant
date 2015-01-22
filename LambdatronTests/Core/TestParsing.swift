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
  /// Characters should be properly parsed.
  func testParsingBasicCharacter() {
    expectThat("\\z", shouldEvalTo: .CharacterLiteral("z"))
  }

  /// The backslash character '\\' should be properly parsed.
  func testParsingBackslash() {
    expectThat("\\\\", shouldEvalTo: .CharacterLiteral("\\"))
  }

  /// The tab character should be properly parsed.
  func testParsingTab() {
    expectThat("\\tab", shouldEvalTo: .CharacterLiteral("\t"))
  }

  /// The space character should be properly parsed.
  func testParsingSpace() {
    expectThat("\\space", shouldEvalTo: .CharacterLiteral(" "))
  }

  /// The newline character should be properly parsed.
  func testParsingNewline() {
    expectThat("\\newline", shouldEvalTo: .CharacterLiteral("\n"))
  }

  /// The return character should be properly parsed.
  func testParsingReturn() {
    expectThat("\\return", shouldEvalTo: .CharacterLiteral("\r"))
  }

  /// The formfeed character should be properly parsed.
  func testParsingFormfeed() {
    let formfeed = Character(UnicodeScalar(12))
    expectThat("\\formfeed", shouldEvalTo: .CharacterLiteral(formfeed))
  }

  /// The backspace character should be properly parsed.
  func testParsingBackspace() {
    let backspace = Character(UnicodeScalar(8))
    expectThat("\\backspace", shouldEvalTo: .CharacterLiteral(backspace))
  }
}

class TestListParsing : InterpreterTest {
  func testParsingEmptyList() {
    expectThat("'()", shouldEvalTo: .ListLiteral(Cons()))
  }

  func testParsingNilList() {
    expectThat("'(nil)", shouldEvalTo: .ListLiteral(Cons(.NilLiteral)))
  }

  /// Single element lists should be properly parsed.
  func testParsingSingleElementList() {
    expectThat("'(\"hello world\")", shouldEvalTo: .ListLiteral(Cons(.StringLiteral("hello world"))))
  }

  func testParsingMultiElementList() {
    expectThat("'(true false nil)",
      shouldEvalTo: .ListLiteral(Cons(.BoolLiteral(true), next: Cons(.BoolLiteral(false), next: Cons(.NilLiteral)))))
  }

  func testParsingNestedList() {
    // Piece together the final list, since it's too ugly to be constructed as a single literal
    // The target list is ((1 2) (3.14 (4 5) 6) 7)
    let oneTwoList = Cons(.IntegerLiteral(1), next: Cons(.IntegerLiteral(2)))
    let fourFiveList = Cons(.IntegerLiteral(4), next: Cons(.IntegerLiteral(5)))
    let piList = Cons(.FloatLiteral(3.14), next: Cons(.ListLiteral(fourFiveList), next: Cons(.IntegerLiteral(6))))
    let fullList = Cons(.ListLiteral(oneTwoList), next: Cons(.ListLiteral(piList), next: Cons(.IntegerLiteral(7))))

    expectThat("'((1 2) (3.14 (4 5) 6) 7)", shouldEvalTo: .ListLiteral(fullList))
  }
}

class TestVectorParsing : InterpreterTest {
  func testParsingEmptyVector() {
    expectThat("[]", shouldEvalTo: .VectorLiteral([]))
  }

  func testParsingSingleElementVector() {
    expectThat("[123]", shouldEvalTo: .VectorLiteral([.IntegerLiteral(123)]))
  }

  func testParsingMultiElementVector() {
    expectThat("[1 2 nil true \"hello\" \\c]",
      shouldEvalTo: .VectorLiteral(
        [.IntegerLiteral(1),
          .IntegerLiteral(2),
          .NilLiteral,
          .BoolLiteral(true),
          .StringLiteral("hello"),
          .CharacterLiteral("c")]))
  }

  func testParsingNestedVector() {
    expectThat("[[1 2] [3.14 [4 5] 6] 7]",
      shouldEvalTo: .VectorLiteral(
        [.VectorLiteral([.IntegerLiteral(1), .IntegerLiteral(2)]),
          .VectorLiteral(
            [.FloatLiteral(3.14),
              .VectorLiteral([.IntegerLiteral(4), .IntegerLiteral(5)]),
              .IntegerLiteral(6)]),
          .IntegerLiteral(7)]))
  }
}

class TestMapParsing : InterpreterTest {
  // TODO
}
