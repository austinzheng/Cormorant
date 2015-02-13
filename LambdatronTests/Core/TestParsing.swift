//
//  TestParsing.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/17/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

class TestNilParsing : InterpreterTest {
  func testParsingNil() {
    expectThat("nil", shouldEvalTo: .Nil)
  }
}

class TestBoolParsing : InterpreterTest {
  func testParsingTrue() {
    expectThat("true", shouldEvalTo: .BoolAtom(true))
  }

  func testParsingFalse() {
    expectThat("false", shouldEvalTo: .BoolAtom(false))
  }
}

class TestIntegerParsing : InterpreterTest {
  func testParsingZero() {
    expectThat("0", shouldEvalTo: .IntAtom(0))
  }

  func testParsingPositiveNumber() {
    expectThat("501", shouldEvalTo: .IntAtom(501))
  }

  func testParsingNegativeNumber() {
    expectThat("-9182", shouldEvalTo: .IntAtom(-9182))
  }
}

class TestFloatingPointParsing : InterpreterTest {
  func testParsingZero() {
    expectThat("0.0", shouldEvalTo: .FloatAtom(0.0))
  }

  func testParsingPositiveNumber() {
    expectThat("3.141592", shouldEvalTo: .FloatAtom(3.141592))
  }

  func testParsingNegativeNumber() {
    expectThat("-29128.6812", shouldEvalTo: .FloatAtom(-29128.6812))
  }
}

class TestStringParsing : InterpreterTest {
  func testParsingEmptyString() {
    expectThat("\"\"", shouldEvalTo: .StringAtom(""))
  }

  func testParsingNonemptyString() {
    expectThat("\"the quick brown fox\"", shouldEvalTo: .StringAtom("the quick brown fox"))
  }
}

class TestCharacterParsing : InterpreterTest {
  /// Characters should be properly parsed.
  func testParsingBasicCharacter() {
    expectThat("\\z", shouldEvalTo: .CharAtom("z"))
  }

  /// The backslash character '\\' should be properly parsed.
  func testParsingBackslash() {
    expectThat("\\\\", shouldEvalTo: .CharAtom("\\"))
  }

  /// The tab character should be properly parsed.
  func testParsingTab() {
    expectThat("\\tab", shouldEvalTo: .CharAtom("\t"))
  }

  /// The space character should be properly parsed.
  func testParsingSpace() {
    expectThat("\\space", shouldEvalTo: .CharAtom(" "))
  }

  /// The newline character should be properly parsed.
  func testParsingNewline() {
    expectThat("\\newline", shouldEvalTo: .CharAtom("\n"))
  }

  /// The return character should be properly parsed.
  func testParsingReturn() {
    expectThat("\\return", shouldEvalTo: .CharAtom("\r"))
  }

  /// The formfeed character should be properly parsed.
  func testParsingFormfeed() {
    let formfeed = Character(UnicodeScalar(12))
    expectThat("\\formfeed", shouldEvalTo: .CharAtom(formfeed))
  }

  /// The backspace character should be properly parsed.
  func testParsingBackspace() {
    let backspace = Character(UnicodeScalar(8))
    expectThat("\\backspace", shouldEvalTo: .CharAtom(backspace))
  }
}

class TestListParsing : InterpreterTest {
  func testParsingEmptyList() {
    expectThat("()", shouldEvalTo: .List(Empty()))
  }

  func testParsingNilList() {
    expectThat("'(nil)", shouldEvalTo: .List(Cons(.Nil)))
  }

  /// Single element lists should be properly parsed.
  func testParsingSingleElementList() {
    expectThat("'(\"hello world\")", shouldEvalTo: .List(Cons(.StringAtom("hello world"))))
  }

  func testParsingMultiElementList() {
    expectThat("'(true false nil)",
      shouldEvalTo: .List(Cons(.BoolAtom(true), next: Cons(.BoolAtom(false), next: Cons(.Nil)))))
  }

  func testParsingNestedList() {
    // Piece together the final list, since it's too ugly to be constructed as a single literal
    // The target list is ((1 2) (3.14 (4 5) 6) 7)
    let oneTwoList : ListType<ConsValue> = Cons(.IntAtom(1), next: Cons(.IntAtom(2)))
    let fourFiveList : ListType<ConsValue> = Cons(.IntAtom(4), next: Cons(.IntAtom(5)))
    let piList : ListType<ConsValue> = Cons(.FloatAtom(3.14),
      next: Cons(.List(fourFiveList), next: Cons(.IntAtom(6))))
    let fullList : ListType<ConsValue> = Cons(.List(oneTwoList),
      next: Cons(.List(piList), next: Cons(.IntAtom(7))))

    expectThat("'((1 2) (3.14 (4 5) 6) 7)", shouldEvalTo: .List(fullList))
  }
}

class TestVectorParsing : InterpreterTest {
  func testParsingEmptyVector() {
    expectThat("[]", shouldEvalTo: .Vector([]))
  }

  func testParsingSingleElementVector() {
    expectThat("[123]", shouldEvalTo: .Vector([.IntAtom(123)]))
  }

  func testParsingMultiElementVector() {
    expectThat("[1 2 nil true \"hello\" \\c]",
      shouldEvalTo: .Vector(
        [.IntAtom(1),
          .IntAtom(2),
          .Nil,
          .BoolAtom(true),
          .StringAtom("hello"),
          .CharAtom("c")]))
  }

  func testParsingNestedVector() {
    expectThat("[[1 2] [3.14 [4 5] 6] 7]",
      shouldEvalTo: .Vector(
        [.Vector([.IntAtom(1), .IntAtom(2)]),
          .Vector(
            [.FloatAtom(3.14),
              .Vector([.IntAtom(4), .IntAtom(5)]),
              .IntAtom(6)]),
          .IntAtom(7)]))
  }
}

class TestMapParsing : InterpreterTest {
  // TODO
}

class TestParsingFailure : InterpreterTest {

  func expectThat(input: String, shouldFailAs expected: ParseError.ErrorType) {
    let result = interpreter.evaluate(input)
    switch result {
    case let .Success(s):
      XCTFail("evaluation unexpectedly succeeded; result: \(s.description)")
    case .LexFailure:
      XCTFail("lexer error")
    case let .ParseFailure(actual):
      let expectedName = expected.rawValue
      let actualName = actual.error.rawValue
      XCTAssert(expected == actual.error, "expected: \(expectedName), got: \(actualName)")
    case .ReaderFailure:
      XCTFail("reader error")
    case let .EvalFailure(actual):
      XCTFail("evaluation error")
    }
  }

  func testEmptyInput() {
    expectThat("", shouldFailAs: .EmptyInputError)
  }

  func testMismatchedParen() {
    expectThat("(", shouldFailAs: .MismatchedDelimiterError)
    expectThat("(a (1 2)", shouldFailAs: .MismatchedDelimiterError)
  }

  func testMismatchedBracket() {
    expectThat("[", shouldFailAs: .MismatchedDelimiterError)
    expectThat("[a [1 2]", shouldFailAs: .MismatchedDelimiterError)
  }

  func testMismatchedBrace() {
    expectThat("{", shouldFailAs: .MismatchedDelimiterError)
    expectThat("{:key {:key :value}", shouldFailAs: .MismatchedDelimiterError)
  }

  func testBadStartToken() {
    expectThat(")", shouldFailAs: .BadStartTokenError)
    expectThat("]", shouldFailAs: .BadStartTokenError)
    expectThat("}", shouldFailAs: .BadStartTokenError)
  }

  func testMismatchedQuote() {
    expectThat("'", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("(a b ')", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("[a b ']", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("{:key '}", shouldFailAs: .MismatchedReaderMacroError)
  }

  func testMismatchedSyntaxQuote() {
    expectThat("`", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("(a b `)", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("[a b `]", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("{:key `}", shouldFailAs: .MismatchedReaderMacroError)
  }

  func testMismatchedUnquote() {
    expectThat("~", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("`(a b ~)", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("`[a b ~]", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("`{:key ~}", shouldFailAs: .MismatchedReaderMacroError)
  }

  func testMismatchedUnquoteSplice() {
    expectThat("~@", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("`(a b ~@)", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("`[a b ~@]", shouldFailAs: .MismatchedReaderMacroError)
    expectThat("`{:key ~@}", shouldFailAs: .MismatchedReaderMacroError)
  }

  func testMismatchedMapItems() {
    expectThat("{:key}", shouldFailAs: .MapKeyValueMismatchError)
    expectThat("{:key1 :value1 :key2}", shouldFailAs: .MapKeyValueMismatchError)
  }
}
