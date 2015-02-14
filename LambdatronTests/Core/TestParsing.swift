//
//  TestParsing.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/17/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

/// Test how nil is lexed and parsed.
class TestNilParsing : InterpreterTest {
  func testParsingNil() {
    expectThat("nil", shouldEvalTo: .Nil)
  }

  /// The lexer and parser should properly parse nil in the context of a collection.
  func testInCollection() {
    expectThat("'(nil nil nil)", shouldEvalTo: listWithItems(.Nil, .Nil, .Nil))
  }
}

/// Test how boolean literals are lexed and parsed.
class TestBoolParsing : InterpreterTest {
  func testParsingTrue() {
    expectThat("true", shouldEvalTo: .BoolAtom(true))
  }

  func testParsingFalse() {
    expectThat("false", shouldEvalTo: .BoolAtom(false))
  }

  /// The lexer and parser should properly parse true and false in the context of a collection.
  func testInCollection() {
    expectThat("'(true true false)", shouldEvalTo: listWithItems(.BoolAtom(true), .BoolAtom(true), .BoolAtom(false)))
  }
}

/// Test how integer literals are lexed and parsed.
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

  /// The lexer and parser should properly parse integers in the context of a collection.
  func testInCollection() {
    expectThat("'(-915 -1 100009)", shouldEvalTo: listWithItems(.IntAtom(-915), .IntAtom(-1), .IntAtom(100009)))
  }
}

/// Test how floating-point literals are lexed and parsed.
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

  /// The lexer and parser should properly parse floating-point numbers in the context of a collection.
  func testInCollection() {
    expectThat("'(0.00012 3190.0 -1234.5)",
      shouldEvalTo: listWithItems(.FloatAtom(0.00012), .FloatAtom(3190.0), .FloatAtom(-1234.5)))
  }
}

/// Test how string literals are lexed and parsed.
class TestStringParsing : InterpreterTest {
  func testParsingEmptyString() {
    expectThat("\"\"", shouldEvalTo: .StringAtom(""))
  }

  func testParsingNonemptyString() {
    expectThat("\"the quick brown fox\"", shouldEvalTo: .StringAtom("the quick brown fox"))
  }

  /// The lexer and parser should properly parse strings in the context of a collection.
  func testInCollection() {
    expectThat("'(\"\" \"foobar\" \"t\")",
      shouldEvalTo: listWithItems(.StringAtom(""), .StringAtom("foobar"), .StringAtom("t")))
  }
}

/// Test parsing of regexes.
class TestRegexParsing : InterpreterTest {

  /// Valid regular expression literals should be successfully lexed and parsed into regex patterns.
  func testParsingNonemptyRegex() {
    expectThat("#\"[0-9]+\"", shouldEvalTo: .Regex(NSRegularExpression(pattern: "[0-9]+", options: nil, error: nil)!))
    // Fancy regex for matching all numbers
    expectThat("#\"^[+-]?(\\\\d+\\\\.?\\\\d*|\\\\.\\\\d+)([eE][+-]?\\\\d+)?$\"",
      shouldEvalTo: .Regex(NSRegularExpression(pattern: "^[+-]?(\\d+\\.?\\d*|\\.\\d+)([eE][+-]?\\d+)?$",
        options: nil, error: nil)!))
  }

  /// The lexer and parser should properly parse regular expressions in the context of a collection.
  func testInCollection() {
    expectThat("[#\"abc\" #\"def\" #\"ghi\"]", shouldEvalTo:
      vectorWithItems(
        .Regex(NSRegularExpression(pattern: "abc", options: nil, error: nil)!),
        .Regex(NSRegularExpression(pattern: "def", options: nil, error: nil)!),
        .Regex(NSRegularExpression(pattern: "ghi", options: nil, error: nil)!)))
  }
}

/// Test how characters are lexed and parsed.
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

  /// The lexer and parser should properly parse characters in the context of a collection.
  func testInCollection() {
    expectThat("'(\\\\ \\newline \\a \\b)",
      shouldEvalTo: listWithItems(.CharAtom("\\"), .CharAtom("\n"), .CharAtom("a"), .CharAtom("b")))
  }
}

/// Test how symbols are lexed and parsed.
class TestSymbolParsing : InterpreterTest {
  /// The lexer and parser should properly parse symbols in the context of a collection.
  func testInCollection() {
    let test123 = interpreter.context.symbolForName("test123")
    let superSymbol = interpreter.context.symbolForName("SUPER-SYMBOL")
    let strange = interpreter.context.symbolForName("___*something!!")
    expectThat("'(test123 SUPER-SYMBOL ___*something!!)",
      shouldEvalTo: listWithItems(.Symbol(test123), .Symbol(superSymbol), .Symbol(strange)))
  }
}

/// Test how keywords are lexed and parsed
class TestKeywordParsing : InterpreterTest {
  /// The lexer and parser should properly parse keywords in the context of a collection.
  func testInCollection() {
    let foo = interpreter.context.keywordForName("foo")
    let elseKw = interpreter.context.keywordForName("else")
    let veryLong = interpreter.context.keywordForName("veryLongKeyword123")
    expectThat("'(:foo :else :veryLongKeyword123)",
      shouldEvalTo: listWithItems(.Keyword(foo), .Keyword(elseKw), .Keyword(veryLong)))
  }
}

/// Test how lists are lexed and parsed.
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

/// Test how vectors are lexed and parsed.
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

/// Test how maps are lexed and parsed.
class TestMapParsing : InterpreterTest {
  func testParsingEmptyMap() {
    expectThat("{}", shouldEvalTo: .Map([:]))
  }

  func testParsingSingleElementMap() {
    expectThat("{\"foo\" 1234}", shouldEvalTo: .Map([.StringAtom("foo"): .IntAtom(1234)]))
  }

  func testParsingMultiElementMap() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.symbolForName("c")
    expectThat("{:a \"a\" :b \\b 'c 3}",
      shouldEvalTo: .Map([.Keyword(a): .StringAtom("a"), .Keyword(b): .CharAtom("b"), .Symbol(c): .IntAtom(3)]))
  }

  func testParsingNestedMap() {
    let a = interpreter.context.keywordForName("a")
    let b = interpreter.context.keywordForName("b")
    let c = interpreter.context.keywordForName("c")
    expectThat("{:a {:b :c 1 2} 3 4}", shouldEvalTo: mapWithItems(
      (.Keyword(a), mapWithItems((.Keyword(b), .Keyword(c)), (.IntAtom(1), .IntAtom(2)))), (.IntAtom(3), .IntAtom(4))))
  }
}

/// Test certain conditions which are expected to lead to parsing failures.
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

  /// Invalid regex patterns, including the empty pattern "", should fail.
  func testInvalidRegexes() {
    expectThat("#\"\"", shouldFailAs: .InvalidRegexError)
    expectThat("#\"abc[[[[\"", shouldFailAs: .InvalidRegexError)
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
