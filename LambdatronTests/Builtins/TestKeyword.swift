//
//  TestKeyword.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Lambdatron

private extension Value {
  var asKeyword : InternedKeyword? {
    if case let .Keyword(value) = self {
      return value
    }
    return nil
  }
}

class TestKeywordBuiltin : InterpreterTest {

  /// .keyword should properly return a keyword when given a new keyword.
  func testWithNovelKeyword() {
    let value = runCode("(.keyword :foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a novel keyword from a keyword")
    }
  }

  /// .keyword should properly return a keyword when given an existing keyword.
  func testWithExistingKeyword() {
    runCode("(.keyword :foobar)")
    let value = runCode("(.keyword :foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return an existing keyword from a keyword")
    }
  }

  /// .keyword should return nil if given an empty string.
  func testWithEmptyString() {
    expectThat("(.keyword \"\")", shouldEvalTo: .Nil)
  }

  /// .keyword should return a keyword if given the name of a new keyword.
  func testWithNovelString() {
    let value = runCode("(.keyword \"foobar\")")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a novel keyword from a string")
    }
  }

  /// .keyword should return a keyword if given the name of an existing keyword.
  func testWithExistingKeywordString() {
    runCode("(.keyword :foobar)")
    let value = runCode("(.keyword \"foobar\")")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return an existing keyword from a string")
    }
  }

  /// .keyword should work if given a symbol whose name is not an existing keyword.
  func testWithNovelSymbol() {
    let value = runCode("(.keyword 'foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a novel keyword from a symbol")
    }
  }

  /// .keyword should work if given a qualified symbol.
  func testWithQualifiedSymbol() {
    if let value = runCode("(.keyword 'foo/bar)") {
      let expected = keyword("bar", namespace: "foo")
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a qualified keyword")
    }
  }

  /// .keyword should work if given a symbol whose name is an existing keyword.
  func testWithExistingKeywordSymbol() {
    runCode("(.keyword :foobar)")
    let value = runCode("(.keyword 'foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return an existing keyword from a symbol")
    }
  }

  /// .keyword should properly return a qualified symbol when given two string arguments.
  func testWithQualifiedString() {
    if let value = runCode("(.keyword \"foo\" \"bar\")") {
      let expected = keyword("bar", namespace: "foo")
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a qualified keyword")
    }
  }

  /// .keyword should return an error if given two string arguments, but the first is an empty string.
  func testWithEmptyNamespaceString() {
    expectInvalidArgumentErrorFrom("(.keyword \"\" \"bar\")")
    expectInvalidArgumentErrorFrom("(.keyword \"\" \"\")")
  }

  /// .keyword should return nil if given two string arguments, but the second is an empty string.
  func testWithEmptyNameString() {
    expectThat("(.keyword \"foo\" \"\")", shouldEvalTo: .Nil)
  }

  /// .keyword should return nil if called with any non-compliant argument type.
  func testArgumentType() {
    expectThat("(.keyword nil)", shouldEvalTo: .Nil)
    expectThat("(.keyword true)", shouldEvalTo: .Nil)
    expectThat("(.keyword false)", shouldEvalTo: .Nil)
    expectThat("(.keyword 123)", shouldEvalTo: .Nil)
    expectThat("(.keyword 1.23)", shouldEvalTo: .Nil)
    expectThat("(.keyword #\"[0-9]+\")", shouldEvalTo: .Nil)
    expectThat("(.keyword \\a)", shouldEvalTo: .Nil)
    expectThat("(.keyword ())", shouldEvalTo: .Nil)
    expectThat("(.keyword [])", shouldEvalTo: .Nil)
    expectThat("(.keyword {})", shouldEvalTo: .Nil)
    expectInvalidArgumentErrorFrom("(.keyword 'foo 'bar)")
    expectInvalidArgumentErrorFrom("(.keyword \"foo\" :bar)")
  }

  /// .keyword should take exactly one or two arguments.
  func testArity() {
    expectArityErrorFrom("(.keyword)")
    expectArityErrorFrom("(.keyword :a :b :c)")
  }
}
