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
    run(input: "(def a)")
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
    run(input: "(def a 1523)")
    expectThat("a", shouldEvalTo: 1523)
  }

  /// def with an initializer should evaluate the initializer form.
  func testDefWithInitializer2() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    run(input: "(def a (.+ 12 2))")
    expectThat("a", shouldEvalTo: 14)
  }

  /// def should allow qualified symbols only if they are in the current namespace.
  func testQualifiedSymbols() {
    run(input: "(.ns-set 'foo)")
    expectThat("(def bar/a 10)", shouldFailAs: .QualifiedSymbolMisuseError)
    run(input: "(def foo/a 10)")
    run(input: "(def foo/b 15)")
    expectThat("(def bar/z)", shouldFailAs: .QualifiedSymbolMisuseError)
    // Move namespaces
    run(input: "(.ns-set 'bar)")
    expectThat("(def foo/a 10)", shouldFailAs: .QualifiedSymbolMisuseError)
    run(input: "(def bar/a 10)")
    run(input: "(def bar/b 15)")
    expectThat("(def foo/z)", shouldFailAs: .QualifiedSymbolMisuseError)
  }

  /// def should overwrite a previous unbound def with a new value.
  func testOverwritingUnboundDef() {
    let a = symbol("a", namespace: "user")
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    run(input: "(def a)")
    expectThat("a", shouldEvalTo: .auxiliary(UnboundVarObject(a, ctx: interpreter.currentNamespace)))
    run(input: "(def a \"foobar\")")
    expectThat("a", shouldEvalTo: .string("foobar"))
  }

  /// def should overwrite a previous bound def with a new value.
  func testOverwritingBoundDef() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    run(input: "(def a \\c)")
    expectThat("a", shouldEvalTo: .char("c"))
    run(input: "(def a true)")
    expectThat("a", shouldEvalTo: true)
  }

  /// def without a value should not overwrite a previous bound def with a value.
  func testOverwritingBoundDefWithUnbound() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    let code = keyword("foobar")
    run(input: "(def a :foobar)")
    expectThat("a", shouldEvalTo: .keyword(code))
    run(input: "(def a)")
    expectThat("a", shouldEvalTo: .keyword(code))
  }

  /// def should not bind by reference, but by value.
  func testDefBindingByValue() {
    expectThat("a", shouldFailAs: .InvalidSymbolError)
    run(input: "(def a 10)")
    expectThat("b", shouldFailAs: .InvalidSymbolError)
    run(input: "(def b a)")
    expectThat("b", shouldEvalTo: 10)
    run(input: "(def a 20)")
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
