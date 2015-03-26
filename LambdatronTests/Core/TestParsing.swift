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
    expectThat("true", shouldEvalTo: true)
  }

  func testParsingFalse() {
    expectThat("false", shouldEvalTo: false)
  }

  /// The lexer and parser should properly parse true and false in the context of a collection.
  func testInCollection() {
    expectThat("'(true true false)", shouldEvalTo: listWithItems(true, true, false))
  }
}

/// Test how integer literals are lexed and parsed.
class TestIntegerParsing : InterpreterTest {
  func testParsingZero() {
    expectThat("0", shouldEvalTo: 0)
  }

  func testParsingPositiveNumber() {
    expectThat("501", shouldEvalTo: 501)
  }

  func testParsingNegativeNumber() {
    expectThat("-9182", shouldEvalTo: -9182)
  }

  /// The lexer and parser should properly parse integers in the context of a collection.
  func testInCollection() {
    expectThat("'(-915 -1 100009)", shouldEvalTo: listWithItems(-915, -1, 100009))
  }
}

/// Test how floating-point literals are lexed and parsed.
class TestFloatingPointParsing : InterpreterTest {
  func testParsingZero() {
    expectThat("0.0", shouldEvalTo: 0.0)
  }

  func testParsingPositiveNumber() {
    expectThat("3.141592", shouldEvalTo: 3.141592)
  }

  func testParsingNegativeNumber() {
    expectThat("-29128.6812", shouldEvalTo: -29128.6812)
  }

  /// The lexer and parser should properly parse floating-point numbers in the context of a collection.
  func testInCollection() {
    expectThat("'(0.00012 3190.0 -1234.5)", shouldEvalTo: listWithItems(0.00012, 3190.0, -1234.5))
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
    expectThat("#\"[0-9]+\"",
      shouldEvalTo: .Auxiliary(NSRegularExpression(pattern: "[0-9]+", options: nil, error: nil)!))
    // Fancy regex for matching all numbers
    expectThat("#\"^[+-]?(\\d+\\.?\\d*|\\.\\d+)([eE][+-]?\\d+)?$\"",
      shouldEvalTo: .Auxiliary(NSRegularExpression(pattern: "^[+-]?(\\d+\\.?\\d*|\\.\\d+)([eE][+-]?\\d+)?$",
        options: nil, error: nil)!))
  }

  /// The lexer and parser should properly parse regular expressions in the context of a collection.
  func testInCollection() {
    expectThat("[#\"abc\" #\"def\" #\"ghi\"]", shouldEvalTo:
      vectorWithItems(
        .Auxiliary(NSRegularExpression(pattern: "abc", options: nil, error: nil)!),
        .Auxiliary(NSRegularExpression(pattern: "def", options: nil, error: nil)!),
        .Auxiliary(NSRegularExpression(pattern: "ghi", options: nil, error: nil)!)))
  }
}

/// Test how characters are lexed and parsed.
class TestCharacterParsing : InterpreterTest {
  /// Characters should be properly parsed.
  func testParsingBasicCharacter() {
    expectThat("\\z", shouldEvalTo: .CharAtom("z"))
    expectThat("\\o", shouldEvalTo: .CharAtom("o"))
    expectThat("\\u", shouldEvalTo: .CharAtom("u"))
    expectThat("\\5", shouldEvalTo: .CharAtom("5"))
    expectThat("\\!", shouldEvalTo: .CharAtom("!"))
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

  /// Unicode character literals should parse correctly.
  func testUnicodeChars() {
    expectThat("\\u0024", shouldEvalTo: .CharAtom("$"))
    expectThat("\\u00f2", shouldEvalTo: .CharAtom("ò"))
    expectThat("\\u00aB", shouldEvalTo: .CharAtom("«"))
  }

  /// Octal character literals should parse correctly.
  func testOctalChars() {
    expectThat("\\o045", shouldEvalTo: .CharAtom("%"))
    expectThat("\\o164", shouldEvalTo: .CharAtom("t"))
    expectThat("\\o377", shouldEvalTo: .CharAtom("ÿ"))
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
    let test123 = symbol("test123")
    let superSymbol = symbol("SUPER-SYMBOL")
    let strange = symbol("___*something!!")
    expectThat("'(test123 SUPER-SYMBOL ___*something!!)",
      shouldEvalTo: listWithItems(.Symbol(test123), .Symbol(superSymbol), .Symbol(strange)))
  }

  /// The parser should correctly parse explicitly-qualified symbols.
  func testQualified() {
    let expected = symbol("jyaku", namespace: "bar")
    expectThat("'bar/jyaku", shouldEvalTo: .Symbol(expected))
  }

  /// The parser should correctly parse symbols with more than one forward slash.
  func testLongQualified() {
    let expected = symbol("bar/baz", namespace: "foo")
    expectThat("'foo/bar/baz", shouldEvalTo: .Symbol(expected))
  }
}

/// Test how keywords are lexed and parsed.
class TestKeywordParsing : InterpreterTest {
  /// The lexer and parser should properly parse keywords in the context of a collection.
  func testInCollection() {
    let foo = keyword("foo")
    let elseKw = keyword("else")
    let veryLong = keyword("veryLongKeyword123")
    expectThat("'(:foo :else :veryLongKeyword123)",
      shouldEvalTo: listWithItems(.Keyword(foo), .Keyword(elseKw), .Keyword(veryLong)))
  }

  /// The lexer and parser should correctly parse locally-qualified keywords (those that begin with a "::").
  func testLocallyQualified() {
    runCode("(.ns-set 'foo)")
    let expected = keyword("meela", namespace: "foo")
    expectThat("::meela", shouldEvalTo: .Keyword(expected))
  }

  /// The parser should correctly parse explicitly-qualified keywords.
  func testQualified() {
    let expected = keyword("meela", namespace: "foo")
    expectThat(":foo/meela", shouldEvalTo: .Keyword(expected))
  }

  /// The parser should correctly parse keywords with more than one forward slash.
  func testLongQualified() {
    let expected = keyword("bar/baz", namespace: "foo")
    expectThat(":foo/bar/baz", shouldEvalTo: .Keyword(expected))
  }
}

/// Test how lists are lexed and parsed.
class TestListParsing : InterpreterTest {
  func testParsingEmptyList() {
    expectThat("()", shouldEvalTo: .Seq(EmptyNode))
  }

  func testParsingNilList() {
    expectThat("'(nil)", shouldEvalTo: .Seq(sequence(.Nil)))
  }

  /// Single element lists should be properly parsed.
  func testParsingSingleElementList() {
    expectThat("'(\"hello world\")", shouldEvalTo: listWithItems(ConsValue.StringAtom("hello world")))
  }

  func testParsingMultiElementList() {
    expectThat("'(true false nil)", shouldEvalTo: listWithItems(true, false, .Nil))
  }

  func testParsingNestedList() {
    // Piece together the final list, since it's too ugly to be constructed as a single literal
    // The target list is ((1 2) (3.14 (4 5) 6) 7)
    let list = listWithItems(listWithItems(1, 2), listWithItems(3.14, listWithItems(4, 5), 6), 7)
    expectThat("'((1 2) (3.14 (4 5) 6) 7)", shouldEvalTo: list)
  }
}

/// Test how vectors are lexed and parsed.
class TestVectorParsing : InterpreterTest {
  func testParsingEmptyVector() {
    expectThat("[]", shouldEvalTo: .Vector([]))
  }

  func testParsingSingleElementVector() {
    expectThat("[123]", shouldEvalTo: .Vector([123]))
  }

  func testParsingMultiElementVector() {
    expectThat("[1 2 nil true \"hello\" \\c]",
      shouldEvalTo: .Vector([1, 2, .Nil, true, .StringAtom("hello"), .CharAtom("c")]))
  }

  func testParsingNestedVector() {
    expectThat("[[1 2] [3.14 [4 5] 6] 7]",
      shouldEvalTo: .Vector([.Vector([1, 2]), .Vector([3.14, .Vector([4, 5]), 6]), 7]))
  }
}

/// Test how maps are lexed and parsed.
class TestMapParsing : InterpreterTest {
  func testParsingEmptyMap() {
    expectThat("{}", shouldEvalTo: .Map([:]))
  }

  func testParsingSingleElementMap() {
    expectThat("{\"foo\" 1234}", shouldEvalTo: .Map([.StringAtom("foo"): 1234]))
  }

  func testParsingMultiElementMap() {
    let a = keyword("a")
    let b = keyword("b")
    let c = symbol("c")
    expectThat("{:a \"a\" :b \\b 'c 3}",
      shouldEvalTo: .Map([.Keyword(a): .StringAtom("a"), .Keyword(b): .CharAtom("b"), .Symbol(c): 3]))
  }

  func testParsingNestedMap() {
    let a = keyword("a")
    let b = keyword("b")
    let c = keyword("c")
    expectThat("{:a {:b :c 1 2} 3 4}", shouldEvalTo:
      mapWithItems((.Keyword(a), mapWithItems((.Keyword(b), .Keyword(c)), (1, 2))), (3, 4)))
  }
}

/// Test certain conditions which are expected to lead to parsing failures.
class TestParsingFailure : InterpreterTest {

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
