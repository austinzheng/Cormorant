//
//  TestSbFunctions.swift
//  Lambdatron
//
//  Created by Austin Zheng on 3/17/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

/// Test the '.sb' built-in function.
class TestSbBuiltin : InterpreterTest {

  /// .sb called without any arguments should produce an empty string builder.
  func testEmptyBuilder() {
    let sb = runCode("(.sb)")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == "", "(.sb) should produce an empty string")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb called with a string argument should initialize the string builder with the string.
  func testWithInitialString() {
    let testStr = "the quick brown fox jumps across the lazy dog"
    let sb = runCode("(.sb \"\(testStr)\")")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == testStr, "String builder should have been initialized with the string \"\(testStr)\"")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb called with a non-string argument should initialize the string builder with the stringified argument.
  func testWithInitialArgument() {
    let sb = runCode("(.sb :foobar-baz)")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == ":foobar-baz",
        "String builder should have been initialized with the stringified value \":foobar-baz\"")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb should take zero or one arguments.
  func testArity() {
    expectArityErrorFrom("(.sb \"foo\" \"bar\")")
  }
}

/// Test the '.sb-append' built-in function.
class TestSbAppendBuiltin : InterpreterTest {

  /// .sb-append should do nothing if called with an empty string.
  func testWithEmptyString() {
    let referenceStr = "meela"
    runCode("(def a (.sb \"\(referenceStr)\"))")
    runCode("(.sb-append a \"\")")
    let sb = runCode("a")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == referenceStr, "String builder should have retained the value \"\(referenceStr)\"")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb-append should append strings to a string buffer.
  func testWithStrings() {
    let referenceStr = "meela, yuen, piper, and holland..."
    runCode("(def a (.sb))")
    runCode("(.sb-append a \"meela, \")")
    runCode("(.sb-append a \"yuen, \")")
    runCode("(.sb-append a \"piper, \")")
    runCode("(.sb-append a \"and holland...\")")
    let sb = runCode("a")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == referenceStr, "String builder should have retained the value \"\(referenceStr)\"")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb-append should only take a string builder as its first argument.
  func testInvalidArgument() {
    expectThat("(.sb-append nil \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append true \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append false \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append 1521321 \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append -492.01203 \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append \"foobar\" \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append #\"[0-9]+\" \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append :foobar \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append 'foobar \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append '(1 2 3 4) \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append [1 2 3 4] \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append {:foo :bar} \"foo\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-append .sb-append \"foo\")", shouldFailAs: .InvalidArgumentError)
  }

  /// .sb-append should take exactly two arguments.
  func testArity() {
    expectArityErrorFrom("(.sb-append)")
    expectArityErrorFrom("(.sb-append (.sb))")
    expectArityErrorFrom("(.sb-append (.sb) \"foobar\" \"foobarbaz\")")
  }
}

/// Test the '.sb-reverse' built-in function.
class TestSbReverseBuiltin : InterpreterTest {

  /// .sb-reverse should do nothing to an empty string builder.
  func testWithEmptyBuilder() {
    runCode("(def a (.sb))")
    runCode("(.sb-reverse a)")
    let sb = runCode("a")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == "", "String builder should have been empty")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb-reverse should reverse the buffer of a non-empty string builder.
  func testWithNonemptyBuilder() {
    runCode("(def a (.sb \"foobarbaz\"))")
    runCode("(.sb-reverse a)")
    let sb = runCode("a")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == "zabraboof", "String builder should have reversed the string")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb-reverse should only take a string builder as its argument.
  func testInvalidArgument() {
    expectThat("(.sb-reverse nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse 1521321)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse -492.01203)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse \"foobar\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse #\"[0-9]+\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse :foobar)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse 'foobar)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse '(1 2 3 4))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse [1 2 3 4])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse {:foo :bar})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.sb-reverse .sb-reverse)", shouldFailAs: .InvalidArgumentError)
  }

  /// .sb-reverse should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.sb-reverse)")
    expectArityErrorFrom("(.sb-reverse (.sb) \"foobar\")")
  }
}
