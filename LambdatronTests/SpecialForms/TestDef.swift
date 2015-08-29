//
//  TestDef.swift
//  Lambdatron
//
//  Created by Austin Zheng on 1/20/15.
//  Copyright (c) 2015 Austin Zheng. All rights reserved.
//

import Foundation
@testable import Lambdatron

/// Test the 'def' special form.
class TestDef : InterpreterTest {

  /// def should properly take a symbol as its first argument.
  func testDefWithSymbolFirstArg() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a)")
  }

  /// def should only take a symbol as its first argument.
  func testDefWithInvalidFirstArgs() {
    expectInvalidArgumentErrorFrom("(def nil)")
    expectInvalidArgumentErrorFrom("(def 1)")
    expectInvalidArgumentErrorFrom("(def 1.01)")
    expectInvalidArgumentErrorFrom("(def \\a)")
    expectInvalidArgumentErrorFrom("(def :a)")
    expectInvalidArgumentErrorFrom("(def 'a)")
    expectInvalidArgumentErrorFrom("(def \"qwerty\")")
    expectInvalidArgumentErrorFrom("(def ['a])")
    expectInvalidArgumentErrorFrom("(def {\"a\" 1234})")
    expectInvalidArgumentErrorFrom("(def (fn [] 'a))")
    expectInvalidArgumentErrorFrom("(def (do 1 2 'a))")
    expectInvalidArgumentErrorFrom("(def .+)")
  }

  /// def with an initializer should work properly.
  func testDefWithInitializer() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a 1523)")
    expectThat("a", shouldEvalTo: 1523)
  }

  /// def with an initializer should evaluate the initializer form.
  func testDefWithInitializer2() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a (.+ 12 2))")
    expectThat("a", shouldEvalTo: 14)
  }

  /// def should allow qualified symbols only if they are in the current namespace.
  func testQualifiedSymbols() {
    runCode("(.ns-set 'foo)")
    expectThat("(def bar/a 10)", shouldFailAs: .QualifiedSymbolMisuseError)
    runCode("(def foo/a 10)")
    runCode("(def foo/b 15)")
    expectThat("(def bar/z)", shouldFailAs: .QualifiedSymbolMisuseError)
    // Move namespaces
    runCode("(.ns-set 'bar)")
    expectThat("(def foo/a 10)", shouldFailAs: .QualifiedSymbolMisuseError)
    runCode("(def bar/a 10)")
    runCode("(def bar/b 15)")
    expectThat("(def foo/z)", shouldFailAs: .QualifiedSymbolMisuseError)
  }

  /// def should overwrite a previous unbound def with a new value.
  func testOverwritingUnboundDef() {
    let a = symbol("a", namespace: "user")
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a)")
    expectThat("a", shouldEvalTo: .Auxiliary(UnboundVarObject(a, ctx: interpreter.currentNamespace)))
    runCode("(def a \"foobar\")")
    expectThat("a", shouldEvalTo: .StringAtom("foobar"))
  }

  /// def should overwrite a previous bound def with a new value.
  func testOverwritingBoundDef() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    runCode("(def a \\c)")
    expectThat("a", shouldEvalTo: .CharAtom("c"))
    runCode("(def a true)")
    expectThat("a", shouldEvalTo: true)
  }

  /// def without a value should not overwrite a previous bound def with a value.
  func testOverwritingBoundDefWithUnbound() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    let code = keyword("foobar")
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
    expectThat("b", shouldEvalTo: 10)
    runCode("(def a 20)")
    // The value of 'b' should not change because 'a' changed.
    expectThat("b", shouldEvalTo: 10)
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