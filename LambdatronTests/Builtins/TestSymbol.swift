//
//  TestSymbol.swift
//  Lambdatron
//
//  Created by Austin Zheng on 2/1/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
import XCTest

class TestSymbolBuiltin : InterpreterTest {

  /// .symbol should properly return a novel symbol when given a symbol argument.
  func testWithNewSymbol() {
    let value = runCode("(.symbol 'foobar)")
    let expected = symbol("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a not-before-defined symbol")
    }
  }

  /// .symbol should properly return an existing interned symbol when given an appropriate symbol argument.
  func testWithExistingSymbol() {
    runCode("(def foobar)")
    let value = runCode("(.symbol 'foobar)")
    let expected = symbol("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a previously defined symbol")
    }
  }

  /// .symbol should return a qualified symbol if given one as an argument.
  func testWithQualifiedSymbol() {
    if let value = runCode("(.symbol 'foo/bar)") {
      let expected = symbol("bar", namespace: "foo")
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a qualified symbol")
    }
  }

  /// .symbol should return nil if given an empty string.
  func testWithEmptyString() {
    expectThat("(.symbol \"\")", shouldEvalTo: .Nil)
  }

  /// .symbol should properly return a novel symbol when given a string argument.
  func testWithNewSymbolString() {
    let value = runCode("(.symbol \"foobar\")")
    let expected = symbol("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a novel symbol from a string")
    }
  }

  /// .symbol should properly return an existing interned symbol when given an appropriate string argument.
  func testWithExistingSymbolString() {
    runCode("(def foobar)")
    let value = runCode("(.symbol \"foobar\")")
    let expected = symbol("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a previously defined symbol")
    }
  }

  /// .symbol should properly return a qualified symbol when given two string arguments.
  func testWithQualifiedString() {
    if let value = runCode("(.symbol \"foo\" \"bar\")") {
      let expected = symbol("bar", namespace: "foo")
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a qualified symbol")
    }
  }

  /// .symbol should return an error if given two string arguments, but the first is an empty string.
  func testWithEmptyNamespaceString() {
    expectInvalidArgumentErrorFrom("(.symbol \"\" \"bar\")")
    expectInvalidArgumentErrorFrom("(.symbol \"\" \"\")")
  }

  /// .symbol should return nil if given two string arguments, but the second is an empty string.
  func testWithEmptyNameString() {
    expectThat("(.symbol \"foo\" \"\")", shouldEvalTo: .Nil)
  }

  /// .symbol should throw an error if tested with an improper argument type.
  func testArgumentType() {
    expectInvalidArgumentErrorFrom("(.symbol nil)")
    expectInvalidArgumentErrorFrom("(.symbol true)")
    expectInvalidArgumentErrorFrom("(.symbol false)")
    expectInvalidArgumentErrorFrom("(.symbol 123)")
    expectInvalidArgumentErrorFrom("(.symbol 1.23)")
    expectInvalidArgumentErrorFrom("(.symbol #\"[0-9]+\")")
    expectInvalidArgumentErrorFrom("(.symbol :a)")
    expectInvalidArgumentErrorFrom("(.symbol \\a)")
    expectInvalidArgumentErrorFrom("(.symbol ())")
    expectInvalidArgumentErrorFrom("(.symbol [])")
    expectInvalidArgumentErrorFrom("(.symbol {})")
    expectInvalidArgumentErrorFrom("(.symbol nil \"\")")
    expectInvalidArgumentErrorFrom("(.symbol 'foo 'bar)")
    expectInvalidArgumentErrorFrom("(.symbol \"foo\" :bar)")
  }

  /// .symbol should take exactly one or two arguments.
  func testArity() {
    expectArityErrorFrom("(.symbol)")
    expectArityErrorFrom("(.symbol 'a 'b 'c)")
  }
}
