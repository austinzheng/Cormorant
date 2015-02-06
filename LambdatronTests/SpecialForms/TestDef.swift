//
//  TestDef.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/20/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation

/// Test the 'def' special form.
class TestDef : InterpreterTest {

  override func setUp() {
    super.setUp()
    clearOutputBuffer()
    interpreter.writeOutput = writeToBuffer
  }

  override func tearDown() {
    // Reset the interpreter
    clearOutputBuffer()
    interpreter.writeOutput = print
  }

  /// def should properly take a symbol as its first argument.
  func testDefWithSymbolFirstArg() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a)")
  }

  /// def should only take a symbol as its first argument.
  func testDefWithInvalidFirstArgs() {
    expectThat("(def nil)", shouldFailAs: .InvalidArgumentError)
    expectThat("(def 1)", shouldFailAs: .InvalidArgumentError)
    expectThat("(def 1.01)", shouldFailAs: .InvalidArgumentError)
    expectThat("(def \\a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(def :a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(def 'a)", shouldFailAs: .InvalidArgumentError)
    expectThat("(def \"qwerty\")", shouldFailAs: .InvalidArgumentError)
    expectThat("(def ['a])", shouldFailAs: .InvalidArgumentError)
    expectThat("(def {\"a\" 1234})", shouldFailAs: .InvalidArgumentError)
    expectThat("(def (fn [] 'a))", shouldFailAs: .InvalidArgumentError)
    expectThat("(def (do 1 2 'a))", shouldFailAs: .InvalidArgumentError)
    expectThat("(def .+)", shouldFailAs: .InvalidArgumentError)
  }

  /// def with an initializer should work properly.
  func testDefWithInitializer() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a 1523)")
    expectThat("a", shouldEvalTo: .IntAtom(1523))
  }

  /// def with an initializer should evaluate the initializer form.
  func testDefWithInitializer2() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a (.+ 12 2))")
    expectThat("a", shouldEvalTo: .IntAtom(14))
  }

  /// def should overwrite a previous unbound def with a new value.
  func testOverwritingUnboundDef() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a)")
    expectThat("a", shouldFailAs: .UnboundSymbolError)
    runCode("(def a \"foobar\")")
    expectThat("a", shouldEvalTo: .StringAtom("foobar"))
  }

  /// def should overwrite a previous bound def with a new value.
  func testOverwritingBoundDef() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a \\c)")
    expectThat("a", shouldEvalTo: .CharAtom("c"))
    runCode("(def a true)")
    expectThat("a", shouldEvalTo: .BoolAtom(true))
  }

  /// def without a value should not overwrite a previous bound def with a value.
  func testOverwritingBoundDefWithUnbound() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    let code = interpreter.context.keywordForName("foobar")
    runCode("(def a :foobar)")
    expectThat("a", shouldEvalTo: .Keyword(code))
    runCode("(def a)")
    expectThat("a", shouldEvalTo: .Keyword(code))
  }

  /// def should not bind by reference, but by value.
  func testDefBindingByValue() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a 10)")
    expectThat("b", shouldFailAs: .InvalidSymbolError)
    runCode("(def b a)")
    expectThat("b", shouldEvalTo: .IntAtom(10))
    runCode("(def a 20)")
    // The value of 'b' should not change because 'a' changed.
    expectThat("b", shouldEvalTo: .IntAtom(10))
  }

  /// def should not take fewer than one form.
  func testDefWithZeroForms() {
    expectArityErrorFrom("(def)")
  }

  /// def should not take more than two forms.
  func testDefWithThreeForms() {
    expectArityErrorFrom("(def a 5123 nil)")
  }
}