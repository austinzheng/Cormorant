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
    let expected = interpreter.context.symbolForName("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a not-before-defined symbol")
    }
  }

  /// .symbol should properly return an existing interned symbol when given an appropriate symbol argument.
  func testWithExistingSymbol() {
    runCode("(def foobar)")
    let value = runCode("(.symbol 'foobar)")
    let expected = interpreter.context.symbolForName("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a previously defined symbol")
    }
  }

  /// .symbol should return nil if given an empty string.
  func testWithEmptyString() {
    expectThat("(.symbol \"\")", shouldEvalTo: .Nil)
  }

  /// .symbol should properly return a novel symbol when given a string argument.
  func testWithNewSymbolString() {
    let value = runCode("(.symbol \"foobar\")")
    let expected = interpreter.context.symbolForName("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a novel symbol from a string")
    }
  }

  /// .symbol should properly return an existing interned symbol when given an appropriate string argument.
  func testWithExistingSymbolString() {
    runCode("(def foobar)")
    let value = runCode("(.symbol \"foobar\")")
    let expected = interpreter.context.symbolForName("foobar")
    if let value = value {
      XCTAssert(value.asSymbol == expected, ".symbol should properly return a previously defined symbol")
    }
  }

  /// .symbol should throw an error if tested with an improper argument type.
  func testArgumentType() {
    expectThat("(.symbol nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol 123)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol 1.23)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol #\"[0-9]+\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol ())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol {})", shouldFailAs: .InvalidArgumentError)
  }

  /// .symbol should (currently) take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.symbol)")
    expectArityErrorFrom("(.symbol 'a 'b 'c)")
  }
}
