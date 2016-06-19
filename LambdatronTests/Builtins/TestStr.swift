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
    expectThat("(.str)", shouldEvalTo: .string(""))
  }

  /// .str should describe nil as the empty string.
  func testNil() {
    expectThat("(.str nil)", shouldEvalTo: .string(""))
  }

  /// .str should describe booleans properly.
  func testBools() {
    expectThat("(.str true)", shouldEvalTo: .string("true"))
    expectThat("(.str false)", shouldEvalTo: .string("false"))
  }

  /// .str should describe strings as themselves.
  func testStrings() {
    expectThat("(.str \"\")", shouldEvalTo: .string(""))
    expectThat("(.str \"z\")", shouldEvalTo: .string("z"))
    expectThat("(.str \"foobar\")", shouldEvalTo: .string("foobar"))
    expectThat("(.str \"hello world\")", shouldEvalTo: .string("hello world"))
  }

  /// .str should describe strings as themselves, with escaping when necessary.
  func testStringsAndEscaping() {
    expectThat("(.str \"foo\\nbar\")", shouldEvalTo: .string("foo\nbar"))
    expectThat("(.str \"foo\\\"\\\\bar\\n\")", shouldEvalTo: .string("foo\"\\bar\n"))
  }

  /// .str should describe regex patterns as the pattern string.
  func testRegex() {
    expectThat("(.str #\"abc\")", shouldEvalTo: .string("abc"))
    expectThat("(.str #\"[0-9]+\")", shouldEvalTo: .string("[0-9]+"))
    expectThat("(.str #\"(?x) #hello 123\")", shouldEvalTo: .string("(?x) #hello 123"))
  }

  /// .str should properly convert string builders into strings.
  func testStringBuilders() {
    run(input: "(def a (.sb))")
    expectThat("(.str a)", shouldEvalTo: .string(""))
    run(input: "(def b (.sb \"foobar\"))")
    expectThat("(.str b)", shouldEvalTo: .string("foobar"))
    run(input: "(def c (.sb \"foo\"))")
    run(input: "(.sb-append c \" bar\")")
    run(input: "(.sb-append c \" baz\")")
    run(input: "(.sb-reverse c)")
    expectThat("(.str c)", shouldEvalTo: .string("zab rab oof"))
  }

  /// .str should describe characters as themselves.
  func testCharacters() {
    expectThat("(.str \\n)", shouldEvalTo: .string("n"))
    expectThat("(.str \\!)", shouldEvalTo: .string("!"))
    expectThat("(.str \\newline)", shouldEvalTo: .string("\n"))
    expectThat("(.str \\return)", shouldEvalTo: .string("\r"))
  }

  /// .str should properly describe keywords.
  func testKeywords() {
    expectThat("(.str :a)", shouldEvalTo: .string(":a"))
    expectThat("(.str :longKeyword)", shouldEvalTo: .string(":longKeyword"))
  }

  /// .str should properly describe symbols.
  func testSymbols() {
    expectThat("(.str 'z)", shouldEvalTo: .string("z"))
    expectThat("(.str 'veryLongSymbol)", shouldEvalTo: .string("veryLongSymbol"))
  }

  /// .str should properly describe integers.
  func testInts() {
    expectThat("(.str 152)", shouldEvalTo: .string("152"))
    expectThat("(.str -9981)", shouldEvalTo: .string("-9981"))
  }

  /// .str should properly describe floating-point numbers.
  func testFloats() {
    expectThat("(.str 0.001238)", shouldEvalTo: .string("0.001238"))
    expectThat("(.str -9581.928)", shouldEvalTo: .string("-9581.928"))
  }

  /// .str should properly describe single element lists.
  func testSingleElementLists() {
    // Note that in Clojure, "(str ())" evaluates to some interned empty list instance instead of "()".
    expectThat("(.str ())", shouldEvalTo: .string("()"))
    expectThat("(.str '(nil))", shouldEvalTo: .string("(nil)"))
    expectThat("(.str '(152))", shouldEvalTo: .string("(152)"))
    expectThat("(.str '(65.192))", shouldEvalTo: .string("(65.192)"))
    expectThat("(.str '(true))", shouldEvalTo: .string("(true)"))
    expectThat("(.str '(\"foobar\"))", shouldEvalTo: .string("(\"foobar\")"))
    expectThat("(.str '(\"foo\\nbar\"))", shouldEvalTo: .string("(\"foo\\nbar\")"))
    expectThat("(.str '(#\"[0-9]\"))", shouldEvalTo: .string("(#\"[0-9]\")"))
    expectThat("(.str '(\\a))", shouldEvalTo: .string("(\\a)"))
    expectThat("(.str '(:foobar))", shouldEvalTo: .string("(:foobar)"))
    expectThat("(.str '(foobar))", shouldEvalTo: .string("(foobar)"))
  }

  /// .str should properly describe multi-element lists.
  func testMultiElementLists() {
    expectThat("(.str '(a \"b\\n\" :c))", shouldEvalTo: .string("(a \"b\\n\" :c)"))
    expectThat("(.str '(\"foo\" (\"ba\\nr\" (\"baz\"))))",
      shouldEvalTo: .string("(\"foo\" (\"ba\\nr\" (\"baz\")))"))
  }

  /// .str should properly describe single element vectors.
  func testSingleElementVectors() {
    expectThat("(.str [])", shouldEvalTo: .string("[]"))
    expectThat("(.str [nil])", shouldEvalTo: .string("[nil]"))
    expectThat("(.str [152])", shouldEvalTo: .string("[152]"))
    expectThat("(.str [65.192])", shouldEvalTo: .string("[65.192]"))
    expectThat("(.str [true])", shouldEvalTo: .string("[true]"))
    expectThat("(.str [\"foobar\"])", shouldEvalTo: .string("[\"foobar\"]"))
    expectThat("(.str [#\"[0-9]\"])", shouldEvalTo: .string("[#\"[0-9]\"]"))
    expectThat("(.str [\\a])", shouldEvalTo: .string("[\\a]"))
    expectThat("(.str [:foobar])", shouldEvalTo: .string("[:foobar]"))
    expectThat("(.str ['foobar])", shouldEvalTo: .string("[foobar]"))
  }

  /// .str should properly describe multi-element vectors.
  func testMultiElementVectors() {
    expectThat("(.str ['a \"b\\n\" :c])", shouldEvalTo: .string("[a \"b\\n\" :c]"))
    expectThat("(.str [\"foo\" [\"ba\\nr\" [\"baz\"]]])",
      shouldEvalTo: .string("[\"foo\" [\"ba\\nr\" [\"baz\"]]]"))
  }

  /// .str should properly describe maps.
  // TODO: (az) re-write this test to be less fragile
//  func testMaps() {
//    expectThat("(.str {})", shouldEvalTo: .string("{}"))
//    expectThat("(.str {:foo \"foo\" 'bar \\c})",
//      shouldEvalTo: .string("{bar \\c, :foo \"foo\"}"))
//    expectThat("(.str {152 {\"foo\" \\f} true nil false '(\"bar\" baz)})",
//      shouldEvalTo: .string("{152 {\"foo\" \\f}, false (\"bar\" baz), true nil}"))
//  }

  /// .str should properly concatenate items.
  func testConcatenation() {
    expectThat("(.str \"foo\" \"bar\" \"baz\")", shouldEvalTo: .string("foobarbaz"))
    expectThat("(.str \\a 1523 true nil :meela 'jyaku \\1 2)",
      shouldEvalTo: .string("a1523true:meelajyaku12"))
  }
}
