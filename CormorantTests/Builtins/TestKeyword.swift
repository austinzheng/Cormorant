//
//  TestKeyword.swift
//  Cormorant
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest
@testable import Cormorant

private extension Value {
  var asKeyword : InternedKeyword? {
    if case let .keyword(value) = self {
      return value
    }
    return nil
  }
}

class TestKeywordBuiltin : InterpreterTest {

  /// .keyword should properly return a keyword when given a new keyword.
  func testWithNovelKeyword() {
    let value = run(input: "(.keyword :foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a novel keyword from a keyword")
    }
  }

  /// .keyword should properly return a keyword when given an existing keyword.
  func testWithExistingKeyword() {
    run(input: "(.keyword :foobar)")
    let value = run(input: "(.keyword :foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return an existing keyword from a keyword")
    }
  }

  /// .keyword should return nil if given an empty string.
  func testWithEmptyString() {
    expectThat("(.keyword \"\")", shouldEvalTo: .nilValue)
  }

  /// .keyword should return a keyword if given the name of a new keyword.
  func testWithNovelString() {
    let value = run(input: "(.keyword \"foobar\")")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a novel keyword from a string")
    }
  }

  /// .keyword should return a keyword if given the name of an existing keyword.
  func testWithExistingKeywordString() {
    run(input: "(.keyword :foobar)")
    let value = run(input: "(.keyword \"foobar\")")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return an existing keyword from a string")
    }
  }

  /// .keyword should work if given a symbol whose name is not an existing keyword.
  func testWithNovelSymbol() {
    let value = run(input: "(.keyword 'foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a novel keyword from a symbol")
    }
  }

  /// .keyword should work if given a qualified symbol.
  func testWithQualifiedSymbol() {
    if let value = run(input: "(.keyword 'foo/bar)") {
      let expected = keyword("bar", namespace: "foo")
      XCTAssert(value.asKeyword == expected, ".keyword should properly return a qualified keyword")
    }
  }

  /// .keyword should work if given a symbol whose name is an existing keyword.
  func testWithExistingKeywordSymbol() {
    run(input: "(.keyword :foobar)")
    let value = run(input: "(.keyword 'foobar)")
    let expected = keyword("foobar")
    if let value = value {
      XCTAssert(value.asKeyword == expected, ".keyword should properly return an existing keyword from a symbol")
    }
  }

  /// .keyword should properly return a qualified symbol when given two string arguments.
  func testWithQualifiedString() {
    if let value = run(input: "(.keyword \"foo\" \"bar\")") {
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
    expectThat("(.keyword \"foo\" \"\")", shouldEvalTo: .nilValue)
  }

  /// .keyword should return nil if called with any non-compliant argument type.
  func testArgumentType() {
    expectThat("(.keyword nil)", shouldEvalTo: .nilValue)
    expectThat("(.keyword true)", shouldEvalTo: .nilValue)
    expectThat("(.keyword false)", shouldEvalTo: .nilValue)
    expectThat("(.keyword 123)", shouldEvalTo: .nilValue)
    expectThat("(.keyword 1.23)", shouldEvalTo: .nilValue)
    expectThat("(.keyword #\"[0-9]+\")", shouldEvalTo: .nilValue)
    expectThat("(.keyword \\a)", shouldEvalTo: .nilValue)
    expectThat("(.keyword ())", shouldEvalTo: .nilValue)
    expectThat("(.keyword [])", shouldEvalTo: .nilValue)
    expectThat("(.keyword {})", shouldEvalTo: .nilValue)
    expectInvalidArgumentErrorFrom("(.keyword 'foo 'bar)")
    expectInvalidArgumentErrorFrom("(.keyword \"foo\" :bar)")
  }

  /// .keyword should take exactly one or two arguments.
  func testArity() {
    expectArityErrorFrom("(.keyword)")
    expectArityErrorFrom("(.keyword :a :b :c)")
  }
}
