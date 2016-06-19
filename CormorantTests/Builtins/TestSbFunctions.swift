//
//  TestSbFunctions.swift
//  Cormorant
//
//  Created by Austin Zheng on 3/17/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Cormorant

private extension Value {
  var asStringBuilder : StringBuilderType? {
    if case let .auxiliary(value as StringBuilderType) = self {
      return value
    }
    return nil
  }
}

/// Test the '.sb' built-in function.
class TestSbBuiltin : InterpreterTest {

  /// .sb called without any arguments should produce an empty string builder.
  func testEmptyBuilder() {
    let sb = run(input: "(.sb)")
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
    let sb = run(input: "(.sb \"\(testStr)\")")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == testStr, "String builder should have been initialized with the string \"\(testStr)\"")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb called with a non-string argument should initialize the string builder with the stringified argument.
  func testWithInitialArgument() {
    let sb = run(input: "(.sb :foobar-baz)")
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
    run(input: "(def a (.sb \"\(referenceStr)\"))")
    run(input: "(.sb-append a \"\")")
    let sb = run(input: "a")
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
    run(input: "(def a (.sb))")
    run(input: "(.sb-append a \"meela, \")")
    run(input: "(.sb-append a \"yuen, \")")
    run(input: "(.sb-append a \"piper, \")")
    run(input: "(.sb-append a \"and holland...\")")
    let sb = run(input: "a")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == referenceStr, "String builder should have retained the value \"\(referenceStr)\"")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb-append should only take a string builder as its first argument.
  func testInvalidArgument() {
    expectInvalidArgumentErrorFrom("(.sb-append nil \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append true \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append false \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append 1521321 \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append -492.01203 \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append \"foobar\" \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append #\"[0-9]+\" \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append :foobar \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append 'foobar \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append '(1 2 3 4) \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append [1 2 3 4] \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append {:foo :bar} \"foo\")")
    expectInvalidArgumentErrorFrom("(.sb-append .sb-append \"foo\")")
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
    run(input: "(def a (.sb))")
    run(input: "(.sb-reverse a)")
    let sb = run(input: "a")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == "", "String builder should have been empty")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb-reverse should reverse the buffer of a non-empty string builder.
  func testWithNonemptyBuilder() {
    run(input: "(def a (.sb \"foobarbaz\"))")
    run(input: "(.sb-reverse a)")
    let sb = run(input: "a")
    if let sb = sb?.asStringBuilder {
      XCTAssert(sb.string() == "zabraboof", "String builder should have reversed the string")
    }
    else {
      XCTAssert(false, "Trying to retrieve the builder produced an error or returned the wrong type of object")
    }
  }

  /// .sb-reverse should only take a string builder as its argument.
  func testInvalidArgument() {
    expectInvalidArgumentErrorFrom("(.sb-reverse nil)")
    expectInvalidArgumentErrorFrom("(.sb-reverse true)")
    expectInvalidArgumentErrorFrom("(.sb-reverse false)")
    expectInvalidArgumentErrorFrom("(.sb-reverse 1521321)")
    expectInvalidArgumentErrorFrom("(.sb-reverse -492.01203)")
    expectInvalidArgumentErrorFrom("(.sb-reverse \"foobar\")")
    expectInvalidArgumentErrorFrom("(.sb-reverse #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.sb-reverse :foobar)")
    expectInvalidArgumentErrorFrom("(.sb-reverse 'foobar)")
    expectInvalidArgumentErrorFrom("(.sb-reverse '(1 2 3 4))")
    expectInvalidArgumentErrorFrom("(.sb-reverse [1 2 3 4])")
    expectInvalidArgumentErrorFrom("(.sb-reverse {:foo :bar})")
    expectInvalidArgumentErrorFrom("(.sb-reverse .sb-reverse)")
  }

  /// .sb-reverse should take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.sb-reverse)")
    expectArityErrorFrom("(.sb-reverse (.sb) \"foobar\")")
  }
}
