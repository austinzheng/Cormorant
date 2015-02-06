//
//  TestKeyword.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

class TestKeywordBuiltin : InterpreterTest {

  /// .keyword should properly return a keyword when given a new keyword.
  func testWithNovelKeyword() {
    let value = runCode("(.keyword :foobar)")
    let expected = interpreter.context.keywordForName("foobar")
    if let value = value {
      XCTAssert(value.asKeyword()? == expected, ".keyword should properly return a novel keyword from a keyword")
    }
  }

  /// .keyword should properly return a keyword when given an existing keyword.
  func testWithExistingKeyword() {
    runCode("(.keyword :foobar)")
    let value = runCode("(.keyword :foobar)")
    let expected = interpreter.context.keywordForName("foobar")
    if let value = value {
      XCTAssert(value.asKeyword()? == expected, ".keyword should properly return an existing keyword from a keyword")
    }
  }

  /// .keyword should return nil if given an empty string.
  func testWithEmptyString() {
    expectThat("(.keyword \"\")", shouldEvalTo: .Nil)
  }

  /// .keyword should return a keyword if given the name of a new keyword.
  func testWithNovelString() {
    let value = runCode("(.keyword \"foobar\")")
    let expected = interpreter.context.keywordForName("foobar")
    if let value = value {
      XCTAssert(value.asKeyword()? == expected, ".keyword should properly return a novel keyword from a string")
    }
  }

  /// .keyword should return a keyword if given the name of an existing keyword.
  func testWithExistingKeywordString() {
    runCode("(.keyword :foobar)")
    let value = runCode("(.keyword \"foobar\")")
    let expected = interpreter.context.keywordForName("foobar")
    if let value = value {
      XCTAssert(value.asKeyword()? == expected, ".keyword should properly return an existing keyword from a string")
    }
  }

  /// .keyword should work if given a symbol whose name is not an existing keyword.
  func testWithNovelSymbol() {
    let value = runCode("(.keyword 'foobar)")
    let expected = interpreter.context.keywordForName("foobar")
    if let value = value {
      XCTAssert(value.asKeyword()? == expected, ".keyword should properly return a novel keyword from a symbol")
    }
  }

  /// .keyword should work if given a symbol whose name is an existing keyword.
  func testWithExistingKeywordSymbol() {
    runCode("(.keyword :foobar)")
    let value = runCode("(.keyword 'foobar)")
    let expected = interpreter.context.keywordForName("foobar")
    if let value = value {
      XCTAssert(value.asKeyword()? == expected, ".keyword should properly return an existing keyword from a symbol")
    }
  }

  /// .keyword should return nil if called with any non-compliant argument type.
  func testArgumentType() {
    expectThat("(.keyword nil)", shouldEvalTo: .Nil)
    expectThat("(.keyword true)", shouldEvalTo: .Nil)
    expectThat("(.keyword false)", shouldEvalTo: .Nil)
    expectThat("(.keyword 123)", shouldEvalTo: .Nil)
    expectThat("(.keyword 1.23)", shouldEvalTo: .Nil)
    expectThat("(.keyword \\a)", shouldEvalTo: .Nil)
    expectThat("(.keyword '())", shouldEvalTo: .Nil)
    expectThat("(.keyword [])", shouldEvalTo: .Nil)
    expectThat("(.keyword {})", shouldEvalTo: .Nil)
  }

  /// .keyword should (currently) take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.keyword)")
    expectArityErrorFrom("(.keyword :a :b :c)")
  }
}
