//
//  TestPrimitiveManip.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/22/15.
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
      XCTAssert(value.asSymbol()? == expected, ".symbol should properly return a not-before-defined symbol")
    }
  }

  /// .symbol should properly return an existing interned symbol when given an appropriate symbol argument.
  func testWithExistingSymbol() {
    runCode("(def foobar)")
    let value = runCode("(.symbol 'foobar)")
    let expected = interpreter.context.symbolForName("foobar")
    if let value = value {
      XCTAssert(value.asSymbol()? == expected, ".symbol should properly return a previously defined symbol")
    }
  }

  /// .symbol should return nil if given an empty string.
  func testWithEmptyString() {
    expectThat("(.symbol \"\")", shouldEvalTo: .NilLiteral)
  }

  /// .symbol should properly return a novel symbol when given a string argument.
  func testWithNewSymbolString() {
    let value = runCode("(.symbol \"foobar\")")
    let expected = interpreter.context.symbolForName("foobar")
    if let value = value {
      XCTAssert(value.asSymbol()? == expected, ".symbol should properly return a novel symbol from a string")
    }
  }

  /// .symbol should properly return an existing interned symbol when given an appropriate string argument.
  func testWithExistingSymbolString() {
    runCode("(def foobar)")
    let value = runCode("(.symbol \"foobar\")")
    let expected = interpreter.context.symbolForName("foobar")
    if let value = value {
      XCTAssert(value.asSymbol()? == expected, ".symbol should properly return a previously defined symbol")
    }
  }

  /// .symbol should throw an error if tested with an improper argument type.
  func testArgumentType() {
    expectThat("(.symbol nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol 123)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol 1.23)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.symbol {})", shouldFailAs: .InvalidArgumentError)
  }

  /// .symbol should (currently) take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.symbol)")
    expectArityErrorFrom("(.symbol 'a 'b 'c)")
  }
}

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
    expectThat("(.keyword \"\")", shouldEvalTo: .NilLiteral)
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
    expectThat("(.keyword nil)", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword true)", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword false)", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword 123)", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword 1.23)", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword \\a)", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword '())", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword [])", shouldEvalTo: .NilLiteral)
    expectThat("(.keyword {})", shouldEvalTo: .NilLiteral)
  }

  /// .keyword should (currently) take exactly one argument.
  func testArity() {
    expectArityErrorFrom("(.keyword)")
    expectArityErrorFrom("(.keyword :a :b :c)")
  }
}

class TestIntBuiltin : InterpreterTest {

  /// .int should return integer values unchanged.
  func testWithInt() {
    expectThat("(.int 51222)", shouldEvalTo: .IntegerLiteral(51222))
  }

  /// .int should coerce and truncate floating-point values to integers.
  func testWithDouble() {
    expectThat("(.int 1.99912)", shouldEvalTo: .IntegerLiteral(1))
  }

  /// .int should coerce characters to their raw values.
  func testWithChar() {
    expectThat("(.int \\g)", shouldEvalTo: .IntegerLiteral(103))
  }

  /// .int should fail with any non-numeric argument.
  func testWithInvalidArguments() {
    expectThat("(.int nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.int .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .int should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.int)")
    expectArityErrorFrom("(.int 0 1)")
  }
}

class TestDoubleBuiltin : InterpreterTest {

  /// .double should return floating-point number arguments unchanged.
  func testWithDouble() {
    expectThat("(.double 12.12355)", shouldEvalTo: .FloatLiteral(12.12355))
  }

  /// .double should coerce integer arguments to floating-point values.
  func testWithInt() {
    expectThat("(.double 19012)", shouldEvalTo: .FloatLiteral(19012.0))
  }

  /// .double should fail with any non-numeric argument.
  func testWithInvalidArguments() {
    expectThat("(.double nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double true)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double false)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double \"\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double [])", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double '())", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double {})", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double (fn [] 0))", shouldFailAs: .InvalidArgumentError)
    expectThat("(.double .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// .double should not take more or fewer than one argument.
  func testArity() {
    expectArityErrorFrom("(.double)")
    expectArityErrorFrom("(.double 0 1)")
  }
}
