//
//  TestStr.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/23/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the '.str' built-in form.
class TestStrBuiltin : InterpreterTest {
  
  /// .str with no arguments should return the empty string.
  func testNoArgs() {
    expectThat("(.str)", shouldEvalTo: .StringAtom(""))
  }

  /// .str should describe nil as the empty string.
  func testNil() {
    expectThat("(.str nil)", shouldEvalTo: .StringAtom(""))
  }

  /// .str should describe booleans properly.
  func testBools() {
    expectThat("(.str true)", shouldEvalTo: .StringAtom("true"))
    expectThat("(.str false)", shouldEvalTo: .StringAtom("false"))
  }

  /// .str should describe strings as themselves.
  func testStrings() {
    expectThat("(.str \"\")", shouldEvalTo: .StringAtom(""))
    expectThat("(.str \"z\")", shouldEvalTo: .StringAtom("z"))
    expectThat("(.str \"foobar\")", shouldEvalTo: .StringAtom("foobar"))
    expectThat("(.str \"hello world\")", shouldEvalTo: .StringAtom("hello world"))
  }

  /// .str should describe strings as themselves, with escaping when necessary.
  func testStringsAndEscaping() {
    expectThat("(.str \"foo\\nbar\")", shouldEvalTo: .StringAtom("foo\nbar"))
    expectThat("(.str \"foo\\\"\\\\bar\\n\")", shouldEvalTo: .StringAtom("foo\"\\bar\n"))
  }

  /// .str should describe regex patterns as the pattern string.
  func testRegex() {
    expectThat("(.str #\"abc\")", shouldEvalTo: .StringAtom("abc"))
    expectThat("(.str #\"[0-9]+\")", shouldEvalTo: .StringAtom("[0-9]+"))
    expectThat("(.str #\"(?x) #hello 123\")", shouldEvalTo: .StringAtom("(?x) #hello 123"))
  }

  /// .str should describe characters as themselves.
  func testCharacters() {
    expectThat("(.str \\n)", shouldEvalTo: .StringAtom("n"))
    expectThat("(.str \\!)", shouldEvalTo: .StringAtom("!"))
    expectThat("(.str \\newline)", shouldEvalTo: .StringAtom("\n"))
    expectThat("(.str \\return)", shouldEvalTo: .StringAtom("\r"))
  }

  /// .str should properly describe keywords.
  func testKeywords() {
    expectThat("(.str :a)", shouldEvalTo: .StringAtom(":a"))
    expectThat("(.str :longKeyword)", shouldEvalTo: .StringAtom(":longKeyword"))
  }

  /// .str should properly describe symbols.
  func testSymbols() {
    expectThat("(.str 'z)", shouldEvalTo: .StringAtom("z"))
    expectThat("(.str 'veryLongSymbol)", shouldEvalTo: .StringAtom("veryLongSymbol"))
  }

  /// .str should properly describe integers.
  func testInts() {
    expectThat("(.str 152)", shouldEvalTo: .StringAtom("152"))
    expectThat("(.str -9981)", shouldEvalTo: .StringAtom("-9981"))
  }

  /// .str should properly describe floating-point numbers.
  func testFloats() {
    expectThat("(.str 0.001238)", shouldEvalTo: .StringAtom("0.001238"))
    expectThat("(.str -9581.928)", shouldEvalTo: .StringAtom("-9581.928"))
  }

  /// .str should properly describe single element lists.
  func testSingleElementLists() {
    // Note that in Clojure, "(str ())" evaluates to some interned empty list instance instead of "()".
    expectThat("(.str ())", shouldEvalTo: .StringAtom("()"))
    expectThat("(.str '(nil))", shouldEvalTo: .StringAtom("(nil)"))
    expectThat("(.str '(152))", shouldEvalTo: .StringAtom("(152)"))
    expectThat("(.str '(65.192))", shouldEvalTo: .StringAtom("(65.192)"))
    expectThat("(.str '(true))", shouldEvalTo: .StringAtom("(true)"))
    expectThat("(.str '(\"foobar\"))", shouldEvalTo: .StringAtom("(\"foobar\")"))
    expectThat("(.str '(\"foo\\nbar\"))", shouldEvalTo: .StringAtom("(\"foo\\nbar\")"))
    expectThat("(.str '(#\"[0-9]\"))", shouldEvalTo: .StringAtom("(#\"[0-9]\")"))
    expectThat("(.str '(\\a))", shouldEvalTo: .StringAtom("(\\a)"))
    expectThat("(.str '(:foobar))", shouldEvalTo: .StringAtom("(:foobar)"))
    expectThat("(.str '(foobar))", shouldEvalTo: .StringAtom("(foobar)"))
  }

  /// .str should properly describe multi-element lists.
  func testMultiElementLists() {
    expectThat("(.str '(a \"b\\n\" :c))", shouldEvalTo: .StringAtom("(a \"b\\n\" :c)"))
    expectThat("(.str '(\"foo\" (\"ba\\nr\" (\"baz\"))))",
      shouldEvalTo: .StringAtom("(\"foo\" (\"ba\\nr\" (\"baz\")))"))
  }

  /// .str should properly describe single element vectors.
  func testSingleElementVectors() {
    expectThat("(.str [])", shouldEvalTo: .StringAtom("[]"))
    expectThat("(.str [nil])", shouldEvalTo: .StringAtom("[nil]"))
    expectThat("(.str [152])", shouldEvalTo: .StringAtom("[152]"))
    expectThat("(.str [65.192])", shouldEvalTo: .StringAtom("[65.192]"))
    expectThat("(.str [true])", shouldEvalTo: .StringAtom("[true]"))
    expectThat("(.str [\"foobar\"])", shouldEvalTo: .StringAtom("[\"foobar\"]"))
    expectThat("(.str [#\"[0-9]\"])", shouldEvalTo: .StringAtom("[#\"[0-9]\"]"))
    expectThat("(.str [\\a])", shouldEvalTo: .StringAtom("[\\a]"))
    expectThat("(.str [:foobar])", shouldEvalTo: .StringAtom("[:foobar]"))
    expectThat("(.str ['foobar])", shouldEvalTo: .StringAtom("[foobar]"))
  }

  /// .str should properly describe multi-element vectors.
  func testMultiElementVectors() {
    expectThat("(.str ['a \"b\\n\" :c])", shouldEvalTo: .StringAtom("[a \"b\\n\" :c]"))
    expectThat("(.str [\"foo\" [\"ba\\nr\" [\"baz\"]]])",
      shouldEvalTo: .StringAtom("[\"foo\" [\"ba\\nr\" [\"baz\"]]]"))
  }

  /// .str should properly describe maps.
  func testMaps() {
    expectThat("(.str {})", shouldEvalTo: .StringAtom("{}"))
    expectThat("(.str {:foo \"foo\" 'bar \\c})",
      shouldEvalTo: .StringAtom("{bar \\c, :foo \"foo\"}"))
    expectThat("(.str {152 {\"foo\" \\f} true nil false '(\"bar\" baz)})",
      shouldEvalTo: .StringAtom("{152 {\"foo\" \\f}, false (\"bar\" baz), true nil}"))
  }

  /// .str should properly concatenate items.
  func testConcatenation() {
    expectThat("(.str \"foo\" \"bar\" \"baz\")", shouldEvalTo: .StringAtom("foobarbaz"))
    expectThat("(.str \\a 1523 true nil :meela 'jyaku \\1 2)",
      shouldEvalTo: .StringAtom("a1523true:meelajyaku12"))
  }
}
